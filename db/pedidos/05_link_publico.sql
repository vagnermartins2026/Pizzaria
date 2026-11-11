-- =====================================================================================================
-- Pizzalia · Apoio do link público (Edge Function supabase/functions/link-pedido): endereço da loja, limite de
-- tentativas e acompanhamento do pedido sem dados pessoais. Tudo SÓ do servidor (service_role). Idempotente.
-- =====================================================================================================

CREATE TABLE IF NOT EXISTS public.loja_links (
  store_id   uuid PRIMARY KEY,
  slug       text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9](?:[a-z0-9-]{1,38}[a-z0-9])$'),   -- pizzalia.app/<slug>
  nome       text NOT NULL CHECK (length(btrim(nome)) BETWEEN 2 AND 60),                   -- nome que o cliente vê
  whatsapp   text CHECK (whatsapp IS NULL OR whatsapp ~ '^\+55[1-9][0-9]{9,10}$'),
  ativo      boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Contador por janela de tempo (limite de tentativas no link). Não é movimento: linhas velhas são descartadas.
CREATE TABLE IF NOT EXISTS public.link_tentativas (
  chave text NOT NULL, janela timestamptz NOT NULL, contagem int NOT NULL DEFAULT 1,
  PRIMARY KEY (chave, janela)
);

-- Conta uma tentativa e diz se ainda está dentro do limite (atômico: duas chamadas juntas não furam o limite).
CREATE OR REPLACE FUNCTION public.link_consumir_limite(p_chave text, p_max int, p_janela_seg int) RETURNS boolean
LANGUAGE plpgsql AS $$
DECLARE v_janela timestamptz := to_timestamp(floor(extract(epoch FROM now()) / p_janela_seg) * p_janela_seg);
        v_n int;
BEGIN
  INSERT INTO public.link_tentativas AS t (chave, janela) VALUES (left(p_chave, 120), v_janela)
  ON CONFLICT (chave, janela) DO UPDATE SET contagem = t.contagem + 1
  RETURNING contagem INTO v_n;
  IF random() < 0.01 THEN                                            -- faxina ocasional das janelas antigas
    DELETE FROM public.link_tentativas WHERE janela < now() - interval '1 day';
  END IF;
  RETURN v_n <= p_max;
END $$;

-- Cardápio + situação da loja para o link (o cardápio vai para o cache do CDN; a situação, não).
CREATE OR REPLACE FUNCTION public.link_loja(p_slug text) RETURNS jsonb LANGUAGE sql STABLE AS $$
  SELECT jsonb_build_object('store_id', l.store_id, 'nome', l.nome, 'whatsapp', l.whatsapp)
    FROM public.loja_links l WHERE l.slug = lower(p_slug) AND l.ativo
$$;

-- Acompanhamento por token (o link que o cliente recebe). Sem nome, telefone nem endereço.
CREATE OR REPLACE FUNCTION public.pedido_acompanhar(p_token text) RETURNS jsonb LANGUAGE sql STABLE AS $$
  SELECT jsonb_build_object(
    'numero', p.numero, 'status', p.status,
    'etapa', CASE p.status WHEN 'novo' THEN 'Recebemos seu pedido' WHEN 'em_preparo' THEN 'Seu pedido está sendo preparado'
                           WHEN 'pronto' THEN CASE WHEN p.tipo = 'entrega' THEN 'Pronto, saindo em instantes' ELSE 'Pronto para retirar' END
                           WHEN 'saiu_entrega' THEN 'Saiu para entrega' WHEN 'aguardando_retirada' THEN 'Pronto para retirar'
                           WHEN 'concluido' THEN 'Pedido entregue. Bom apetite!' WHEN 'cancelado' THEN 'Pedido cancelado' END,
    'tipo', p.tipo, 'total_cents', p.total_cents, 'forma_pagamento', p.forma_pagamento,
    'criado_em', p.created_at,
    'previsao', p.created_at + make_interval(mins => COALESCE(c.tempo_preparo_min, 40) + COALESCE(b.minutos_extra, 0)),
    'loja', jsonb_build_object('nome', l.nome, 'whatsapp', l.whatsapp),
    'historico', (SELECT jsonb_agg(jsonb_build_object('status', h.para, 'em', h.em) ORDER BY h.id)
                    FROM public.pedido_status_historico h WHERE h.pedido_id = p.id))
  FROM public.pedidos p
  LEFT JOIN public.loja_config_pedido c ON c.store_id = p.store_id
  LEFT JOIN public.loja_bairros b ON b.id = p.bairro_id
  LEFT JOIN public.loja_links l ON l.store_id = p.store_id
  WHERE p.token_publico = p_token AND p_token ~ '^[0-9a-f]{64}$'
$$;

DO $$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY['public.link_consumir_limite(text,int,int)', 'public.link_loja(text)',
                           'public.pedido_acompanhar(text)'] LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', f);
    END IF;
  END LOOP;
END $$;
