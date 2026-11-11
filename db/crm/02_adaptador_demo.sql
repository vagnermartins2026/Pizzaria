-- Adaptador da pizzaria DEMO (CSVs de demo/gerar_dados_demo.py, já carregados em demo_* como texto).
-- Na base remixada (MayFlower), outro adaptador implementa as MESMAS três visões a partir de sales / loja_pedidos /
-- customers, e o gabarito continua valendo.
CREATE OR REPLACE VIEW public.crm_fatos_pedido WITH (security_invoker = true) AS
  SELECT tenant_id::uuid AS store_id, customer_id::uuid AS customer_id, id::uuid AS order_id,
         business_date::date AS business_date, total_cents::bigint AS total_cents
  FROM public.demo_orders WHERE status = 'concluded' AND customer_id <> '';

CREATE OR REPLACE VIEW public.crm_fatos_cliente WITH (security_invoker = true) AS
  SELECT c.tenant_id::uuid AS store_id, c.id::uuid AS customer_id, c.name AS nome, NULLIF(c.phone_e164, '') AS telefone,
         NULLIF(c.birth_date, '')::date AS birth_date,
         (SELECT m.status FROM public.demo_marketing_consents m
           WHERE m.customer_id = c.id ORDER BY m.recorded_at::timestamptz DESC LIMIT 1) AS consentimento
  FROM public.demo_customers c;

CREATE OR REPLACE VIEW public.crm_fatos_em_andamento WITH (security_invoker = true) AS
  SELECT NULL::uuid AS store_id, NULL::uuid AS customer_id WHERE false;

CREATE OR REPLACE VIEW public.crm_fatos_sabor WITH (security_invoker = true) AS
  SELECT o.tenant_id::uuid AS store_id, o.id::uuid AS order_id, f.name_snapshot AS sabor, f.fraction::numeric AS fracao
  FROM public.demo_order_item_flavors f
  JOIN public.demo_order_items i ON i.id = f.order_item_id
  JOIN public.demo_orders o ON o.id = i.order_id AND o.status = 'concluded';

CREATE OR REPLACE VIEW public.crm_fatos_loja WITH (security_invoker = true) AS
  SELECT id::uuid AS store_id, name AS nome, 'https://fornalia.app/' || slug AS link_pedido FROM public.demo_tenants;
