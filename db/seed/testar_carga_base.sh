#!/usr/bin/env bash
# Pizzalia · prova da carga DEMO na base, num Postgres LOCAL e descartável montado como um remix novo (o esboço do Supabase e o
# prelúdio dos testes da própria base + TODAS as migrations da pasta do remix). Nada fala com a produção.
# Uso: bash db/seed/testar_carga_base.sh <pasta do repositório pizzalia> [--hoje AAAA-MM-DD]
# Confere: a carga entra sem erro; a 2ª carga não duplica nada; as contagens batem com o resumo do montador; a dona vê tudo pela
# trava de cada loja (RLS) e outra pessoa logada não vê nada; nenhum registro no futuro; totais das vendas = soma dos itens e dos
# pagamentos; o caixa fecha (esperado − contado = diferença).
set -euo pipefail
REPO="${1:?informe a pasta do repositório pizzalia}"; shift
HOJE="$(TZ=America/Sao_Paulo date +%F)"; [ "${1:-}" = "--hoje" ] && HOJE="$2"
AQUI="$(cd "$(dirname "$0")" && pwd)"; RAIZ="$(cd "$AQUI/../.." && pwd)"
LOJA=1e45234c-bd80-52ab-b4e0-983c9d2eee6b; OUTRA=2e45234c-bd80-52ab-b4e0-983c9d2eee6c
DB="mf_test_pizzalia_carga_$$"; TMP="$(mktemp -d)"
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -h "${PGHOST:-localhost}" -U "${PGUSER:-postgres}")
trap '"${PSQL[@]}" -d postgres -c "DROP DATABASE IF EXISTS $DB" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT
falha() { echo "FALHOU: $*"; exit 1; }

echo "1) dados fictícios e carga (hoje = $HOJE)"
python3 "$RAIZ/demo/gerar_dados_demo.py" --hoje "$HOJE" --semente 42 > /dev/null
python3 "$RAIZ/demo/gerar_gestao_demo.py" --hoje "$HOJE" --semente 42 > /dev/null
python3 "$AQUI/montar_carga_base.py" --loja "$LOJA" --hoje "$HOJE" --saida "$TMP/carga" > "$TMP/resumo.txt"

echo "2) banco local como um remix novo"
for papel in anon authenticated "service_role BYPASSRLS" sandbox_exec supabase_admin; do
  n="${papel%% *}"; [ "$("${PSQL[@]}" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$n'")" = 1 ] || "${PSQL[@]}" -d postgres -c "CREATE ROLE $papel NOLOGIN"
done
"${PSQL[@]}" -d postgres -c "CREATE DATABASE $DB" > /dev/null
"${PSQL[@]}" -d "$DB" -f "$REPO/src/__tests__/sql/supabase-stub.sql" > /dev/null
# o mesmo prelúdio de src/__tests__/sql/harness.ts (PRELUDIO_SUPABASE_NOVO)
"${PSQL[@]}" -d "$DB" > /dev/null <<'SQL'
DO $$ DECLARE papel text; tipo text; BEGIN
  IF current_database() !~ '^mf_test_' THEN RAISE EXCEPTION 'só em banco mf_test_*'; END IF;
  EXECUTE format('ALTER DATABASE %I SET search_path TO "$user", public, extensions', current_database());
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN CREATE PUBLICATION supabase_realtime; END IF;
  FOREACH papel IN ARRAY ARRAY['postgres', 'supabase_admin'] LOOP
    FOREACH tipo IN ARRAY ARRAY['TABLES', 'SEQUENCES', 'FUNCTIONS'] LOOP
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public GRANT ALL ON %s TO postgres, anon, authenticated, service_role', papel, tipo);
    END LOOP;
  END LOOP;
