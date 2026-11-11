#!/usr/bin/env bash
# Prova do pacote de segurança num banco DESCARTÁVEL, com os papéis do Supabase (anon, authenticated, service_role).
# Simula o pior caso do Supabase: antes do pacote, anon e authenticated recebem TODOS os privilégios nas tabelas.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"; DB=pizzalia_teste_seguranca
PSQL=(psql -X -q -v ON_ERROR_STOP=1 -d "$DB")
QUIETO=(env PGOPTIONS="-c client_min_messages=warning")   # preparação sem avisos de "não existe, pulando"
dropdb --if-exists --force "$DB"; createdb "$DB"
"${PSQL[@]}" <<'SQL'
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
END $$;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
-- tabelas mínimas que a visão de contrato da demo lê
CREATE TABLE demo_tenants (id text, name text, slug text);
CREATE TABLE demo_orders (id text, tenant_id text, customer_id text, status text, total_cents text, business_date text, type text, delivery_fee_cents text);
CREATE TABLE demo_order_items (id text, order_id text);
CREATE TABLE demo_order_item_flavors (order_item_id text, name_snapshot text, fraction text);
CREATE TABLE demo_customers (id text, tenant_id text, name text, phone_e164 text, birth_date text);
CREATE TABLE demo_marketing_consents (customer_id text, status text, recorded_at text);
-- contrato da base (no Supabase vem da base remixada; aqui, da sessão simulada)
CREATE FUNCTION public.current_store_id() RETURNS uuid LANGUAGE sql STABLE AS $f$ SELECT nullif(current_setting('app.store_id', true), '')::uuid $f$;
CREATE FUNCTION public.pizzalia_papel() RETURNS text LANGUAGE sql STABLE AS $f$ SELECT nullif(current_setting('app.papel', true), '') $f$;
GRANT EXECUTE ON FUNCTION public.current_store_id(), public.pizzalia_papel() TO authenticated;
SQL
for f in db/pedidos/01_cardapio_pedido.sql db/pedidos/02_entrega_horario.sql db/pedidos/05_link_publico.sql db/crm/01_motor_crm.sql db/crm/04_campanhas.sql \
         db/crm/05_resumo.sql db/crm/02_adaptador_demo.sql; do "${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/$f" >/dev/null; done
"${PSQL[@]}" -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
                 GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;"   # padrão do Supabase
"${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/db/seguranca/01_rls.sql" >/dev/null
"${QUIETO[@]}" "${PSQL[@]}" -f "$RAIZ/db/seguranca/01_rls.sql" >/dev/null                                            # idempotente
set +e
saida=$("${PSQL[@]}" -f "$RAIZ/db/seguranca/02_testes_rls.sql" 2>&1); r=$?
set -e
echo "$saida" | grep -E "NOTICE|ERROR" | sed 's/^psql:[^ ]* //; s/^/  /' || true
dropdb --if-exists "$DB"
[[ $r -eq 0 ]] && echo "PROVA OK" || { echo "PROVA FALHOU"; exit 1; }
