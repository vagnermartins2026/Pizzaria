-- Adaptador do CRM sobre os PEDIDOS CARREGADOS (tabelas pedidos / pedido_item_sabores / loja_links).
-- Clientes e consentimento ainda vêm das tabelas de apoio demo_* até o remix; depois, do cadastro da base.
CREATE OR REPLACE VIEW public.crm_fatos_pedido WITH (security_invoker = true) AS
  SELECT store_id, customer_id, id AS order_id, data_negocio AS business_date, total_cents
  FROM public.pedidos WHERE status = 'concluido' AND customer_id IS NOT NULL;
CREATE OR REPLACE VIEW public.crm_fatos_sabor WITH (security_invoker = true) AS
  SELECT p.store_id, p.id AS order_id, s.nome AS sabor, s.fracao
  FROM public.pedido_item_sabores s JOIN public.pedido_itens i ON i.id = s.pedido_item_id
  JOIN public.pedidos p ON p.id = i.pedido_id AND p.status = 'concluido';
CREATE OR REPLACE VIEW public.crm_fatos_em_andamento WITH (security_invoker = true) AS
  SELECT DISTINCT store_id, customer_id FROM public.pedidos
  WHERE status IN ('novo','em_preparo','pronto','saiu_entrega','aguardando_retirada') AND customer_id IS NOT NULL;
CREATE OR REPLACE VIEW public.crm_fatos_loja WITH (security_invoker = true) AS
  SELECT store_id, nome, 'https://pizzalia.app/' || slug AS link_pedido FROM public.loja_links;
CREATE OR REPLACE VIEW public.crm_fatos_cliente WITH (security_invoker = true) AS
  SELECT c.tenant_id::uuid AS store_id, c.id::uuid AS customer_id, c.name AS nome, NULLIF(c.phone_e164, '') AS telefone,
         NULLIF(c.birth_date, '')::date AS birth_date,
         (SELECT m.status FROM public.demo_marketing_consents m WHERE m.customer_id = c.id
           ORDER BY m.recorded_at::timestamptz DESC LIMIT 1) AS consentimento
  FROM public.demo_customers c;
