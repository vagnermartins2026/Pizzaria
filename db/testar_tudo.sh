#!/usr/bin/env bash
# Roda todas as provas de banco da Pizzalia (cada uma num banco descartável). Sai com erro se qualquer uma falhar.
# Uso: PGHOST=... PGPORT=... PGUSER=... db/testar_tudo.sh
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"; falhas=0
for prova in crm/testar_motor.sh pedidos/testar_pedidos.sh seguranca/testar_seguranca.sh; do
  echo "== $prova"
  "$RAIZ/db/$prova" 2>&1 | grep -E "PROVA|gabarito|mensagens:|concorrência|OK \(|: OK|ERROR|FALHOU" | grep -v "^NOTICE:  table" | cut -c1-200
  [[ ${PIPESTATUS[0]} -eq 0 ]] || falhas=$((falhas + 1))
done
# função do link: testes de unidade + ponta a ponta contra o SQL real (precisa do Deno: DENO=/caminho/deno ou no PATH)
DENO_BIN="${DENO:-$(command -v deno || true)}"
if [[ -n "$DENO_BIN" ]]; then
  echo "== supabase/functions/link-pedido"
  DB=pizzalia_teste_link; dropdb --if-exists --force "$DB" 2>/dev/null; createdb "$DB"
  for f in db/pedidos/01_cardapio_pedido.sql db/pedidos/02_entrega_horario.sql db/pedidos/05_link_publico.sql; do
    PGOPTIONS="-c client_min_messages=warning" psql -X -q -v ON_ERROR_STOP=1 -d "$DB" -f "$RAIZ/$f" >/dev/null || falhas=$((falhas + 1))
  done
  SOCK="${PGHOST:-/var/run/postgresql}"
  PIZZALIA_PG_DB="$DB" PIZZALIA_PG_SOCKET="$SOCK" PIZZALIA_PG_PORT="${PGPORT:-5432}" PIZZALIA_PG_USER="${PGUSER:-postgres}" \
    "$DENO_BIN" test --allow-env --allow-net --allow-read --allow-write "$RAIZ/supabase/functions/link-pedido/" 2>&1 \
    | grep -E "\.\.\. (ok|FAILED|ignored)|passed|failed|error" | sed 's/\x1b\[[0-9;]*m//g; s/^/  /'
  [[ ${PIPESTATUS[0]} -eq 0 ]] || falhas=$((falhas + 1))
  dropdb --if-exists --force "$DB"
else
  echo "== supabase/functions/link-pedido: PULADO (Deno não encontrado)"; falhas=$((falhas + 1))
fi
[[ $falhas -eq 0 ]] && echo "TUDO OK" || { echo "$falhas prova(s) falharam"; exit 1; }
