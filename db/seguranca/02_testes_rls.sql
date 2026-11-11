-- Testes do pacote de segurança. Rodam com papéis iguais aos do Supabase (anon, authenticated, service_role) e com a
-- "sessão" simulada por app.store_id / app.papel. Terminam em ROLLBACK. Falha = RAISE EXCEPTION.
\set ON_ERROR_STOP 1
BEGIN;
-- ---------- dados de duas lojas (como superusuário) ----------
DO $$
DECLARE A uuid := '0000000a-0000-4000-8000-000000000000'; B uuid := '0000000b-0000-4000-8000-000000000000';
        r jsonb; s uuid;
BEGIN
  INSERT INTO public.cardapio_itens (id, store_id, nome, preco_cents) VALUES
    ('0000000a-0000-4000-8000-0000000000a1', A, 'Refri A', 1400), ('0000000b-0000-4000-8000-0000000000b1', B, 'Refri B', 1400);
  INSERT INTO public.cardapio_sabores (id, store_id, nome) VALUES (gen_random_uuid(), A, 'Sabor A'), (gen_random_uuid(), B, 'Sabor B');
  INSERT INTO public.cardapio_tamanhos (id, store_id, nome) VALUES ('0000000a-0000-4000-8000-0000000000a2', A, 'Grande');
  INSERT INTO public.cardapio_sabor_precos SELECT s2.id, '0000000a-0000-4000-8000-0000000000a2', 5000
    FROM public.cardapio_sabores s2 WHERE s2.store_id = A;
  r := public.pedido_criar(A, '{"canal":"balcao","tipo":"retirada","forma_pagamento":"pix","itens":[{"tipo":"produto","item_id":"0000000a-0000-4000-8000-0000000000a1"}]}', 'rls-a-0001');
  r := public.pedido_criar(A, '{"canal":"balcao","tipo":"retirada","forma_pagamento":"pix","itens":[{"tipo":"produto","item_id":"0000000a-0000-4000-8000-0000000000a1"}]}', 'rls-a-0002');
  r := public.pedido_criar(B, '{"canal":"balcao","tipo":"retirada","forma_pagamento":"pix","itens":[{"tipo":"produto","item_id":"0000000b-0000-4000-8000-0000000000b1"}]}', 'rls-b-0001');
  INSERT INTO public.loja_bairros (store_id, nome, taxa_cents) VALUES (A, 'Centro', 500);
  r := public.pedido_criar(A, '{"canal":"telefone","tipo":"entrega","forma_pagamento":"pix","endereco":{"bairro":"Centro"},"itens":[{"tipo":"produto","item_id":"0000000a-0000-4000-8000-0000000000a1"}]}', 'rls-a-entrega');
  UPDATE public.pedidos SET status = 'pronto' WHERE id = (r->>'pedido_id')::uuid;
  UPDATE public.pedidos SET status = 'saiu_entrega' WHERE id = (r->>'pedido_id')::uuid;
  INSERT INTO public.crm_oportunidades (id, store_id, customer_id, gatilho, elegivel, status, ordem, criada_para, expira_em) VALUES
    ('0000000a-0000-4000-8000-0000000000a9', A, gen_random_uuid(), 'G1', true, 'aberta', 1, current_date, current_date + 3),
    ('0000000b-0000-4000-8000-0000000000b9', B, gen_random_uuid(), 'G1', true, 'aberta', 1, current_date, current_date + 3);
END $$;

