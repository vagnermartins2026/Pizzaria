#!/usr/bin/env bash
# Prova do carregador da pizzaria demo num banco DESCARTÁVEL: carrega tudo, confere contagens e totais com os CSVs,
# roda o carregador DUAS vezes (idempotente) e roda o motor do CRM sobre os pedidos carregados — o resultado precisa
# ser idêntico aos gabaritos (oportunidades e mensagens). Também confere a gestão contra o seu gabarito.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"; DB=pizzalia_teste_seed; HOJE=2026-11-08; SAIDA="$RAIZ/demo/saida"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB"); QUIETO=(env PGOPTIONS="-c client_min_messages=warning")
python3 "$RAIZ/demo/gerar_dados_demo.py" --hoje "$HOJE" --verificar >/dev/null
python3 "$RAIZ/demo/gerar_gestao_demo.py" --hoje "$HOJE" --verificar
dropdb --if-exists --force "$DB"; createdb "$DB"
for f in db/pedidos/01_cardapio_pedido.sql db/pedidos/02_entrega_horario.sql db/pedidos/05_link_publico.sql \
         db/crm/01_motor_crm.sql db/crm/04_campanhas.sql db/crm/05_resumo.sql; do "${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/$f" >/dev/null; done
for csvf in "$SAIDA"/*.csv; do                       # tabelas de apoio só com texto, no formato de cada CSV
  t=$(basename "$csvf" .csv); case "$t" in oportunidades_*|mensagens_*) continue;; esac
  cols=$(head -1 "$csvf" | sed 's/,/ text, /g; s/$/ text/')
  "${PSQL[@]}" -c "CREATE TABLE public.demo_$t ($cols);" -c "\\copy public.demo_$t FROM '$csvf' CSV HEADER"
done
"${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/db/seed/01_carregar_pizzalia_demo.sql" >/dev/null
"${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/db/seed/01_carregar_pizzalia_demo.sql" >/dev/null     # 2ª vez: nada duplica
"${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/db/seed/02_adaptador_seed.sql" >/dev/null
falhou=0
conferir() { if [[ "$2" == "$3" ]]; then echo "  $1: OK ($2)"; else echo "  $1: FALHOU (banco $2, CSV $3)"; falhou=1; fi; }
conferir "pedidos"           "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedidos")"            "$("${PSQL[@]}" -tAc "SELECT count(*) FROM demo_orders")"
conferir "soma dos totais"   "$("${PSQL[@]}" -tAc "SELECT sum(total_cents) FROM pedidos")"     "$("${PSQL[@]}" -tAc "SELECT sum(total_cents::bigint) FROM demo_orders")"
conferir "itens"             "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedido_itens")"       "$("${PSQL[@]}" -tAc "SELECT count(*) FROM demo_order_items")"
conferir "sabores"           "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedido_item_sabores")" "$("${PSQL[@]}" -tAc "SELECT count(*) FROM demo_order_item_flavors")"
conferir "itens sem ligação" "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedido_itens WHERE tamanho_id IS NULL AND item_id IS NULL")" "0"
conferir "entregas sem bairro" "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedidos WHERE tipo = 'entrega' AND bairro_id IS NULL")" "0"
conferir "histórico"         "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pedido_status_historico")" \
                             "$("${PSQL[@]}" -tAc "SELECT 5 * count(*) FILTER (WHERE status = 'concluded') + 2 * count(*) FILTER (WHERE status <> 'concluded') FROM demo_orders")"
conferir "contador = último número" "$("${PSQL[@]}" -tAc "SELECT ultimo_pedido FROM loja_contadores")" "$("${PSQL[@]}" -tAc "SELECT max(numero) FROM pedidos")"
LOJA=$(sed -n 2p "$SAIDA/tenants.csv" | cut -d, -f1)
"${PSQL[@]}" -tAc "SELECT public.crm_calcular('$LOJA', '$HOJE')" >/dev/null
conferir "oportunidades x gabarito" "$("${PSQL[@]}" -tA -F, -c "SELECT customer_id, gatilho, CASE WHEN elegivel THEN 'sim' ELSE 'nao' END FROM crm_oportunidades ORDER BY 1,2,3" | md5sum | cut -c1-12)" \
                                    "$(tail -n +2 "$RAIZ/demo/gabarito_oportunidades_$HOJE.csv" | sort | md5sum | cut -c1-12)"
"${PSQL[@]}" -c "\\copy (SELECT o.customer_id, m->>'modelo', m->>'texto', m->>'whatsapp_url' FROM crm_oportunidades o, LATERAL crm_mensagem(o.id) m WHERE o.elegivel) TO '$SAIDA/.seed_msgs.csv' CSV"
conferir "mensagens x gabarito" "$(python3 -I -c "import csv,sys;print(sorted(map(tuple,csv.reader(open(sys.argv[1],encoding='utf-8')))) == sorted(tuple(r) for r in list(csv.reader(open(sys.argv[2],encoding='utf-8')))[1:]))" "$SAIDA/.seed_msgs.csv" "$RAIZ/demo/gabarito_mensagens_$HOJE.csv")" "True"
conferir "resumo de 07/11" "$("${PSQL[@]}" -tAc "SELECT resumo_hoje('$LOJA', '2026-11-07') #>> '{pedidos,frase}'" | cut -c1-6)" "Hoje: "
conferir "tabelas de gestão em espera" "$("${PSQL[@]}" -tAc "SELECT count(*) FROM pg_tables WHERE tablename LIKE 'demo_gestao_%'")" "18"
dropdb --if-exists --force "$DB"
[[ $falhou -eq 0 ]] && echo "PROVA OK" || { echo "PROVA FALHOU"; exit 1; }
