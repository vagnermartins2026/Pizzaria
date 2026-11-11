-- =====================================================================================================
-- Pizzalia · Carregador da pizzaria DEMO (Forno da Vila) nos módulos próprios (cardápio, pedidos, entrega,
-- link, CRM). Lê as tabelas de apoio demo_* (CSVs de demo/gerar_dados_demo.py, como texto).
-- Travas (docs/PILOTO-DEMO.md): tudo na loja demo (tenant próprio); idempotente (ON CONFLICT DO NOTHING);
-- remoção = por store_id da loja demo, nunca por filtro genérico. Os módulos da BASE (financeiro, estoque, caixa,
-- compras, entregadores, mesas, fiscal) entram depois do remix: ver db/seed/LEIAME.md.
-- =====================================================================================================
\set ON_ERROR_STOP 1
SELECT id::uuid AS loja, name AS nome, slug FROM public.demo_tenants LIMIT 1 \gset

INSERT INTO public.loja_links (store_id, slug, nome, whatsapp) VALUES (:'loja', :'slug', :'nome', '+5519900000000')
ON CONFLICT (store_id) DO NOTHING;
INSERT INTO public.loja_config_pedido (store_id, pedido_minimo_cents, tempo_preparo_min) VALUES (:'loja', 3000, 40)
ON CONFLICT (store_id) DO NOTHING;
INSERT INTO public.loja_horarios (store_id, dia_semana, abre, fecha)
SELECT :'loja', d, '18:00', CASE WHEN d IN (5, 6) THEN '00:30' WHEN d = 0 THEN '23:00' ELSE '23:30' END::time
FROM generate_series(0, 6) d WHERE d <> 1                                     -- segunda fechado
  AND NOT EXISTS (SELECT 1 FROM public.loja_horarios WHERE store_id = :'loja');
INSERT INTO public.loja_bairros (id, store_id, nome, taxa_cents, minutos_extra)
SELECT id::uuid, tenant_id::uuid, neighborhood, fee_cents::bigint, extra_minutes::int FROM public.demo_delivery_zones
ON CONFLICT DO NOTHING;

-- cardápio
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

-- pedidos históricos (inserção direta: o histórico já aconteceu; numeração em ordem de criação)
INSERT INTO public.pedidos (id, store_id, numero, data_negocio, canal, tipo, status, customer_id, cliente_nome,
       cliente_telefone, endereco, bairro_id, subtotal_cents, taxa_entrega_cents, total_cents, forma_pagamento,
       idempotency_key, cancelamento_motivo, created_at, updated_at)
SELECT o.id::uuid, o.tenant_id::uuid, row_number() OVER (ORDER BY o.created_at::timestamptz, o.id),
       o.business_date::date,
       CASE o.channel WHEN 'link' THEN 'link' WHEN 'phone' THEN 'telefone' ELSE 'balcao' END,
       CASE o.type WHEN 'delivery' THEN 'entrega' ELSE 'retirada' END,
       CASE o.status WHEN 'concluded' THEN 'concluido' ELSE 'cancelado' END,
       c.id::uuid, c.name, c.phone_e164,
       CASE WHEN o.type = 'delivery' THEN jsonb_build_object('rua', a.street, 'bairro', a.neighborhood) END,
       CASE WHEN o.type = 'delivery' THEN b.id END,
       o.subtotal_cents::bigint, o.delivery_fee_cents::bigint, o.total_cents::bigint,
       CASE o.payment_method WHEN 'credit' THEN 'credito' WHEN 'debit' THEN 'debito' WHEN 'cash' THEN 'dinheiro' ELSE 'pix' END,
       'demo-' || o.id, CASE WHEN o.status <> 'concluded' THEN 'cliente desistiu (demo)' END,
       o.created_at::timestamptz, o.created_at::timestamptz + interval '50 minutes'
FROM public.demo_orders o
JOIN public.demo_customers c ON c.id = o.customer_id
LEFT JOIN public.demo_customer_addresses a ON a.customer_id = c.id
LEFT JOIN public.loja_bairros b ON b.store_id = o.tenant_id::uuid AND b.nome = a.neighborhood
ON CONFLICT DO NOTHING;

