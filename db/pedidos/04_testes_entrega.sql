-- Testes de entrega, horário, pausa e pedido mínimo. Loja de teste isolada; termina em ROLLBACK.
-- Datas em horário de Brasília (-03, sem horário de verão desde 2019). 13/11/2026 = sexta-feira.
BEGIN;
DO $$
DECLARE
  E uuid := '00000000-0000-4000-8000-0000000000ee'; S uuid := '00000000-0000-4000-8000-0000000000ef';
  refri uuid := gen_random_uuid(); refri_s uuid := gen_random_uuid(); r jsonb; caso record;
  ped jsonb;
BEGIN
  INSERT INTO public.cardapio_itens (id, store_id, nome, preco_cents) VALUES (refri, E, 'Refrigerante 2L', 1400),
                                                                    (refri_s, S, 'Refrigerante 2L', 1400);
  INSERT INTO public.loja_horarios (store_id, dia_semana, abre, fecha) VALUES
    (E, 5, '18:00', '00:30'),                       -- sexta: passa da meia-noite
    (E, 6, '11:00', '14:00'), (E, 6, '18:00', '23:00');  -- sábado: dois turnos; domingo fechado
  INSERT INTO public.loja_bairros (store_id, nome, taxa_cents, minutos_extra, ativo) VALUES
    (E, 'Cambuí', 600, 0, true), (E, 'Nova Campinas', 800, 10, true), (E, 'Barão Geraldo', 1200, 20, false);
  INSERT INTO public.loja_config_pedido (store_id, pedido_minimo_cents, tempo_preparo_min) VALUES (E, 5000, 40);

  FOR caso IN SELECT * FROM (VALUES
      ('2026-11-13 17:59-03', false), ('2026-11-13 18:00-03', true), ('2026-11-13 23:59-03', true),
      ('2026-11-14 00:29-03', true),  ('2026-11-14 00:30-03', false), ('2026-11-14 10:59-03', false),
      ('2026-11-14 11:00-03', true),  ('2026-11-14 13:59-03', true), ('2026-11-14 14:00-03', false),
      ('2026-11-14 18:00-03', true),  ('2026-11-14 23:00-03', false), ('2026-11-15 12:00-03', false),
      ('2026-11-13 21:00+00', true)   -- 18:00 em Brasília, informado em UTC
    ) AS t(quando, esperado) LOOP
    IF public.loja_aberta(E, caso.quando::timestamptz) <> caso.esperado THEN
      RAISE EXCEPTION 'horário: % deveria ser aberta=%', caso.quando, caso.esperado;
    END IF;
  END LOOP;
  r := public.loja_status_link(E, '2026-11-15 12:00-03');
  IF r->>'proxima_abertura' <> '2026-11-20T18:00' THEN RAISE EXCEPTION 'próxima abertura (domingo → sexta 18h): %', r; END IF;
  r := public.loja_status_link(E, '2026-11-14 15:00-03');
  IF r->>'proxima_abertura' <> '2026-11-14T18:00' THEN RAISE EXCEPTION 'próxima abertura (entre turnos): %', r; END IF;

  IF (public.loja_taxa_bairro(E, ' CAMBUI ')).taxa_cents <> 600 THEN RAISE EXCEPTION 'bairro sem acento/maiúscula'; END IF;
  IF (public.loja_taxa_bairro(E, 'nova   campinas')).taxa_cents <> 800 THEN RAISE EXCEPTION 'bairro com espaços'; END IF;
  IF (public.loja_taxa_bairro(E, 'Barão Geraldo')).id IS NOT NULL THEN RAISE EXCEPTION 'bairro inativo atendido'; END IF;

  ped := jsonb_build_object('canal','link','tipo','entrega','forma_pagamento','pix',
           'cliente', jsonb_build_object('telefone','19998765432'), 'endereco', jsonb_build_object('bairro','cambui'),
           'itens', jsonb_build_array(jsonb_build_object('tipo','produto','item_id',refri,'quantidade',4)));
  r := public.pedido_criar(E, ped, 'entrega-0001', '2026-11-13 19:00-03');
  IF (r->>'total_cents')::int <> 5600 + 600 THEN RAISE EXCEPTION 'total com frete: %', r; END IF;
  IF (SELECT data_negocio FROM public.pedidos WHERE id = (r->>'pedido_id')::uuid) <> '2026-11-13' THEN
    RAISE EXCEPTION 'data de negócio'; END IF;

  FOR caso IN SELECT * FROM (VALUES
      ('PEDIDO_MINIMO',       jsonb_set(ped, '{itens,0,quantidade}', '3'), '2026-11-13 19:00-03'),   -- 4200 < 5000
      ('BAIRRO_NAO_ATENDIDO', jsonb_set(ped, '{endereco,bairro}', '"Barão Geraldo"'), '2026-11-13 19:00-03'),
      ('BAIRRO_NAO_ATENDIDO', ped - 'endereco', '2026-11-13 19:00-03'),
      ('LOJA_FECHADA',        ped, '2026-11-15 12:00-03')
    ) AS t(erro, p, quando) LOOP
    BEGIN
      PERFORM public.pedido_criar(E, caso.p, 'recusa-' || md5(caso.p::text || caso.quando), caso.quando::timestamptz);
      RAISE EXCEPTION 'deveria recusar com %', caso.erro;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM NOT LIKE caso.erro || '%' THEN RAISE EXCEPTION 'esperado %, veio: %', caso.erro, SQLERRM; END IF;
    END;
  END LOOP;
  -- mínimo vale só para entrega; com a loja fechada, o balcão continua vendendo
  r := public.pedido_criar(E, jsonb_set(jsonb_set(ped, '{tipo}', '"retirada"'), '{itens,0,quantidade}', '1'),
                           'retirada-0001', '2026-11-13 19:00-03');
  IF (r->>'total_cents')::int <> 1400 THEN RAISE EXCEPTION 'retirada sem mínimo nem frete: %', r; END IF;
  r := public.pedido_criar(E, jsonb_set(ped, '{canal}', '"balcao"'), 'balcao-0001', '2026-11-15 12:00-03');
  IF (r->>'total_cents')::int <> 6200 THEN RAISE EXCEPTION 'balcão com a loja fechada: %', r; END IF;

  UPDATE public.loja_config_pedido SET pausado = true, pausado_motivo = 'cozinha cheia' WHERE store_id = E;
  BEGIN
    PERFORM public.pedido_criar(E, ped, 'pausa-0001', '2026-11-13 19:00-03');
    RAISE EXCEPTION 'deveria recusar com PEDIDOS_PAUSADOS';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'PEDIDOS_PAUSADOS: cozinha cheia' THEN RAISE; END IF; END;
  r := public.pedido_criar(E, jsonb_set(ped, '{canal}', '"telefone"'), 'pausa-0002', '2026-11-13 19:00-03');
  IF (r->>'numero')::int <> 4 THEN RAISE EXCEPTION 'telefone durante a pausa / número sem buraco: %', r; END IF;

  BEGIN
    PERFORM public.pedido_criar(S, jsonb_set(jsonb_set(ped, '{tipo}', '"retirada"'), '{itens,0,item_id}', to_jsonb(refri_s)),
                                'sem-horario-0001', '2026-11-13 19:00-03');
    RAISE EXCEPTION 'loja sem horário deveria recusar o link';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'LOJA_SEM_HORARIO' THEN RAISE; END IF; END;
  RAISE NOTICE 'entrega e horário: OK (13 instantes de horário com virada da meia-noite e dois turnos, próxima abertura, bairro normalizado e inativo, frete, mínimo só na entrega, 4 recusas, balcão com loja fechada, pausa, loja sem horário)';
END $$;
ROLLBACK;
