-- Testes de campanhas e do Resumo de hoje numa loja de teste isolada. Terminam em ROLLBACK.
BEGIN;
DO $$ BEGIN   -- no banco de teste não há a base: a "loja ativa" vem de app.store_id (no Supabase, da base remixada)
  IF to_regprocedure('public.current_store_id()') IS NULL THEN
    EXECUTE $f$CREATE FUNCTION public.current_store_id() RETURNS uuid LANGUAGE sql STABLE AS
             'SELECT nullif(current_setting(''app.store_id'', true), '''')::uuid'$f$;
  END IF;
END $$;

DO $$
DECLARE
  T uuid := '00000000-0000-4000-8000-0000000000cc'; OUTRA uuid := '00000000-0000-4000-8000-0000000000cd';
  d date := '2026-06-10';                                        -- quarta-feira
  c1 text := '00000000-0000-4000-8000-0000000001c1'; c2 text := '00000000-0000-4000-8000-0000000001c2';
  c3 text := '00000000-0000-4000-8000-0000000001c3'; c4 text := '00000000-0000-4000-8000-0000000001c4';
  o1 uuid; o2 uuid; o3 uuid; o4 uuid; r jsonb; k uuid; k2 uuid; refri uuid := gen_random_uuid(); i int;
BEGIN
  IF public.url_codificar('Oi, Ã 😊 ~-_.') <> 'Oi%2C%20%C3%83%20%F0%9F%98%8A%20~-_.' THEN RAISE EXCEPTION 'url_codificar'; END IF;
  IF public.brl(0) <> 'R$ 0,00' OR public.brl(5) <> 'R$ 0,05' OR public.brl(100000) <> 'R$ 1.000,00'
     OR public.brl(123456789) <> 'R$ 1.234.567,89' OR public.brl(-1550) <> '-R$ 15,50' THEN RAISE EXCEPTION 'brl'; END IF;

  INSERT INTO public.demo_tenants (id, name, slug) VALUES (T, 'Pizzaria Teste', 'teste');
  INSERT INTO public.demo_customers (id, tenant_id, name, phone_e164, birth_date) VALUES
    (c1, T, 'Ana Souza', '+5519900000001', ''), (c2, T, 'Bruno Lima', '+5519900000002', ''),
    (c3, T, 'Carla Dias', '', ''), (c4, T, 'Davi Melo', '+5519900000004', '');
  INSERT INTO public.demo_marketing_consents (customer_id, status, recorded_at) VALUES
    (c1, 'granted', '2026-01-01'), (c2, 'granted', '2026-01-01'), (c3, 'granted', '2026-01-01');
  -- 2 pedidos de cada um (último há 30 dias → G1); c1 pede Calabresa nos dois, c2 um sabor diferente em cada
  FOR i IN 1..2 LOOP
    INSERT INTO public.demo_orders (id, tenant_id, customer_id, status, total_cents, business_date)
    SELECT md5('p' || c || i)::uuid::text, T, c, 'concluded', '9000', (d - 30 * i)::text FROM unnest(ARRAY[c1, c2, c3, c4]) c;
    INSERT INTO public.demo_order_items (id, order_id) SELECT md5('i' || c || i)::uuid::text, md5('p' || c || i)::uuid::text FROM unnest(ARRAY[c1, c2, c3, c4]) c;
  END LOOP;
  INSERT INTO public.demo_order_item_flavors (order_item_id, name_snapshot, fraction) VALUES
    (md5('i' || c1 || 1)::uuid::text, 'Calabresa', '1'), (md5('i' || c1 || 2)::uuid::text, 'Calabresa', '0.5'),
    (md5('i' || c1 || 2)::uuid::text, 'Atum', '0.5'), (md5('i' || c2 || 1)::uuid::text, 'Mussarela', '1'),
    (md5('i' || c2 || 2)::uuid::text, 'Portuguesa', '1');

  PERFORM public.crm_calcular(T, d);
  SELECT id INTO o1 FROM public.crm_oportunidades WHERE store_id = T AND customer_id = c1::uuid;
  SELECT id INTO o2 FROM public.crm_oportunidades WHERE store_id = T AND customer_id = c2::uuid;
  SELECT id INTO o3 FROM public.crm_oportunidades WHERE store_id = T AND customer_id = c3::uuid;
  SELECT id INTO o4 FROM public.crm_oportunidades WHERE store_id = T AND customer_id = c4::uuid;
  IF (SELECT sabores_favoritos FROM public.crm_customer_stats WHERE store_id = T AND customer_id = c1::uuid) <> '{Calabresa}' THEN
    RAISE EXCEPTION 'favorito de c1 (Atum só em 1 pedido não conta)'; END IF;

  r := public.crm_mensagem(o1);
  IF r->>'modelo' <> 'G1.1' OR r->>'texto' NOT LIKE 'Oi, Ana! %Calabresa está entre as suas favoritas%https://pizzalia.app/teste%Responda SAIR.'
     OR r->>'whatsapp_url' NOT LIKE 'https://wa.me/5519900000001?text=Oi%2C%20Ana%21%20%' THEN RAISE EXCEPTION 'mensagem c1: %', r; END IF;
  r := public.crm_mensagem(o2);
  IF r->>'modelo' <> 'G1.2' OR r->>'texto' LIKE '%{%' THEN RAISE EXCEPTION 'sem favorito usa a variante 2: %', r; END IF;
  IF public.crm_mensagem(o3)->>'whatsapp_url' IS NOT NULL THEN RAISE EXCEPTION 'sem telefone, sem link'; END IF;
  BEGIN PERFORM public.crm_mensagem(o4); RAISE EXCEPTION 'bloqueada não gera mensagem';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'OPORTUNIDADE_NAO_ELEGIVEL' THEN RAISE; END IF; END;

  -- modelos da loja substituem os da plataforma; variável desconhecida faz cair para a próxima variante
  INSERT INTO public.crm_modelos (store_id, gatilho, variante, corpo) VALUES
    (T, 'G1', 1, 'Olá {primeiro_nome}, use o cupom {cupom}! {link_pedido}'), (T, 'G1', 2, 'Olá {primeiro_nome}, saudade! {link_pedido}');
  r := public.crm_mensagem(o1);
  IF r->>'modelo' <> 'G1.2' OR r->>'texto' NOT LIKE 'Olá Ana, saudade! https://pizzalia.app/teste%' THEN RAISE EXCEPTION 'modelo da loja: %', r; END IF;
  UPDATE public.crm_modelos SET ativo = false WHERE store_id = T;

  -- Resumo de hoje (antes de qualquer envio): 3 mensagens prontas, 1 sem autorização
  INSERT INTO public.cardapio_itens (id, store_id, nome, preco_cents) VALUES (refri, T, 'Refrigerante 2L', 1400);
  FOR i IN 1..3 LOOP PERFORM public.pedido_criar(T, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','pix',
      'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'resumo-hoje-' || i, (d + time '19:00') AT TIME ZONE 'America/Sao_Paulo'); END LOOP;
  FOR i IN 1..2 LOOP PERFORM public.pedido_criar(T, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','pix',
      'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'resumo-sem-' || i, (d - 7 + time '19:00') AT TIME ZONE 'America/Sao_Paulo'); END LOOP;
  r := public.resumo_hoje(T, d);
  IF r #>> '{pedidos,frase}' <> 'Hoje: 3 pedidos, 1 a mais que na quarta passada.' THEN RAISE EXCEPTION 'frase pedidos: %', r; END IF;
  IF r #>> '{vendas,frase}' <> 'Vendas de hoje: R$ 42,00.' OR r #>> '{valor_medio,frase}' <> 'Valor médio do pedido: R$ 14,00.' THEN
    RAISE EXCEPTION 'vendas/valor médio: %', r; END IF;
  IF r->'atencao' <> '["3 mensagens prontas para enviar hoje.", "1 cliente não autorizou receber mensagens: peça a autorização no próximo pedido."]'::jsonb THEN
    RAISE EXCEPTION 'atenção: %', r->'atencao'; END IF;
  IF public.resumo_hoje(T, d + 1) #>> '{pedidos,frase}' <> 'Hoje ainda não há pedidos.' THEN RAISE EXCEPTION 'dia sem pedidos'; END IF;
  PERFORM public.pedido_criar(T, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','pix',
      'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'resumo-sab-1', timestamptz '2026-06-13 19:00-03');
  PERFORM public.pedido_criar(T, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','pix',
      'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'resumo-sab-2', timestamptz '2026-06-06 19:00-03');
  IF public.resumo_hoje(T, '2026-06-13') #>> '{pedidos,frase}' <> 'Hoje: 1 pedido, o mesmo número do sábado passado.' THEN
    RAISE EXCEPTION 'frase no masculino: %', public.resumo_hoje(T, '2026-06-13') #>> '{pedidos,frase}'; END IF;

  -- registrar envio, toque duplo, "não enviei", prazo, outra loja, descarte
  PERFORM set_config('app.store_id', T::text, true);
  k := public.crm_registrar_contato(o1);
  IF (SELECT status FROM public.crm_oportunidades WHERE id = o1) <> 'contatada' THEN RAISE EXCEPTION 'contatada'; END IF;
  IF public.crm_registrar_contato(o1) <> k THEN RAISE EXCEPTION 'toque duplo criou 2 registros'; END IF;
  PERFORM public.crm_desfazer_contato(k);
  IF (SELECT status FROM public.crm_oportunidades WHERE id = o1) <> 'aberta'
     OR (SELECT desfeito_em FROM public.crm_contatos WHERE id = k) IS NULL THEN RAISE EXCEPTION 'não enviei'; END IF;
  k2 := public.crm_registrar_contato(o1);
  UPDATE public.crm_contatos SET enviado_em = now() - interval '11 minutes' WHERE id = k2;
  BEGIN PERFORM public.crm_desfazer_contato(k2); RAISE EXCEPTION 'prazo de 10 min';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'PRAZO_ENCERRADO' THEN RAISE; END IF; END;
  BEGIN PERFORM public.crm_registrar_contato(o4); RAISE EXCEPTION 'bloqueada';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'OPORTUNIDADE_NAO_ELEGIVEL' THEN RAISE; END IF; END;
  PERFORM public.crm_descartar(o2, 'cliente pediu para não receber hoje');
  BEGIN PERFORM public.crm_descartar(o2); RAISE EXCEPTION 'descartar duas vezes';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'OPORTUNIDADE_JA_TRATADA%' THEN RAISE; END IF; END;
  PERFORM set_config('app.store_id', OUTRA::text, true);
  BEGIN PERFORM public.crm_registrar_contato(o3); RAISE EXCEPTION 'outra loja registrou contato';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'SEM_ACESSO' THEN RAISE; END IF; END;

  -- c1 compra 2 dias depois do envio → convertida, e o Resumo mostra o resultado
  INSERT INTO public.demo_orders (id, tenant_id, customer_id, status, total_cents, business_date)
    VALUES (md5('conv-c1')::uuid::text, T, c1, 'concluded', '9500', (d + 2)::text);
  UPDATE public.crm_contatos SET enviado_em = (d + time '17:00') AT TIME ZONE 'America/Sao_Paulo' WHERE id = k2;
  PERFORM public.crm_calcular(T, d + 2);
  IF (SELECT status FROM public.crm_oportunidades WHERE id = o1) <> 'convertida' THEN RAISE EXCEPTION 'conversão'; END IF;
  IF public.resumo_hoje(T, d + 2) #>> '{mensagens,frase}' <> 'As mensagens dos últimos 7 dias trouxeram 1 pedido (R$ 95,00).' THEN
    RAISE EXCEPTION 'resultado das mensagens: %', public.resumo_hoje(T, d + 2) #>> '{mensagens,frase}'; END IF;
  RAISE NOTICE 'campanhas e resumo: OK (url, R$, favorito, variantes, sem telefone, bloqueada, modelo da loja, frases do resumo no feminino e no masculino, atenção, envio, toque duplo, não enviei, prazo, descarte, outra loja, conversão)';
END $$;
ROLLBACK;
