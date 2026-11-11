-- =====================================================================================================
-- Pizzalia · Entrega por bairro, horário de funcionamento, pausa e pedido mínimo (PRD RF-07 a RF-12, RN-08 a RN-10).
-- Substitui pedido_validar_operacao() de 01_cardapio_pedido.sql. Idempotente, só aditivo.
-- Regras: horário/pausa valem só para o LINK (balcão e telefone seguem funcionando); bairro e mínimo valem para
-- toda ENTREGA; o mínimo é sobre o subtotal dos itens, sem frete. Fuso: America/Sao_Paulo.
-- =====================================================================================================

CREATE TABLE IF NOT EXISTS public.loja_horarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id   uuid NOT NULL,
  dia_semana smallint NOT NULL CHECK (dia_semana BETWEEN 0 AND 6),   -- 0 = domingo (igual ao extract(dow))
  abre       time NOT NULL,
  fecha      time NOT NULL,                                          -- fecha <= abre = turno passa da meia-noite
  CHECK (abre <> fecha)                                              -- dia inteiro: 00:00 às 24:00
);
CREATE INDEX IF NOT EXISTS loja_horarios_loja ON public.loja_horarios (store_id, dia_semana);

-- "Cambuí", "cambui" e " CAMBUÍ " são o mesmo bairro.
CREATE OR REPLACE FUNCTION public.normalizar_bairro(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT regexp_replace(btrim(translate(lower(coalesce(p, '')),
           'áàâãäéèêëíìîïóòôõöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn')), '\s+', ' ', 'g')
$$;

CREATE TABLE IF NOT EXISTS public.loja_bairros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id      uuid NOT NULL,
  nome          text NOT NULL CHECK (length(btrim(nome)) BETWEEN 2 AND 80),
  nome_chave    text GENERATED ALWAYS AS (public.normalizar_bairro(nome)) STORED,
  taxa_cents    bigint NOT NULL CHECK (taxa_cents >= 0),
  minutos_extra int NOT NULL DEFAULT 0 CHECK (minutos_extra BETWEEN 0 AND 180),
  ativo         boolean NOT NULL DEFAULT true,
  UNIQUE (store_id, nome_chave)
);

CREATE OR REPLACE FUNCTION public.loja_taxa_bairro(p_store uuid, p_bairro text) RETURNS public.loja_bairros
LANGUAGE sql STABLE AS $$
  SELECT * FROM public.loja_bairros
   WHERE store_id = p_store AND nome_chave = public.normalizar_bairro(p_bairro) AND ativo
$$;

-- Aberta no instante p_quando? Considera o turno de ontem que atravessa a meia-noite.
CREATE OR REPLACE FUNCTION public.loja_aberta(p_store uuid, p_quando timestamptz DEFAULT now()) RETURNS boolean
LANGUAGE sql STABLE AS $$
  WITH l AS (SELECT (p_quando AT TIME ZONE 'America/Sao_Paulo') AS t)
  SELECT EXISTS (
    SELECT 1 FROM public.loja_horarios h, l
     WHERE h.store_id = p_store AND (
           (h.dia_semana = extract(dow FROM l.t) AND h.abre < h.fecha AND l.t::time >= h.abre AND l.t::time < h.fecha)
        OR (h.dia_semana = extract(dow FROM l.t) AND h.abre > h.fecha AND l.t::time >= h.abre)
        OR (h.dia_semana = (extract(dow FROM l.t)::int + 6) % 7 AND h.abre > h.fecha AND l.t::time < h.fecha)))
$$;