END $$;
SQL
for f in "$REPO"/supabase/migrations/*.sql; do
  sed -E 's/^(CREATE EXTENSION IF NOT EXISTS (pg_cron|pg_net)\b.*;)$/-- (ensaio) \1/I' "$f" | "${PSQL[@]}" -1 -d "$DB" > /dev/null 2> "$TMP/erro.txt" \
    || { cat "$TMP/erro.txt"; falha "migration $(basename "$f")"; }
done
"${PSQL[@]}" -d "$DB" -c "INSERT INTO auth.users (id, email, email_confirmed_at) VALUES ('$LOJA', 'dono.demo@pizzalia.invalid', now()), ('$OUTRA', 'outra@teste.invalid', now())" > /dev/null

echo "3) carga (duas vezes: a 2ª não pode duplicar)"
contar() { "${PSQL[@]}" -d "$DB" -tAc "SELECT string_agg(t || '=' || n, ' ' ORDER BY t) FROM (
  SELECT 'vendas' t, count(*) n FROM sales UNION ALL SELECT 'itens', count(*) FROM sale_items UNION ALL SELECT 'pagamentos', count(*) FROM sale_payments
  UNION ALL SELECT 'clientes', count(*) FROM customers UNION ALL SELECT 'produtos', count(*) FROM products UNION ALL SELECT 'caixas', count(*) FROM cash_registers
  UNION ALL SELECT 'mov_caixa', count(*) FROM cash_movements UNION ALL SELECT 'pagar', count(*) FROM accounts_payable UNION ALL SELECT 'receber', count(*) FROM accounts_receivable
  UNION ALL SELECT 'compras', count(*) FROM purchases UNION ALL SELECT 'itens_compra', count(*) FROM purchase_items UNION ALL SELECT 'estoque', count(*) FROM stock_movements
  UNION ALL SELECT 'planos', count(*) FROM subscription_plans UNION ALL SELECT 'assinaturas', count(*) FROM subscriptions
  UNION ALL SELECT 'pontos', count(*) FROM loyalty_transactions UNION ALL SELECT 'metas', count(*) FROM goals UNION ALL SELECT 'cupons', count(*) FROM promotions
  UNION ALL SELECT 'fixas', count(*) FROM fixed_expenses UNION ALL SELECT 'premios', count(*) FROM loyalty_rewards
  UNION ALL SELECT 'sabores', count(*) FROM cardapio_sabores UNION ALL SELECT 'precos_pizza', count(*) FROM cardapio_sabor_precos UNION ALL SELECT 'itens_cardapio', count(*) FROM cardapio_itens) x"; }
for vez in 1 2; do
  for f in "$TMP"/carga/*.sql; do
    "${PSQL[@]}" -1 -d "$DB" -f "$f" > /dev/null 2> "$TMP/erro.txt" || { head -c 1500 "$TMP/erro.txt"; falha "carga $(basename "$f") (vez $vez)"; }
  done
  eval "C$vez=\"\$(contar)\""
done
echo "   $C1"
[ "$C1" = "$C2" ] || falha "a 2ª carga mudou as contagens: $C2"

echo "4) conferências"
R="$(cat "$TMP/resumo.txt")"
"${PSQL[@]}" -d "$DB" -v resumo="$R" -v loja="$LOJA" -v outra="$OUTRA" -v hoje="$HOJE" > /dev/null <<'SQL'
SELECT set_config('carga.resumo', :'resumo', false), set_config('carga.loja', :'loja', false), set_config('carga.hoje', :'hoje', false);
DO $$ DECLARE r jsonb := current_setting('carga.resumo')::jsonb; loja uuid := current_setting('carga.loja')::uuid; v bigint; x numeric;
BEGIN
  SELECT count(*) INTO v FROM sales WHERE user_id = loja; IF v <> (r->>'vendas')::int THEN RAISE EXCEPTION 'vendas: % ≠ %', v, r->>'vendas'; END IF;
  SELECT count(*) INTO v FROM sale_items WHERE user_id = loja; IF v <> (r->>'itens')::int THEN RAISE EXCEPTION 'itens: % ≠ %', v, r->>'itens'; END IF;
  SELECT count(*) INTO v FROM customers WHERE user_id = loja; IF v <> (r->>'clientes')::int THEN RAISE EXCEPTION 'clientes: %', v; END IF;
  SELECT count(*) INTO v FROM stock_movements WHERE user_id = loja; IF v <> (r->>'movimentos_estoque')::int THEN RAISE EXCEPTION 'estoque: %', v; END IF;
  SELECT round(sum(gross_total), 2) INTO x FROM sales WHERE user_id = loja AND status = 'concluida';
  IF x <> (r->>'receita_concluida')::numeric THEN RAISE EXCEPTION 'receita: % ≠ %', x, r->>'receita_concluida'; END IF;
  -- totais: venda = itens = pagamentos; líquido = bruto − taxa
  SELECT count(*) INTO v FROM sales s WHERE s.user_id = loja AND s.gross_total <> (SELECT sum(subtotal) FROM sale_items i WHERE i.sale_id = s.id);
  IF v > 0 THEN RAISE EXCEPTION '% vendas com itens ≠ total', v; END IF;
  SELECT count(*) INTO v FROM sales s WHERE s.user_id = loja AND s.gross_total <> (SELECT sum(amount) FROM sale_payments p WHERE p.sale_id = s.id);
  IF v > 0 THEN RAISE EXCEPTION '% vendas com pagamentos ≠ total', v; END IF;
  SELECT count(*) INTO v FROM cash_registers WHERE user_id = loja AND expected_balance - closing_balance <> -difference AND closing_balance - expected_balance <> difference;
  IF v > 0 THEN RAISE EXCEPTION '% caixas que não fecham', v; END IF;
  -- nada no futuro
  SELECT count(*) INTO v FROM sales WHERE user_id = loja AND (created_at AT TIME ZONE 'America/Sao_Paulo')::date > current_setting('carga.hoje')::date;
  IF v > 0 THEN RAISE EXCEPTION '% vendas no futuro', v; END IF;
  SELECT count(*) INTO v FROM products WHERE user_id = loja AND stock < 0; IF v > 0 THEN RAISE EXCEPTION 'estoque negativo'; END IF;
  -- a loja nasceu como no cadastro: Dona ativa, loja ativa, plano Premium e módulos ligados
  IF NOT EXISTS (SELECT 1 FROM store_members WHERE store_owner_id = loja AND member_user_id = loja AND dona AND active AND loja_ativa AND papel = 'admin') THEN
    RAISE EXCEPTION 'vínculo de Dona ausente'; END IF;
  IF (SELECT status FROM stores WHERE id = loja) <> 'ativa' THEN RAISE EXCEPTION 'loja não está ativa'; END IF;
  SELECT count(*) INTO v FROM store_modules WHERE store_id = loja AND status = 'ativo';
  RAISE NOTICE 'módulos ligados: %', v;
END $$;
SQL
# a dona vê tudo pela trava (RLS); outra pessoa logada não vê nada
ver() { "${PSQL[@]}" -d "$DB" -tAc "BEGIN; SELECT set_config('request.jwt.claims', '{\"sub\":\"$1\",\"role\":\"authenticated\",\"aal\":\"aal1\"}', true); SET LOCAL ROLE authenticated;
  SELECT (SELECT count(*) FROM sales) || ' ' || (SELECT count(*) FROM customers) || ' ' || (SELECT count(*) FROM products) || ' ' || (SELECT count(*) FROM accounts_payable); ROLLBACK;" | sed -n 2p; }
DONA="$(ver $LOJA)"; OUTRO="$(ver $OUTRA)"
echo "   a dona vê (vendas clientes produtos contas): $DONA · outra pessoa vê: $OUTRO"
[ "$DONA" = "$(echo "$C1" | grep -o 'vendas=[0-9]*' | cut -d= -f2) $(echo "$C1" | grep -o 'clientes=[0-9]*' | cut -d= -f2) $(echo "$C1" | grep -o 'produtos=[0-9]*' | cut -d= -f2) $(echo "$C1" | grep -o 'pagar=[0-9]*' | cut -d= -f2)" ] \
  || falha "a dona não vê tudo: $DONA"
[ "$OUTRO" = "0 0 0 0" ] || falha "outra pessoa vê dados da loja demo: $OUTRO"
echo "CARGA OK"
