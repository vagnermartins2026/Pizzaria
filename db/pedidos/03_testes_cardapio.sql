-- Testes do cardápio e do pedido numa loja de teste isolada. Terminam em ROLLBACK. Falha = RAISE EXCEPTION.
BEGIN;
DO $$
DECLARE
  L uuid := '00000000-0000-4000-8000-0000000000bb';
  broto uuid := gen_random_uuid(); grande uuid := gen_random_uuid(); familia uuid := gen_random_uuid();
  sa uuid := gen_random_uuid(); sb uuid := gen_random_uuid(); sc uuid := gen_random_uuid(); sd uuid := gen_random_uuid();
  gb uuid := gen_random_uuid(); bcat uuid := gen_random_uuid(); bche uuid := gen_random_uuid(); refri uuid := gen_random_uuid();
  r jsonb; r2 jsonb; erro text; pid uuid; n int;
BEGIN
  INSERT INTO public.cardapio_tamanhos (id, store_id, nome, max_sabores, ordem) VALUES
    (broto, L, 'Broto', 1, 0), (grande, L, 'Grande', 2, 1), (familia, L, 'Família', 3, 2);
  INSERT INTO public.cardapio_sabores (id, store_id, nome, ativo) VALUES
    (sa, L, 'A', true), (sb, L, 'B', true), (sc, L, 'C', true), (sd, L, 'D inativo', false);
  INSERT INTO public.cardapio_sabor_precos VALUES
    (sa, broto, 3000), (sb, broto, 4000), (sd, broto, 3000),              -- C não existe no Broto
    (sa, grande, 5000), (sb, grande, 7000), (sc, grande, 6100), (sd, grande, 5000),
    (sa, familia, 6500), (sb, familia, 9100), (sc, familia, 7930);
  INSERT INTO public.cardapio_grupos_adicionais (id, store_id, nome, min_escolhas, max_escolhas) VALUES (gb, L, 'Bordas', 0, 1);
  INSERT INTO public.cardapio_adicionais (id, store_id, grupo_id, nome, preco_cents) VALUES
    (bcat, L, gb, 'Borda Catupiry', 1200), (bche, L, gb, 'Borda Cheddar', 1200);
  INSERT INTO public.cardapio_adicional_precos VALUES (bcat, familia, 1500);
  INSERT INTO public.cardapio_itens (id, store_id, nome, preco_cents) VALUES (refri, L, 'Refrigerante 2L', 1400);

  -- RN-03: maior preço (padrão) e média arredondada para cima
  r := public.cardapio_preco_item(L, jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa,sb)));
  IF (r->>'preco_unitario_cents')::int <> 7000 THEN RAISE EXCEPTION 'maior preço: %', r->>'preco_unitario_cents'; END IF;
  INSERT INTO public.loja_config_pedido (store_id, regra_preco_pizza) VALUES (L, 'media');
  r := public.cardapio_preco_item(L, jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa,sc)));
  IF (r->>'preco_unitario_cents')::int <> 5550 THEN RAISE EXCEPTION 'média 2 sabores: %', r->>'preco_unitario_cents'; END IF;
  r := public.cardapio_preco_item(L, jsonb_build_object('tipo','pizza','tamanho_id',familia,'sabores',jsonb_build_array(sa,sb,sc)));
  IF (r->>'preco_unitario_cents')::int <> 7844 THEN RAISE EXCEPTION 'média 3 sabores (23530/3 ↑): %', r->>'preco_unitario_cents'; END IF;
  UPDATE public.loja_config_pedido SET regra_preco_pizza = 'maior' WHERE store_id = L;
  -- adicional com preço por tamanho e sem preço próprio no tamanho
  r := public.cardapio_preco_item(L, jsonb_build_object('tipo','pizza','tamanho_id',familia,'sabores',jsonb_build_array(sa),'adicionais',jsonb_build_array(bcat)));
  IF (r->>'preco_unitario_cents')::int <> 8000 THEN RAISE EXCEPTION 'borda no Família (6500+1500): %', r->>'preco_unitario_cents'; END IF;
  r := public.cardapio_preco_item(L, jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa),'adicionais',jsonb_build_array(bcat)));
  IF (r->>'preco_unitario_cents')::int <> 6200 THEN RAISE EXCEPTION 'borda no Grande (5000+1200): %', r->>'preco_unitario_cents'; END IF;

  -- validações que precisam recusar
  FOR erro, r IN SELECT * FROM (VALUES
      ('QUANTIDADE_DE_SABORES', jsonb_build_object('tipo','pizza','tamanho_id',broto,'sabores',jsonb_build_array(sa,sb))),
      ('QUANTIDADE_DE_SABORES', jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores','[]'::jsonb)),
      ('SABOR_INDISPONIVEL_NO_TAMANHO', jsonb_build_object('tipo','pizza','tamanho_id',broto,'sabores',jsonb_build_array(sc))),
      ('SABOR_INDISPONIVEL_NO_TAMANHO', jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sd))),
      ('SABOR_REPETIDO', jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa,sa))),
      ('ESCOLHAS_DO_GRUPO', jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa),'adicionais',jsonb_build_array(bcat,bche))),
      ('ADICIONAL_REPETIDO', jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sa),'adicionais',jsonb_build_array(bcat,bcat))),
      ('QUANTIDADE_INVALIDA', jsonb_build_object('tipo','produto','item_id',refri,'quantidade',0)),
      ('TAMANHO_INDISPONIVEL', jsonb_build_object('tipo','pizza','tamanho_id',gen_random_uuid(),'sabores',jsonb_build_array(sa)))
    ) AS t(e, j) LOOP
    BEGIN
      PERFORM public.cardapio_preco_item(L, r);
      RAISE EXCEPTION 'deveria recusar com %: %', erro, r;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE erro || '%' THEN RAISE EXCEPTION 'esperado %, veio: %', erro, SQLERRM; END IF;
    END;
  END LOOP;

  -- telefone (RN-13)
  IF public.fone_e164_br('(19) 99876-5432') <> '+5519998765432' THEN RAISE EXCEPTION 'fone celular'; END IF;
  IF public.fone_e164_br('+55 (19) 99876-5432') <> '+5519998765432' THEN RAISE EXCEPTION 'fone +55'; END IF;
  IF public.fone_e164_br('019 99876-5432') <> '+5519998765432' THEN RAISE EXCEPTION 'fone 0+DDD'; END IF;
  IF public.fone_e164_br('19 3232-1010') <> '+551932321010' THEN RAISE EXCEPTION 'fone fixo'; END IF;
  IF public.fone_e164_br('99876-5432') IS NOT NULL THEN RAISE EXCEPTION 'fone sem DDD deveria ser inválido'; END IF;
  IF public.fone_e164_br('(19) 1234-5678') IS NOT NULL THEN RAISE EXCEPTION 'fixo começando com 1 é inválido'; END IF;

  -- pedido: preço do navegador ignorado, idempotência, número sem buraco
  r := public.pedido_criar(L, jsonb_build_object('canal','link','tipo','retirada','forma_pagamento','pix',
         'cliente', jsonb_build_object('nome','Maria','telefone','(19) 99876-5432'),
         'total_esperado_cents', 9800,
         'itens', jsonb_build_array(
            jsonb_build_object('tipo','pizza','tamanho_id',grande,'sabores',jsonb_build_array(sb,sa),'preco_unitario_cents',1),
            jsonb_build_object('tipo','produto','item_id',refri,'quantidade',2))), 'chave-0001');
  IF (r->>'total_cents')::int <> 9800 OR (r->>'numero')::int <> 1 OR (r->>'repetido')::boolean THEN RAISE EXCEPTION 'pedido 1: %', r; END IF;
  pid := (r->>'pedido_id')::uuid;
  r2 := public.pedido_criar(L, jsonb_build_object('canal','link','tipo','retirada','forma_pagamento','pix',
         'cliente', jsonb_build_object('telefone','19998765432'), 'itens', jsonb_build_array(
            jsonb_build_object('tipo','produto','item_id',refri))), 'chave-0001');
  IF (r2->>'pedido_id')::uuid <> pid OR NOT (r2->>'repetido')::boolean THEN RAISE EXCEPTION 'idempotência: %', r2; END IF;
  BEGIN
    PERFORM public.pedido_criar(L, jsonb_build_object('canal','link','tipo','retirada','forma_pagamento','pix',
         'cliente', jsonb_build_object('telefone','19998765432'), 'total_esperado_cents', 1000,
         'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'chave-0002');
    RAISE EXCEPTION 'deveria recusar PRECO_MUDOU';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'PRECO_MUDOU' THEN RAISE; END IF; END;
  BEGIN
    PERFORM public.pedido_criar(L, jsonb_build_object('canal','link','tipo','retirada','forma_pagamento','pix',
         'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'chave-0003');
    RAISE EXCEPTION 'link sem telefone deveria recusar';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'TELEFONE_INVALIDO' THEN RAISE; END IF; END;
  BEGIN
    PERFORM public.pedido_criar(L, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','dinheiro',
         'troco_para_cents', 1000, 'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'chave-0004');
    RAISE EXCEPTION 'troco menor que o total deveria recusar';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'TROCO_MENOR_QUE_TOTAL' THEN RAISE; END IF; END;
  r := public.pedido_criar(L, jsonb_build_object('canal','balcao','tipo','retirada','forma_pagamento','dinheiro',
         'troco_para_cents', 2000, 'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri))), 'chave-0005');
  IF (r->>'numero')::int <> 2 THEN RAISE EXCEPTION 'recusas não podem gastar número: veio %', r->>'numero'; END IF;
  IF (SELECT status FROM public.pedidos WHERE id = (r->>'pedido_id')::uuid) <> 'em_preparo' THEN
    RAISE EXCEPTION 'pedido de balcão nasce em preparo'; END IF;
  IF (SELECT count(*) FROM public.pedido_item_sabores s JOIN public.pedido_itens i ON i.id = s.pedido_item_id
      WHERE i.pedido_id = pid) <> 2 THEN RAISE EXCEPTION 'sabores não copiados'; END IF;

  -- máquina de estados (§9)
  UPDATE public.pedidos SET status = 'em_preparo' WHERE id = pid;
  UPDATE public.pedidos SET status = 'pronto' WHERE id = pid;
  BEGIN UPDATE public.pedidos SET status = 'saiu_entrega' WHERE id = pid; RAISE EXCEPTION 'retirada não sai para entrega';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'TRANSICAO_INVALIDA%' THEN RAISE; END IF; END;
  UPDATE public.pedidos SET status = 'aguardando_retirada' WHERE id = pid;
  UPDATE public.pedidos SET status = 'concluido' WHERE id = pid;
  BEGIN UPDATE public.pedidos SET status = 'em_preparo' WHERE id = pid; RAISE EXCEPTION 'concluído não volta';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'TRANSICAO_INVALIDA%' THEN RAISE; END IF; END;
  BEGIN UPDATE public.pedidos SET total_cents = 1, subtotal_cents = 1 WHERE id = pid; RAISE EXCEPTION 'valor de concluído não muda';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'PEDIDO_ENCERRADO%' THEN RAISE; END IF; END;
  BEGIN DELETE FROM public.pedidos WHERE id = pid; RAISE EXCEPTION 'pedido não se apaga';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'SOMENTE_INSERCAO%' THEN RAISE; END IF; END;
  BEGIN UPDATE public.pedidos SET status = 'cancelado' WHERE id = (r->>'pedido_id')::uuid; RAISE EXCEPTION 'cancelar sem motivo';
  EXCEPTION WHEN check_violation THEN NULL; END;
  UPDATE public.pedidos SET status = 'cancelado', cancelamento_motivo = 'cliente desistiu' WHERE id = (r->>'pedido_id')::uuid;
  SELECT count(*) INTO n FROM public.pedido_status_historico WHERE pedido_id = pid;
  IF n <> 5 THEN RAISE EXCEPTION 'histórico do pedido 1: % linhas, esperado 5', n; END IF;
  IF jsonb_array_length(public.cardapio_publico(L)->'sabores') <> 3 THEN RAISE EXCEPTION 'cardápio público mostra inativo'; END IF;
  RAISE NOTICE 'cardápio e pedido: OK (preço maior/média, adicional por tamanho, 9 recusas, telefone, preço do navegador ignorado, idempotência, número sem buraco, estados, imutabilidade)';
END $$;
ROLLBACK;
