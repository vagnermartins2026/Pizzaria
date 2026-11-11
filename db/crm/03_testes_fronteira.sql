-- Testes do motor do CRM: fronteiras das regras puras + cenários de ciclo de vida (contato, conversão, bloqueios).
-- Rodam numa loja de teste isolada (tenant próprio) e terminam com ROLLBACK: não deixam nada no banco.
-- Falha = RAISE EXCEPTION com a descrição do caso.
BEGIN;

DO $$
DECLARE
  casos int[][] := ARRAY[  -- pedidos, dias, intervalo (-1 = sem intervalo), esperado (0=nenhum,1..4 = G1..G4)
    [2,24,-1,0],[2,25,-1,1],[2,59,-1,1],[2,60,-1,4],[2,180,-1,4],[2,181,-1,0],
    [1,9,-1,0],[1,10,-1,3],[1,59,-1,3],[1,60,-1,4],
    [5,13,7,0],[5,14,7,2],[5,28,14,2],[5,27,14,1],[5,59,21,2],[5,60,21,4],[5,44,22,1]];
  c int[]; obtido text; esperado text;
BEGIN
  FOREACH c SLICE 1 IN ARRAY casos LOOP
    obtido := public.crm_gatilho(c[1], c[2], CASE WHEN c[3] < 0 THEN NULL ELSE c[3] END);
    esperado := CASE c[4] WHEN 0 THEN NULL ELSE 'G' || c[4] END;
    IF obtido IS DISTINCT FROM esperado THEN
      RAISE EXCEPTION 'fronteira: pedidos=% dias=% intervalo=% -> %, esperado %', c[1], c[2], c[3], obtido, esperado;
    END IF;
  END LOOP;
  -- aniversário: virada do ano, no dia, véspera do ano seguinte, 29/02 em ano comum
  IF public.crm_dias_ate_aniversario('1990-01-01', '2026-12-30') <> 2 THEN RAISE EXCEPTION 'aniversário: virada do ano'; END IF;
  IF public.crm_dias_ate_aniversario('1990-11-08', '2026-11-08') <> 0 THEN RAISE EXCEPTION 'aniversário: no dia'; END IF;
  IF public.crm_dias_ate_aniversario('1990-11-07', '2026-11-08') <> 364 THEN RAISE EXCEPTION 'aniversário: passou ontem'; END IF;
  IF public.crm_dias_ate_aniversario('1992-02-29', '2027-02-27') <> 1 THEN RAISE EXCEPTION 'aniversário: 29/02'; END IF;
  RAISE NOTICE 'fronteiras: OK (17 casos de gatilho + 4 de aniversário)';
END $$;

-- ---------- cenários de ciclo de vida numa loja de teste ----------
DO $$
DECLARE
  loja uuid := '00000000-0000-4000-8000-00000000aaaa';
  d date := '2026-06-10';
  c1 text := '00000000-0000-4000-8000-0000000000c1';  -- G1, será contatado e vai comprar (convertida)
  c2 text := '00000000-0000-4000-8000-0000000000c2';  -- G1, contato há 6 dias (bloqueado)
  c3 text := '00000000-0000-4000-8000-0000000000c3';  -- G1, contato há 7 dias (liberado)
  c4 text := '00000000-0000-4000-8000-0000000000c4';  -- G1, sem contato, compra sozinho (voltou sozinho)
  c5 text := '00000000-0000-4000-8000-0000000000c5';  -- G1, sem consentimento (bloqueado)
  c6 text := '00000000-0000-4000-8000-0000000000c6';  -- G1, revogou o consentimento depois de dar (bloqueado)
  v record; n1 int; n2 int; op uuid;