INSERT INTO public.pedido_itens (id, pedido_id, tipo, tamanho_id, item_id, nome, tamanho_nome, preco_unitario_cents, quantidade)
SELECT i.id::uuid, i.order_id::uuid, CASE i.kind WHEN 'pizza' THEN 'pizza' ELSE 'produto' END,
       t.id, ci.id, i.name_snapshot, NULLIF(i.size_snapshot, ''), i.unit_price_cents::bigint, i.qty::int
FROM public.demo_order_items i
JOIN public.demo_orders o ON o.id = i.order_id
LEFT JOIN public.cardapio_tamanhos t ON t.store_id = o.tenant_id::uuid AND t.nome = i.size_snapshot
LEFT JOIN public.cardapio_itens ci ON ci.store_id = o.tenant_id::uuid AND ci.nome = i.name_snapshot AND i.kind = 'product'
WHERE NOT EXISTS (SELECT 1 FROM public.pedido_itens x WHERE x.id = i.id::uuid);
INSERT INTO public.pedido_item_sabores (pedido_item_id, sabor_id, nome, fracao)
SELECT f.order_item_id::uuid, f.flavor_id::uuid, f.name_snapshot, f.fraction::numeric FROM public.demo_order_item_flavors f
WHERE NOT EXISTS (SELECT 1 FROM public.pedido_item_sabores x WHERE x.pedido_item_id = f.order_item_id::uuid AND x.sabor_id = f.flavor_id::uuid);
INSERT INTO public.pedido_item_adicionais (pedido_item_id, adicional_id, nome, preco_cents)
SELECT a.order_item_id::uuid, a.addon_id::uuid, a.name_snapshot, a.price_cents::bigint FROM public.demo_order_item_addons a
WHERE NOT EXISTS (SELECT 1 FROM public.pedido_item_adicionais x WHERE x.pedido_item_id = a.order_item_id::uuid);
INSERT INTO public.pedido_status_historico (pedido_id, de, para, motivo, em)
SELECT p.id, s.de, s.para, CASE WHEN s.para = 'cancelado' THEN p.cancelamento_motivo END, p.created_at + s.depois
FROM public.pedidos p
CROSS JOIN LATERAL (VALUES (NULL, 'novo', interval '0'), ('novo', 'em_preparo', interval '3 minutes'),
                           ('em_preparo', 'pronto', interval '25 minutes'),
                           ('pronto', CASE WHEN p.tipo = 'entrega' THEN 'saiu_entrega' ELSE 'aguardando_retirada' END, interval '30 minutes'),
                           (CASE WHEN p.tipo = 'entrega' THEN 'saiu_entrega' ELSE 'aguardando_retirada' END, 'concluido', interval '50 minutes'))
     AS s(de, para, depois)
WHERE p.store_id = :'loja' AND p.status = 'concluido' AND p.idempotency_key LIKE 'demo-%'
  AND NOT EXISTS (SELECT 1 FROM public.pedido_status_historico h WHERE h.pedido_id = p.id)
UNION ALL
SELECT p.id, s.de, s.para, CASE WHEN s.para = 'cancelado' THEN p.cancelamento_motivo END, p.created_at + s.depois
FROM public.pedidos p
CROSS JOIN LATERAL (VALUES (NULL, 'novo', interval '0'), ('novo', 'cancelado', interval '4 minutes')) AS s(de, para, depois)
WHERE p.store_id = :'loja' AND p.status = 'cancelado' AND p.idempotency_key LIKE 'demo-%'
  AND NOT EXISTS (SELECT 1 FROM public.pedido_status_historico h WHERE h.pedido_id = p.id);
INSERT INTO public.loja_contadores (store_id, ultimo_pedido)
SELECT :'loja', max(numero) FROM public.pedidos WHERE store_id = :'loja'
ON CONFLICT (store_id) DO UPDATE SET ultimo_pedido = GREATEST(public.loja_contadores.ultimo_pedido, EXCLUDED.ultimo_pedido);