-- ---------- atendente da loja A ----------
SELECT set_config('app.store_id', '0000000a-0000-4000-8000-000000000000', true), set_config('app.papel', 'atendente', true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE A uuid := '0000000a-0000-4000-8000-000000000000'; B uuid := '0000000b-0000-4000-8000-000000000000';
        n int; r jsonb; pa uuid;
BEGIN
  IF (SELECT count(*) FROM public.pedidos) <> 3 OR EXISTS (SELECT 1 FROM public.pedidos WHERE store_id = B) THEN
    RAISE EXCEPTION 'vazamento: a loja A enxerga pedidos de B'; END IF;
  IF (SELECT count(*) FROM public.cardapio_itens) <> 1 OR (SELECT count(*) FROM public.cardapio_sabores) <> 1
     OR (SELECT count(*) FROM public.cardapio_sabor_precos) <> 1 OR (SELECT count(*) FROM public.crm_oportunidades) <> 1
     OR (SELECT count(*) FROM public.pedido_itens) <> 3 OR (SELECT count(*) FROM public.pedido_status_historico) <> 5 THEN
    RAISE EXCEPTION 'vazamento ou leitura faltando nas tabelas de A'; END IF;
  -- atendente não altera cardápio (nem da própria loja); ninguém altera o de outra loja
  UPDATE public.cardapio_itens SET preco_cents = 1 WHERE store_id = A; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'atendente mudou preço'; END IF;
  BEGIN INSERT INTO public.cardapio_itens (store_id, nome, preco_cents) VALUES (A, 'X', 100); RAISE EXCEPTION 'atendente criou item';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  -- movimento: sem DELETE, sem INSERT direto, sem mudar valores
  BEGIN DELETE FROM public.pedidos; RAISE EXCEPTION 'apagou pedido'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN INSERT INTO public.crm_contatos (store_id, customer_id) VALUES (A, gen_random_uuid()); RAISE EXCEPTION 'contato direto';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN UPDATE public.pedidos SET total_cents = 1, subtotal_cents = 1; RAISE EXCEPTION 'mudou valor do pedido';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.pedido_criar(A, '{}'::jsonb, 'rls-direto-01'); RAISE EXCEPTION 'pedido_criar direto';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM count(*) FROM public.loja_contadores; RAISE EXCEPTION 'leu contadores';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  -- status: muda na própria loja; na outra não encontra a linha
  SELECT id INTO pa FROM public.pedidos ORDER BY numero LIMIT 1;
  UPDATE public.pedidos SET status = 'pronto' WHERE id = pa; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'equipe não conseguiu avançar status'; END IF;
  UPDATE public.pedidos SET status = 'cancelado', cancelamento_motivo = 'teste' WHERE store_id = B; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'cancelou pedido de outra loja'; END IF;
  -- PDV: a loja vem da sessão; link não pode ser criado pela equipe
  r := public.pedido_criar_balcao('{"canal":"balcao","tipo":"retirada","forma_pagamento":"pix","itens":[{"tipo":"produto","item_id":"0000000a-0000-4000-8000-0000000000a1"}]}', 'rls-pdv-0001');
  IF (SELECT store_id FROM public.pedidos WHERE id = (r->>'pedido_id')::uuid) <> A THEN RAISE EXCEPTION 'PDV criou em outra loja'; END IF;
  BEGIN PERFORM public.pedido_criar_balcao('{"canal":"link","tipo":"retirada","forma_pagamento":"pix","itens":[]}', 'rls-pdv-0002');
    RAISE EXCEPTION 'equipe criou pedido de link';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'CANAL_INVALIDO%' THEN RAISE; END IF; END;
  BEGIN PERFORM public.pedido_criar_balcao('{"canal":"balcao","tipo":"retirada","forma_pagamento":"pix","itens":[{"tipo":"produto","item_id":"0000000b-0000-4000-8000-0000000000b1"}]}', 'rls-pdv-0003');
    RAISE EXCEPTION 'vendeu item de outra loja';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'ITEM_INDISPONIVEL%' THEN RAISE; END IF; END;
  -- pausa: qualquer pessoa da equipe, só a própria loja
  PERFORM public.loja_ajustar_operacao(true, 'cozinha cheia');
  IF NOT (SELECT pausado FROM public.loja_config_pedido WHERE store_id = A) THEN RAISE EXCEPTION 'pausa'; END IF;
  -- funções que leem: só enxergam a própria loja
  IF public.resumo_hoje(B) #>> '{pedidos,hoje}' <> '0' THEN RAISE EXCEPTION 'resumo de outra loja vazou'; END IF;
  BEGIN PERFORM public.crm_mensagem('0000000b-0000-4000-8000-0000000000b9'); RAISE EXCEPTION 'mensagem de outra loja';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'OPORTUNIDADE_NAO_ELEGIVEL' THEN RAISE; END IF; END;
  BEGIN PERFORM public.crm_descartar('0000000b-0000-4000-8000-0000000000b9'); RAISE EXCEPTION 'descartou de outra loja';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'SEM_ACESSO' THEN RAISE; END IF; END;
  BEGIN PERFORM public.crm_calcular(A, current_date); RAISE EXCEPTION 'equipe rodou o motor';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.pedido_acompanhar(repeat('0', 64)); RAISE EXCEPTION 'equipe chamou função do link';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.link_consumir_limite('x', 1, 60); RAISE EXCEPTION 'equipe mexeu no limite do link';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  -- depois de sair para entrega, atendente não cancela
  BEGIN UPDATE public.pedidos SET status = 'cancelado', cancelamento_motivo = 'cliente desistiu' WHERE status = 'saiu_entrega';
    RAISE EXCEPTION 'atendente cancelou pedido que já saiu';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'SO_O_DONO_CANCELA_APOS_SAIDA' THEN RAISE; END IF; END;
  RAISE NOTICE 'segurança/atendente: OK';
END $$;
RESET ROLE;

-- ---------- gerente e dono da loja A ----------
SELECT set_config('app.papel', 'gerente', true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE A uuid := '0000000a-0000-4000-8000-000000000000'; B uuid := '0000000b-0000-4000-8000-000000000000'; n int;
BEGIN
  UPDATE public.cardapio_itens SET preco_cents = 1500 WHERE store_id = A; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'gerente não mudou o preço da própria loja'; END IF;
  BEGIN INSERT INTO public.cardapio_itens (store_id, nome, preco_cents) VALUES (B, 'Invasor', 100); RAISE EXCEPTION 'gerente criou item em outra loja';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN UPDATE public.cardapio_itens SET store_id = B WHERE store_id = A; RAISE EXCEPTION 'gerente moveu item para outra loja';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  UPDATE public.crm_modelos SET corpo = 'x' WHERE store_id IS NULL; GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'loja alterou modelo da plataforma'; END IF;
  BEGIN UPDATE public.pedidos SET status = 'cancelado', cancelamento_motivo = 'cliente desistiu' WHERE status = 'saiu_entrega';
    RAISE EXCEPTION 'gerente cancelou pedido que já saiu';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'SO_O_DONO_CANCELA_APOS_SAIDA' THEN RAISE; END IF; END;
  RAISE NOTICE 'segurança/gerente: OK';
END $$;
RESET ROLE;
SELECT set_config('app.papel', 'dono', true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE n int; BEGIN
  UPDATE public.pedidos SET status = 'cancelado', cancelamento_motivo = 'cliente desistiu' WHERE status = 'saiu_entrega';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'dono não conseguiu cancelar depois da saída'; END IF;
  RAISE NOTICE 'segurança/dono: OK';
END $$;
RESET ROLE;

-- ---------- anônimo: nada direto ----------
SET LOCAL ROLE anon;
DO $$ BEGIN
  BEGIN PERFORM count(*) FROM public.pedidos; RAISE EXCEPTION 'anônimo leu pedidos'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM count(*) FROM public.cardapio_itens; RAISE EXCEPTION 'anônimo leu cardápio'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN PERFORM public.pedido_criar_balcao('{}'::jsonb, 'anon-000001'); RAISE EXCEPTION 'anônimo chamou RPC';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  RAISE NOTICE 'segurança/anônimo: OK';
END $$;
RESET ROLE;

-- ---------- cobertura: toda tabela do módulo com RLS; nenhuma policy de DELETE em movimento; visões invoker ----------
DO $$
DECLARE faltando text; del text; vis text;
BEGIN
  SELECT string_agg(c.relname, ', ') INTO faltando FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relname ~ '^(cardapio_|pedido|loja_|link_|crm_)' AND NOT c.relrowsecurity;
  IF faltando IS NOT NULL THEN RAISE EXCEPTION 'tabelas sem RLS: %', faltando; END IF;
  SELECT string_agg(tablename || '.' || policyname, ', ') INTO del FROM pg_policies
   WHERE schemaname = 'public' AND cmd IN ('DELETE', 'ALL')
     AND tablename IN ('pedidos','pedido_itens','pedido_item_sabores','pedido_item_adicionais','pedido_status_historico',
                       'crm_oportunidades','crm_contatos','crm_customer_stats','loja_contadores');
  IF del IS NOT NULL THEN RAISE EXCEPTION 'policy de DELETE em movimento: %', del; END IF;
  SELECT string_agg(c.relname, ', ') INTO vis FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public' AND c.relkind = 'v' AND c.relname LIKE 'crm_fatos_%'
     AND NOT COALESCE(c.reloptions @> ARRAY['security_invoker=true'], false);
  IF vis IS NOT NULL THEN RAISE EXCEPTION 'visões sem security_invoker (ignorariam a RLS): %', vis; END IF;
  RAISE NOTICE 'segurança/cobertura: OK (todas as tabelas com RLS, sem DELETE em movimento, visões invoker)';
END $$;
ROLLBACK;