BEGIN
  INSERT INTO public.demo_customers (id, tenant_id, name, birth_date) VALUES
    (c1, loja, 'Teste 1', ''), (c2, loja, 'Teste 2', ''), (c3, loja, 'Teste 3', ''),
    (c4, loja, 'Teste 4', ''), (c5, loja, 'Teste 5', ''), (c6, loja, 'Teste 6', '');
  INSERT INTO public.demo_marketing_consents (customer_id, status, recorded_at) VALUES
    (c1, 'granted', '2026-01-01'), (c2, 'granted', '2026-01-01'), (c3, 'granted', '2026-01-01'),
    (c4, 'granted', '2026-01-01'), (c6, 'granted', '2026-01-01'), (c6, 'revoked', '2026-03-01');
  -- dois pedidos para cada um, o último há 30 dias → G1
  INSERT INTO public.demo_orders (id, tenant_id, customer_id, status, total_cents, business_date)
  SELECT gen_random_uuid()::text, loja, c, 'concluded', '9000', (d - k)::text
  FROM unnest(ARRAY[c1, c2, c3, c4, c5, c6]) AS c, unnest(ARRAY[30, 60]) AS k;
  INSERT INTO public.crm_contatos (store_id, customer_id, enviado_em) VALUES
    (loja, c2::uuid, (d - 6)::timestamp AT TIME ZONE 'America/Sao_Paulo'),
    (loja, c3::uuid, (d - 7)::timestamp AT TIME ZONE 'America/Sao_Paulo');

  PERFORM public.crm_calcular(loja, d);
  FOR v IN SELECT customer_id::text AS cid, gatilho, status, motivo_bloqueio FROM public.crm_oportunidades
            WHERE store_id = loja AND criada_para = d LOOP
    IF v.cid = c1 AND (v.gatilho, v.status) IS DISTINCT FROM ('G1', 'aberta') THEN RAISE EXCEPTION 'c1: % %', v.gatilho, v.status; END IF;
    IF v.cid = c2 AND v.motivo_bloqueio IS DISTINCT FROM 'contato_recente' THEN RAISE EXCEPTION 'c2 deveria estar em descanso (6 dias): %', v.motivo_bloqueio; END IF;
    IF v.cid = c3 AND v.status <> 'aberta' THEN RAISE EXCEPTION 'c3 deveria estar liberado (7 dias): %', v.motivo_bloqueio; END IF;
    IF v.cid = c5 AND v.motivo_bloqueio IS DISTINCT FROM 'sem_consentimento' THEN RAISE EXCEPTION 'c5 sem consentimento: %', v.motivo_bloqueio; END IF;
    IF v.cid = c6 AND v.motivo_bloqueio IS DISTINCT FROM 'sem_consentimento' THEN RAISE EXCEPTION 'c6 revogou: %', v.motivo_bloqueio; END IF;
  END LOOP;
  SELECT count(*) INTO n1 FROM public.crm_oportunidades WHERE store_id = loja;
  PERFORM public.crm_calcular(loja, d);                                   -- rodar de novo no mesmo dia
  SELECT count(*) INTO n2 FROM public.crm_oportunidades WHERE store_id = loja;
  IF n1 <> 6 OR n2 <> 6 THEN RAISE EXCEPTION 'idempotência: % depois %, esperado 6 e 6', n1, n2; END IF;

  -- c1 recebe a mensagem hoje e compra 2 dias depois; c4 compra sozinho amanhã
  SELECT id INTO op FROM public.crm_oportunidades WHERE store_id = loja AND customer_id = c1::uuid;
  UPDATE public.crm_oportunidades SET status = 'contatada' WHERE id = op;
  INSERT INTO public.crm_contatos (store_id, customer_id, oportunidade_id, gatilho, enviado_em)
    VALUES (loja, c1::uuid, op, 'G1', d::timestamp AT TIME ZONE 'America/Sao_Paulo' + interval '17 hours');
  INSERT INTO public.demo_orders (id, tenant_id, customer_id, status, total_cents, business_date) VALUES
    (gen_random_uuid()::text, loja, c1, 'concluded', '9500', (d + 2)::text),
    (gen_random_uuid()::text, loja, c4, 'concluded', '8000', (d + 1)::text);
  PERFORM public.crm_calcular(loja, d + 2);
  IF (SELECT status FROM public.crm_oportunidades WHERE id = op) <> 'convertida' THEN
    RAISE EXCEPTION 'c1 deveria estar convertida'; END IF;
  IF (SELECT status FROM public.crm_oportunidades WHERE store_id = loja AND customer_id = c4::uuid AND criada_para = d)
     <> 'voltou_sozinho' THEN RAISE EXCEPTION 'c4 deveria ser "voltou sozinho"'; END IF;
  -- c3 tem oportunidade aberta de d (vale até d+3): não ganha outra em d+2
  IF EXISTS (SELECT 1 FROM public.crm_oportunidades WHERE store_id = loja AND customer_id = c3::uuid AND criada_para = d + 2) THEN
    RAISE EXCEPTION 'c3 ganhou 2 cartões ao mesmo tempo'; END IF;
  -- em d+4 a oportunidade de c3 expira e ele volta a ser avaliado
  PERFORM public.crm_calcular(loja, d + 4);
  IF (SELECT status FROM public.crm_oportunidades WHERE store_id = loja AND customer_id = c3::uuid AND criada_para = d) <> 'expirada' THEN
    RAISE EXCEPTION 'c3 deveria ter expirado'; END IF;
  -- o contato de c1 em d bloqueia nova mensagem até d+7 (c1 comprou em d+2: dias = 2, sem gatilho; ok não aparecer)
  RAISE NOTICE 'cenários: OK (consentimento, revogação, descanso 6/7 dias, idempotência, conversão, voltou sozinho, cartão único, expiração)';
END $$;

ROLLBACK;
