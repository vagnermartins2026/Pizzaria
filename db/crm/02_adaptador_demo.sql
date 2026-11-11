-- Adaptador da pizzaria DEMO (CSVs de demo/gerar_dados_demo.py, já carregados em demo_* como texto).
-- Na base remixada (MayFlower), outro adaptador implementa as MESMAS três visões a partir de sales / loja_pedidos /
-- customers, e o gabarito continua valendo.
CREATE OR REPLACE VIEW public.crm_fatos_pedido AS
  SELECT tenant_id::uuid AS store_id, customer_id::uuid AS customer_id, id::uuid AS order_id,
         business_date::date AS business_date, total_cents::bigint AS total_cents
  FROM public.demo_orders WHERE status = 'concluded' AND customer_id <> '';

CREATE OR REPLACE VIEW public.crm_fatos_cliente AS
  SELECT c.tenant_id::uuid AS store_id, c.id::uuid AS customer_id, c.name AS nome,
         NULLIF(c.birth_date, '')::date AS birth_date,
         (SELECT m.status FROM public.demo_marketing_consents m
           WHERE m.customer_id = c.id ORDER BY m.recorded_at::timestamptz DESC LIMIT 1) AS consentimento
  FROM public.demo_customers c;

CREATE OR REPLACE VIEW public.crm_fatos_em_andamento AS
  SELECT NULL::uuid AS store_id, NULL::uuid AS customer_id WHERE false;
