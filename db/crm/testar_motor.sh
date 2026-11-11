#!/usr/bin/env bash
# Prova do motor do CRM em SQL contra o gabarito da pizzaria demo.
# Uso: PGHOST=... PGPORT=... PGUSER=... db/crm/testar_motor.sh [--sabotar]
#   Cria um banco DESCARTÁVEL (pizzalia_teste_crm), carrega a demo, roda os testes de fronteira/cenários e compara,
#   cliente a cliente, as oportunidades do motor com demo/gabarito_oportunidades_2026-11-08.csv.
#   --sabotar: volta a regra antiga do G1 (25 a 30 dias) e EXIGE que a prova falhe (prova de que o teste acusa).
# Nunca aponte para um banco de verdade: o script apaga e recria o banco de teste.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
DB=pizzalia_teste_crm
HOJE=2026-11-08
SAIDA="$RAIZ/demo/saida"
GAB="$RAIZ/demo/gabarito_oportunidades_$HOJE.csv"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB")

python3 "$RAIZ/demo/gerar_dados_demo.py" --hoje "$HOJE" --verificar >/dev/null
dropdb --if-exists "$DB" && createdb "$DB"

for t in tenants orders order_items order_item_flavors customers marketing_consents; do   # tabelas de apoio só com texto, no formato do CSV
  cols=$(head -1 "$SAIDA/$t.csv" | sed 's/,/ text, /g; s/$/ text/')
  "${PSQL[@]}" -c "CREATE TABLE public.demo_$t ($cols);"
  "${PSQL[@]}" -c "\\copy public.demo_$t FROM '$SAIDA/$t.csv' CSV HEADER"
done

"${PSQL[@]}" -f "$RAIZ/db/pedidos/01_cardapio_pedido.sql" -f "$RAIZ/db/pedidos/02_entrega_horario.sql" >/dev/null
"${PSQL[@]}" -f "$RAIZ/db/crm/01_motor_crm.sql" -f "$RAIZ/db/crm/04_campanhas.sql" -f "$RAIZ/db/crm/05_resumo.sql"
if [[ "${1:-}" == "--sabotar" ]]; then
  "${PSQL[@]}" -c "CREATE OR REPLACE FUNCTION public.crm_param(p jsonb, chave text) RETURNS numeric LANGUAGE sql IMMUTABLE AS \$\$
    SELECT CASE WHEN chave = 'g1_max' THEN 30 ELSE COALESCE((p->>chave)::numeric, (jsonb_build_object(
      'g1_min',25,'g2_intervalo_max',21,'g3_min',10,'g3_max',59,'g4_min',60,'g4_max',180,'g5_janela',3,
      'cooldown_dias',7,'max_contatos_30d',4,'descarte_dias',14,'vip_fracao',0.10,'vip_min_pedidos_180d',5,
      'expira_dias',3,'atribuicao_dias',7)->>chave)::numeric) END \$\$;"
fi
"${PSQL[@]}" -f "$RAIZ/db/crm/02_adaptador_demo.sql"

set +e
"${PSQL[@]}" -f "$RAIZ/db/crm/03_testes_fronteira.sql" -f "$RAIZ/db/crm/06_testes_campanhas.sql" 2>&1 | sed 's/^/  /'
testes=${PIPESTATUS[0]}
set -e

LOJA=$(sed -n 2p "$SAIDA/tenants.csv" | cut -d, -f1)
"${PSQL[@]}" -tAc "SELECT public.crm_calcular('$LOJA', '$HOJE');"
OBTIDO="$SAIDA/oportunidades_sql.csv"
{ echo "customer_id,gatilho,elegivel"
  "${PSQL[@]}" -tA -F, -c "SELECT customer_id, gatilho, CASE WHEN elegivel THEN 'sim' ELSE 'nao' END
                           FROM public.crm_oportunidades WHERE store_id = '$LOJA' AND criada_para = '$HOJE'
                           ORDER BY 1, 2, 3"; } > "$OBTIDO"

MSG="$SAIDA/mensagens_sql.csv"
"${PSQL[@]}" -c "\\copy (SELECT o.customer_id, m->>'modelo' AS modelo, m->>'texto' AS texto, m->>'whatsapp_url' AS whatsapp_url
   FROM public.crm_oportunidades o, LATERAL public.crm_mensagem(o.id) m
   WHERE o.store_id = '$LOJA' AND o.criada_para = '$HOJE' AND o.elegivel) TO '$MSG' CSV HEADER"
mensagens_ok=$(python3 -I -c "
import csv,sys
a={tuple(r.values()) for r in csv.DictReader(open(sys.argv[1],encoding='utf-8'))}
b={tuple(r.values()) for r in csv.DictReader(open(sys.argv[2],encoding='utf-8'))}
print('sim' if a==b and len(a)>0 else 'nao:%d gabarito, %d sql, %d diferentes' % (len(a),len(b),len(a^b)))" "$RAIZ/demo/gabarito_mensagens_$HOJE.csv" "$MSG")
echo "  mensagens: $mensagens_ok"
if [[ $testes -eq 0 && "$mensagens_ok" == "sim" ]] && diff -q <(sort "$GAB") <(sort "$OBTIDO") >/dev/null; then
  resultado=0; echo "PROVA OK: $(($(wc -l < "$OBTIDO") - 1)) oportunidades e $(($(python3 -I -c "import csv,sys;print(sum(1 for _ in csv.reader(open(sys.argv[1],encoding='utf-8'))))" "$MSG") - 1)) mensagens idênticas ao gabarito, cliente a cliente."
else
  resultado=1; echo "PROVA FALHOU (testes=$testes). Diferenças (< gabarito | > SQL):"
  diff <(sort "$GAB") <(sort "$OBTIDO") | head -10 || true
fi
dropdb --if-exists "$DB"

if [[ "${1:-}" == "--sabotar" ]]; then
  [[ $resultado -ne 0 ]] && { echo "SABOTAGEM ACUSADA: com a regra antiga a prova falha, como deveria."; exit 0; }
  echo "ERRO: a sabotagem passou despercebida — o teste não protege a regra."; exit 1
fi
exit $resultado
