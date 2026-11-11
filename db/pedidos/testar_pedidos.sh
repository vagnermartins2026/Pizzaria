#!/usr/bin/env bash
# Prova do cardápio e do pedido (e, se existir, de entrega/horário) num banco DESCARTÁVEL.
# Uso: PGHOST=... PGPORT=... PGUSER=... db/pedidos/testar_pedidos.sh [--sabotar]
#   --sabotar: troca "sabor mais caro" por "mais barato" e EXIGE que a prova falhe.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"; DB=fornalia_teste_pedidos; HOJE=2026-11-08; SAIDA="$RAIZ/demo/saida"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB")
python3 "$RAIZ/demo/gerar_dados_demo.py" --hoje "$HOJE" --verificar >/dev/null
dropdb --if-exists --force "$DB"; createdb "$DB"
for t in tenants categories pizza_sizes flavors flavor_prices addon_groups addons products delivery_zones \
         customers customer_addresses orders order_items order_item_flavors order_item_addons; do
  cols=$(head -1 "$SAIDA/$t.csv" | sed 's/,/ text, /g; s/$/ text/')
  "${PSQL[@]}" -c "CREATE TABLE public.demo_$t ($cols);" -c "\\copy public.demo_$t FROM '$SAIDA/$t.csv' CSV HEADER"
done
SQL1="$RAIZ/db/pedidos/01_cardapio_pedido.sql"
if [[ "${1:-}" == "--sabotar" ]]; then SQL1=$(mktemp); sed 's/ELSE (SELECT max(x) FROM unnest(v_precos) x)/ELSE (SELECT min(x) FROM unnest(v_precos) x)/' \
  "$RAIZ/db/pedidos/01_cardapio_pedido.sql" > "$SQL1"; fi
falhou=0
passo() {  # roda um arquivo SQL; qualquer erro marca a prova como falha (sem esconder o código de saída)
  local f="$1"; [[ -f "$f" ]] || return 0
  if ! "${PSQL[@]}" -f "$f" > "$SAIDA/.passo.log" 2>&1; then falhou=1; echo "  FALHOU: $(basename "$f")"; fi
  grep -E "ERROR|NOTICE: +(cardápio|entrega)|gabarito" "$SAIDA/.passo.log" | sed 's/^psql:[^ ]* //; s/^/  /' || true
}
passo "$SQL1"
passo "$RAIZ/db/pedidos/02_entrega_horario.sql"
passo "$RAIZ/db/pedidos/carregar_demo.sql"
passo "$RAIZ/db/pedidos/03_testes_cardapio.sql"
passo "$RAIZ/db/pedidos/04_testes_entrega.sql"

# concorrência: 40 chamadas ao mesmo tempo (30 chaves novas + 10 repetidas) → 30 pedidos, números 1..30 sem buraco
LOJA=$(sed -n 2p "$SAIDA/tenants.csv" | cut -d, -f1)
REFRI=$("${PSQL[@]}" -tAc "SELECT id FROM public.cardapio_itens WHERE store_id = '$LOJA' AND nome = 'Refrigerante 2L'")
for i in $(seq 1 30) $(seq 1 10); do
  "${PSQL[@]}" -tAc "SELECT public.pedido_criar('$LOJA', '{\"canal\":\"balcao\",\"tipo\":\"retirada\",\"forma_pagamento\":\"pix\",\"itens\":[{\"tipo\":\"produto\",\"item_id\":\"$REFRI\"}]}', 'concorrencia-$(printf %03d $i)')" >/dev/null &
done; wait
read -r n maxn distintos <<<"$("${PSQL[@]}" -tA -F' ' -c "SELECT count(*), max(numero), count(DISTINCT numero) FROM public.pedidos WHERE store_id = '$LOJA'")"
if [[ "$n $maxn $distintos" == "30 30 30" ]]; then echo "  concorrência: OK (40 chamadas simultâneas → 30 pedidos, números 1 a 30 sem buraco nem repetição)"
else echo "  concorrência: FALHOU ($n pedidos, maior número $maxn, $distintos distintos)"; falhou=1; fi
dropdb --if-exists "$DB"
if [[ "${1:-}" == "--sabotar" ]]; then
  [[ $falhou -ne 0 ]] && { echo "SABOTAGEM ACUSADA: com 'sabor mais barato' a prova falha, como deveria."; exit 0; }
  echo "ERRO: a sabotagem passou despercebida."; exit 1
fi
[[ $falhou -eq 0 ]] && echo "PROVA OK" || { echo "PROVA FALHOU"; exit 1; }
