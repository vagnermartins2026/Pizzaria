#!/usr/bin/env bash
# Roda todas as provas de banco da Fornalia (cada uma num banco descartável). Sai com erro se qualquer uma falhar.
# Uso: PGHOST=... PGPORT=... PGUSER=... db/testar_tudo.sh
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"; falhas=0
for prova in crm/testar_motor.sh pedidos/testar_pedidos.sh seguranca/testar_seguranca.sh; do
  echo "== $prova"
  "$RAIZ/db/$prova" 2>&1 | grep -E "PROVA|gabarito|mensagens:|concorrência|OK \(|: OK|ERROR|FALHOU" | grep -v "^NOTICE:  table" | cut -c1-200
  [[ ${PIPESTATUS[0]} -eq 0 ]] || falhas=$((falhas + 1))
done
[[ $falhas -eq 0 ]] && echo "TUDO OK" || { echo "$falhas prova(s) falharam"; exit 1; }