-- Para a tela do link: aberta? pausada? quando abre de novo? ("Fechado agora: abre sexta às 18:00")
CREATE OR REPLACE FUNCTION public.loja_status_link(p_store uuid, p_quando timestamptz DEFAULT now()) RETURNS jsonb
LANGUAGE sql STABLE AS $$
  WITH l AS (SELECT (p_quando AT TIME ZONE 'America/Sao_Paulo') AS t),
  prox AS (
    SELECT min((l.t::date + k) + h.abre) AS abre_em
      FROM l, generate_series(0, 7) AS k, public.loja_horarios h
     WHERE h.store_id = p_store AND h.dia_semana = extract(dow FROM l.t::date + k) AND (l.t::date + k) + h.abre > l.t)
  SELECT jsonb_build_object(
    'aberta', public.loja_aberta(p_store, p_quando),
    'pausado', COALESCE((SELECT pausado FROM public.loja_config_pedido WHERE store_id = p_store), false),
    'pausado_motivo', (SELECT pausado_motivo FROM public.loja_config_pedido WHERE store_id = p_store),
    'tem_horario', EXISTS (SELECT 1 FROM public.loja_horarios WHERE store_id = p_store),
    'proxima_abertura', (SELECT to_char(abre_em, 'YYYY-MM-DD"T"HH24:MI') FROM prox))
$$;

-- Dia de negócio = dia do TURNO (decisão do dono, 11/11/2026): o pedido das 00:15 dentro do turno de sexta que
-- vai até 00:30 conta como sexta — no caixa, nos relatórios e no CRM. Fora de turno noturno, vale o calendário.
CREATE OR REPLACE FUNCTION public.loja_dia_negocio(p_store uuid, p_quando timestamptz DEFAULT now()) RETURNS date
LANGUAGE sql STABLE AS $$
  WITH l AS (SELECT (p_quando AT TIME ZONE 'America/Sao_Paulo') AS t)
  SELECT CASE WHEN EXISTS (SELECT 1 FROM public.loja_horarios h, l
                            WHERE h.store_id = p_store AND h.abre > h.fecha AND l.t::time < h.fecha
                              AND h.dia_semana = (extract(dow FROM l.t)::int + 6) % 7)
              THEN (SELECT t::date - 1 FROM l) ELSE (SELECT t::date FROM l) END
$$;

CREATE OR REPLACE FUNCTION public.pedido_validar_operacao(p_store uuid, p_pedido jsonb, p_subtotal bigint,
                                                          p_quando timestamptz DEFAULT now())
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  cfg public.loja_config_pedido; b public.loja_bairros; v_min bigint;
BEGIN
  SELECT * INTO cfg FROM public.loja_config_pedido WHERE store_id = p_store;
  IF p_pedido->>'canal' = 'link' THEN
    IF COALESCE(cfg.pausado, false) THEN
      RAISE EXCEPTION 'PEDIDOS_PAUSADOS: %', COALESCE(cfg.pausado_motivo, 'a loja pausou os pedidos online');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.loja_horarios WHERE store_id = p_store) THEN
      RAISE EXCEPTION 'LOJA_SEM_HORARIO';
    END IF;
    IF NOT public.loja_aberta(p_store, p_quando) THEN
      RAISE EXCEPTION 'LOJA_FECHADA: %', public.loja_status_link(p_store, p_quando)->>'proxima_abertura';
    END IF;
  END IF;
  IF p_pedido->>'tipo' <> 'entrega' THEN
    RETURN jsonb_build_object('taxa_entrega_cents', 0, 'bairro_id', NULL,
                              'tempo_estimado_min', COALESCE(cfg.tempo_preparo_min, 40));
  END IF;
  b := public.loja_taxa_bairro(p_store, p_pedido #>> '{endereco,bairro}');
  IF b.id IS NULL THEN RAISE EXCEPTION 'BAIRRO_NAO_ATENDIDO: %', COALESCE(p_pedido #>> '{endereco,bairro}', '(vazio)'); END IF;
  v_min := COALESCE(cfg.pedido_minimo_cents, 0);
  IF p_subtotal < v_min THEN RAISE EXCEPTION 'PEDIDO_MINIMO: faltam % centavos', v_min - p_subtotal; END IF;
  RETURN jsonb_build_object('taxa_entrega_cents', b.taxa_cents, 'bairro_id', b.id,
                            'tempo_estimado_min', COALESCE(cfg.tempo_preparo_min, 40) + b.minutos_extra);
END $$;
