-- =====================================================================================================
-- Fornalia · Resumo de hoje (PRD M08, RF-70, RF-71): até 4 números, cada um com uma frase de leitura, e até 3 itens
-- de "o que merece atenção". Lê pedidos (db/pedidos) e CRM; é SECURITY INVOKER: a RLS decide o que cada um vê.
-- =====================================================================================================

-- R$ 1.234,56 sem depender do idioma do servidor.
CREATE OR REPLACE FUNCTION public.brl(p_cents bigint) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN p_cents < 0 THEN '-' ELSE '' END || 'R$ '
      || regexp_replace((abs(p_cents) / 100)::text, '(\d)(?=(\d{3})+$)', '\1.', 'g')
      || ',' || lpad((abs(p_cents) % 100)::text, 2, '0')
$$;

CREATE OR REPLACE FUNCTION public.resumo_hoje(p_store uuid,
                                              p_hoje date DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')::date)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  n int; n7 int; vendas bigint; conv int; conv_v bigint; vip int; abertas int; sem_aut int;
  dia text := (ARRAY['segunda','terça','quarta','quinta','sexta','sábado','domingo'])[extract(isodow FROM p_hoje)::int];
  masc boolean := extract(isodow FROM p_hoje) >= 6;                                     -- "o sábado", "o domingo"
  ref text; f_ped text; diff int; atencao jsonb := '[]';
BEGIN
  SELECT count(*), COALESCE(sum(total_cents), 0) INTO n, vendas FROM public.pedidos
   WHERE store_id = p_store AND data_negocio = p_hoje AND status <> 'cancelado';
  SELECT count(*) INTO n7 FROM public.pedidos
   WHERE store_id = p_store AND data_negocio = p_hoje - 7 AND status <> 'cancelado';
  SELECT count(*), COALESCE(sum(f.total_cents), 0) INTO conv, conv_v
    FROM public.crm_oportunidades o JOIN public.crm_fatos_pedido f ON f.store_id = o.store_id AND f.order_id = o.pedido_id
   WHERE o.store_id = p_store AND o.status = 'convertida' AND f.business_date BETWEEN p_hoje - 6 AND p_hoje;
  SELECT count(*) FILTER (WHERE elegivel AND status = 'aberta' AND gatilho IN ('G1','G2') AND (contexto->>'vip')::boolean),
         count(*) FILTER (WHERE elegivel AND status = 'aberta'),
         count(*) FILTER (WHERE motivo_bloqueio = 'sem_consentimento')
    INTO vip, abertas, sem_aut
    FROM public.crm_oportunidades WHERE store_id = p_store AND criada_para = p_hoje;

  ref := CASE WHEN masc THEN 'no ' || dia || ' passado' ELSE 'na ' || dia || ' passada' END;
  diff := n - n7;
  f_ped := CASE
    WHEN n = 0 THEN 'Hoje ainda não há pedidos.'
    WHEN diff > 0 THEN format('Hoje: %s %s, %s a mais que %s.', n, CASE WHEN n = 1 THEN 'pedido' ELSE 'pedidos' END, diff, ref)
    WHEN diff < 0 THEN format('Hoje: %s %s, %s a menos que %s.', n, CASE WHEN n = 1 THEN 'pedido' ELSE 'pedidos' END, -diff, ref)
    ELSE format('Hoje: %s %s, o mesmo número %s.', n, CASE WHEN n = 1 THEN 'pedido' ELSE 'pedidos' END,
                CASE WHEN masc THEN 'do ' || dia || ' passado' ELSE 'da ' || dia || ' passada' END) END;

  IF vip > 0 THEN atencao := atencao || to_jsonb(format('%s %s VIP %s sumindo.', vip,
                    CASE WHEN vip = 1 THEN 'cliente' ELSE 'clientes' END, CASE WHEN vip = 1 THEN 'está' ELSE 'estão' END)); END IF;
  IF abertas > 0 THEN atencao := atencao || to_jsonb(format('%s %s para enviar hoje.', abertas,
                    CASE WHEN abertas = 1 THEN 'mensagem pronta' ELSE 'mensagens prontas' END)); END IF;
  IF sem_aut > 0 THEN atencao := atencao || to_jsonb(format('%s %s não %s receber mensagens: peça a autorização no próximo pedido.',
                    sem_aut, CASE WHEN sem_aut = 1 THEN 'cliente' ELSE 'clientes' END,
                    CASE WHEN sem_aut = 1 THEN 'autorizou' ELSE 'autorizaram' END)); END IF;

  RETURN jsonb_build_object(
    'pedidos',     jsonb_build_object('hoje', n, 'semana_passada', n7, 'frase', f_ped),
    'vendas',      jsonb_build_object('cents', vendas, 'frase', 'Vendas de hoje: ' || public.brl(vendas) || '.'),
    'valor_medio', jsonb_build_object('cents', CASE WHEN n > 0 THEN vendas / n END,
                     'frase', CASE WHEN n > 0 THEN 'Valor médio do pedido: ' || public.brl(vendas / n) || '.' END),
    'mensagens',   jsonb_build_object('pedidos', conv, 'cents', conv_v, 'frase', CASE WHEN conv = 0
                     THEN 'Nos últimos 7 dias as mensagens ainda não trouxeram pedidos.'
                     ELSE format('As mensagens dos últimos 7 dias trouxeram %s %s (%s).', conv,
                                 CASE WHEN conv = 1 THEN 'pedido' ELSE 'pedidos' END, public.brl(conv_v)) END),
    'atencao', (SELECT COALESCE(jsonb_agg(x), '[]') FROM (SELECT x FROM jsonb_array_elements(atencao) x LIMIT 3) y));
END $$;
