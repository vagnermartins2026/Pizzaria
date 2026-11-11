-- Carrega o cardápio da pizzaria DEMO (CSVs em demo_*) nas tabelas cardapio_* e confere, item a item, que o banco
-- calcula o MESMO preço que o gerador usou nos ~9 mil itens de pedido (gabarito de preço, RN-03).
INSERT INTO public.cardapio_categorias (id, store_id, nome, ordem)
  SELECT id::uuid, tenant_id::uuid, name, sort_order::int FROM public.demo_categories ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_tamanhos (id, store_id, nome, fatias, max_sabores, ordem)
  SELECT id::uuid, tenant_id::uuid, name, slices::int, max_flavors::int, sort_order::int FROM public.demo_pizza_sizes ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_sabores (id, store_id, categoria_id, nome)
  SELECT id::uuid, tenant_id::uuid, category_id::uuid, name FROM public.demo_flavors ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_sabor_precos (sabor_id, tamanho_id, preco_cents)
  SELECT flavor_id::uuid, size_id::uuid, price_cents::bigint FROM public.demo_flavor_prices ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_grupos_adicionais (id, store_id, nome, min_escolhas, max_escolhas)
  SELECT id::uuid, tenant_id::uuid, name, min_choices::int, max_choices::int FROM public.demo_addon_groups ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_adicionais (id, store_id, grupo_id, nome, preco_cents)
  SELECT id::uuid, tenant_id::uuid, group_id::uuid, name, price_cents::bigint FROM public.demo_addons ON CONFLICT DO NOTHING;
INSERT INTO public.cardapio_itens (id, store_id, categoria_id, nome, preco_cents)
  SELECT id::uuid, tenant_id::uuid, category_id::uuid, name, price_cents::bigint FROM public.demo_products ON CONFLICT DO NOTHING;

CREATE TEMP TABLE gabarito_preco AS
SELECT oi.id, oi.kind, oi.unit_price_cents::bigint AS esperado,
       (public.cardapio_preco_item(o.tenant_id::uuid, CASE oi.kind
          WHEN 'pizza' THEN jsonb_build_object('tipo', 'pizza',
               'tamanho_id', (SELECT t.id FROM public.cardapio_tamanhos t WHERE t.store_id = o.tenant_id::uuid AND t.nome = oi.size_snapshot),
               'sabores', (SELECT jsonb_agg(f.flavor_id) FROM public.demo_order_item_flavors f WHERE f.order_item_id = oi.id),
               'adicionais', COALESCE((SELECT jsonb_agg(a.addon_id) FROM public.demo_order_item_addons a WHERE a.order_item_id = oi.id), '[]'))
          ELSE jsonb_build_object('tipo', 'produto',
               'item_id', (SELECT i.id FROM public.cardapio_itens i WHERE i.store_id = o.tenant_id::uuid AND i.nome = oi.name_snapshot))
        END) ->> 'preco_unitario_cents')::bigint AS obtido
FROM public.demo_order_items oi JOIN public.demo_orders o ON o.id = oi.order_id;

SELECT count(*) AS itens, count(*) FILTER (WHERE kind = 'pizza') AS pizzas,
       count(*) FILTER (WHERE obtido IS DISTINCT FROM esperado) AS divergentes
FROM gabarito_preco \gset
\echo 'gabarito de preço: ' :itens ' itens (' :pizzas ' pizzas), divergentes: ' :divergentes
SELECT CASE WHEN :divergentes > 0 THEN 1/0 END AS ok \g /dev/null

-- Etapa B (se instalada): bairros da demo e gabarito de frete — a taxa de cada pedido de entrega da demo precisa
-- ser a do bairro do cliente.
SELECT to_regclass('public.loja_bairros') IS NOT NULL AS tem_entrega \gset
\if :tem_entrega
INSERT INTO public.loja_bairros (id, store_id, nome, taxa_cents, minutos_extra)
  SELECT id::uuid, tenant_id::uuid, neighborhood, fee_cents::bigint, extra_minutes::int FROM public.demo_delivery_zones
  ON CONFLICT DO NOTHING;
SELECT count(*) AS entregas,
       count(*) FILTER (WHERE (public.loja_taxa_bairro(o.tenant_id::uuid, a.neighborhood)).taxa_cents
                              IS DISTINCT FROM o.delivery_fee_cents::bigint) AS frete_divergente
  FROM public.demo_orders o JOIN public.demo_customer_addresses a ON a.customer_id = o.customer_id
 WHERE o.type = 'delivery' \gset
\echo 'gabarito de frete: ' :entregas ' entregas, divergentes: ' :frete_divergente
SELECT CASE WHEN :frete_divergente > 0 THEN 1/0 END AS ok \g /dev/null
\endif
