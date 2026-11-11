-- =====================================================================================================
-- Pizzalia · Motor de oportunidades do CRM (PRD §10, §11.6) — núcleo independente da base remixada.
-- Idempotente (pode rodar de novo). Só aditivo: nenhum DROP de dado, nenhuma policy de DELETE.
-- Lê os pedidos por três "visões de contrato" que cada base implementa (ver 02_adaptador_*.sql):
--   crm_fatos_pedido(store_id, customer_id, order_id, business_date, total_cents)   -- só pedidos CONCLUÍDOS
--   crm_fatos_cliente(store_id, customer_id, nome, birth_date, consentimento)       -- 'granted' / outro / null
--   crm_fatos_em_andamento(store_id, customer_id)                                    -- pedido aberto agora
--   crm_fatos_sabor(store_id, order_id, sabor, fracao)                               -- sabores dos pedidos
--   crm_fatos_loja(store_id, nome, link_pedido)                                      -- para as mensagens
-- (crm_fatos_cliente também traz `telefone` em E.164.) Visões com security_invoker = true: respeitam a RLS.
-- Gabarito: demo/gabarito_oportunidades_2026-11-08.csv (o resultado precisa ser idêntico — db/crm/testar_motor.sh).
-- =====================================================================================================

-- ---------- parâmetros (uma linha por loja; sem linha = padrão do PRD) ----------
CREATE TABLE IF NOT EXISTS public.crm_regras (
  store_id   uuid PRIMARY KEY,
  params     jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.crm_param(p jsonb, chave text) RETURNS numeric
LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE((p->>chave)::numeric, (jsonb_build_object(
    'g1_min', 25, 'g1_max', 59, 'g2_intervalo_max', 21, 'g3_min', 10, 'g3_max', 59,
    'g4_min', 60, 'g4_max', 180, 'g5_janela', 3, 'cooldown_dias', 7, 'max_contatos_30d', 4,
    'descarte_dias', 14, 'vip_fracao', 0.10, 'vip_min_pedidos_180d', 5, 'expira_dias', 3,
    'atribuicao_dias', 7) ->> chave)::numeric)
$$;

-- ---------- regras puras (testadas na fronteira em 03_testes_fronteira.sql) ----------
CREATE OR REPLACE FUNCTION public.crm_gatilho(p_pedidos int, p_dias int, p_intervalo numeric, p jsonb DEFAULT '{}')
RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN p_intervalo IS NOT NULL AND p_intervalo <= public.crm_param(p, 'g2_intervalo_max')
         AND p_dias >= GREATEST(2 * p_intervalo, p_intervalo + 7) AND p_dias < public.crm_param(p, 'g4_min') THEN 'G2'
    WHEN p_pedidos >= 2 AND p_dias BETWEEN public.crm_param(p, 'g1_min') AND public.crm_param(p, 'g1_max') THEN 'G1'
    WHEN p_pedidos = 1  AND p_dias BETWEEN public.crm_param(p, 'g3_min') AND public.crm_param(p, 'g3_max') THEN 'G3'
    WHEN p_dias BETWEEN public.crm_param(p, 'g4_min') AND public.crm_param(p, 'g4_max') THEN 'G4'
  END
$$;

CREATE OR REPLACE FUNCTION public.crm_no_ano(p_nasc date, p_ano int) RETURNS date
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN extract(month FROM p_nasc) = 2 AND extract(day FROM p_nasc) = 29
         AND NOT (p_ano % 4 = 0 AND (p_ano % 100 <> 0 OR p_ano % 400 = 0)) THEN make_date(p_ano, 2, 28)
    ELSE make_date(p_ano, extract(month FROM p_nasc)::int, extract(day FROM p_nasc)::int)
  END
$$;

-- Dias até o próximo aniversário (0 = hoje), atravessando a virada do ano.
CREATE OR REPLACE FUNCTION public.crm_dias_ate_aniversario(p_nasc date, p_hoje date) RETURNS int
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN p_nasc IS NULL THEN NULL ELSE (
    CASE WHEN public.crm_no_ano(p_nasc, extract(year FROM p_hoje)::int) >= p_hoje
         THEN public.crm_no_ano(p_nasc, extract(year FROM p_hoje)::int)
         ELSE public.crm_no_ano(p_nasc, extract(year FROM p_hoje)::int + 1) END - p_hoje) END
$$;

-- ---------- métricas por cliente (materializadas; AD-04) ----------
CREATE TABLE IF NOT EXISTS public.crm_customer_stats (
  store_id              uuid    NOT NULL,
  customer_id           uuid    NOT NULL,
  pedidos_total         int     NOT NULL,
  primeiro_pedido_em    date    NOT NULL,
  ultimo_pedido_em      date    NOT NULL,
  dias_sem_pedir        int     NOT NULL,
  intervalo_habitual    numeric,               -- mediana dos intervalos dos últimos 12 meses (≥ 3 pedidos)
  total_gasto_cents     bigint  NOT NULL,
  gasto_180d_cents      bigint  NOT NULL,
  pedidos_90d           int     NOT NULL,
  pedidos_180d          int     NOT NULL,
  valor_medio_cents     bigint  NOT NULL,
  is_vip                boolean NOT NULL DEFAULT false,
  calculado_para        date    NOT NULL,
  computed_at           timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (store_id, customer_id)
);

ALTER TABLE public.crm_customer_stats ADD COLUMN IF NOT EXISTS sabores_favoritos text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.crm_customer_stats ADD COLUMN IF NOT EXISTS dia_preferido smallint
  CHECK (dia_preferido BETWEEN 0 AND 6);                     -- 0 = segunda … 6 = domingo; só com ≥ 4 pedidos e ≥ 50%

-- ---------- oportunidades e contatos ----------
CREATE TABLE IF NOT EXISTS public.crm_oportunidades (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id        uuid NOT NULL,
  customer_id     uuid NOT NULL,
  gatilho         text NOT NULL CHECK (gatilho IN ('G1','G2','G3','G4','G5','G6','G7')),
  elegivel        boolean NOT NULL,
  motivo_bloqueio text CHECK (motivo_bloqueio IN ('sem_consentimento','contato_recente','limite_30d',
                                                  'descartou','pedido_em_andamento')),
  status          text NOT NULL DEFAULT 'aberta' CHECK (status IN ('aberta','bloqueada','contatada','descartada',
                                                  'expirada','voltou_sozinho','convertida')),
  ordem           int  NOT NULL,                -- posição dentro do cartão (VIP primeiro, depois gasto 180 d)
  criada_para     date NOT NULL,
  expira_em       date NOT NULL,
  contexto        jsonb NOT NULL DEFAULT '{}'::jsonb,
  pedido_id       uuid,                         -- pedido que encerrou a oportunidade (convertida / voltou sozinho)
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, customer_id, criada_para)
);
CREATE INDEX IF NOT EXISTS crm_oportunidades_loja_dia ON public.crm_oportunidades (store_id, criada_para, gatilho, ordem);
CREATE INDEX IF NOT EXISTS crm_oportunidades_loja_status ON public.crm_oportunidades (store_id, status, customer_id);

-- Registro de contato: tabela de movimento (só inserção; "não enviei" marca desfeito_em, nunca apaga). RN-40, RN-43.
CREATE TABLE IF NOT EXISTS public.crm_contatos (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id       uuid NOT NULL,
  customer_id    uuid NOT NULL,
  oportunidade_id uuid REFERENCES public.crm_oportunidades(id),
  gatilho        text,
  modelo         text,                          -- chave do modelo usado; o texto da mensagem NÃO é guardado
  canal          text NOT NULL DEFAULT 'wa_me',
  enviado_por    uuid,
  enviado_em     timestamptz NOT NULL DEFAULT now(),
  desfeito_em    timestamptz
);
CREATE INDEX IF NOT EXISTS crm_contatos_loja_cliente ON public.crm_contatos (store_id, customer_id, enviado_em DESC);

-- ---------- o motor ----------
CREATE OR REPLACE FUNCTION public.crm_calcular(p_store uuid,
                                               p_hoje date DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')::date)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  p         jsonb := COALESCE((SELECT params FROM public.crm_regras WHERE store_id = p_store), '{}'::jsonb);
  v_stats   int;
  v_novas   int;
  v_fechadas int;
BEGIN
  -- 1) Encerrar oportunidades antigas: comprou depois de criada → voltou sozinho (sem contato) ou convertida
  --    (contato e pedido em até atribuicao_dias). Vencidas → expiradas. Nunca apaga.
  WITH compra AS (
    SELECT o.id, min(f.order_id::text)::uuid AS pedido,
           bool_or(c.id IS NOT NULL) AS teve_contato
    FROM public.crm_oportunidades o
    JOIN public.crm_fatos_pedido f ON f.store_id = o.store_id AND f.customer_id = o.customer_id
                                  AND f.business_date > o.criada_para AND f.business_date <= p_hoje
    LEFT JOIN public.crm_contatos c ON c.oportunidade_id = o.id AND c.desfeito_em IS NULL
         AND f.business_date - (c.enviado_em AT TIME ZONE 'America/Sao_Paulo')::date
             BETWEEN 0 AND public.crm_param(p, 'atribuicao_dias')
    WHERE o.store_id = p_store AND o.status IN ('aberta','contatada','bloqueada')
    GROUP BY o.id
  )
  UPDATE public.crm_oportunidades o
     SET status = CASE WHEN compra.teve_contato THEN 'convertida' ELSE 'voltou_sozinho' END,
         pedido_id = compra.pedido, updated_at = now()
    FROM compra WHERE o.id = compra.id;
  GET DIAGNOSTICS v_fechadas = ROW_COUNT;

  UPDATE public.crm_oportunidades
     SET status = 'expirada', updated_at = now()
   WHERE store_id = p_store AND status IN ('aberta','bloqueada') AND expira_em < p_hoje;

  -- 2) Métricas por cliente (só pedidos concluídos até a data de negócio).
  WITH ped AS (
    SELECT customer_id, business_date AS d, total_cents
    FROM public.crm_fatos_pedido WHERE store_id = p_store AND business_date <= p_hoje AND customer_id IS NOT NULL
  ), gaps AS (
    SELECT customer_id, d - lag(d) OVER (PARTITION BY customer_id ORDER BY d) AS gap
    FROM ped WHERE p_hoje - d <= 365
  ), iv AS (
    SELECT customer_id, percentile_cont(0.5) WITHIN GROUP (ORDER BY gap) AS mediana, count(*) + 1 AS n12
    FROM gaps WHERE gap IS NOT NULL GROUP BY customer_id
  ), agg AS (
    SELECT customer_id, count(*)::int AS n, min(d) AS primeiro, max(d) AS ultimo,
           sum(total_cents)::bigint AS total,
           COALESCE(sum(total_cents) FILTER (WHERE p_hoje - d <= 180), 0)::bigint AS g180,
           count(*) FILTER (WHERE p_hoje - d <= 90)::int AS n90,
           count(*) FILTER (WHERE p_hoje - d <= 180)::int AS n180
    FROM ped GROUP BY customer_id
  ), corte AS (
    SELECT COALESCE(max(g180) FILTER (WHERE rn = GREATEST(1, floor(cnt * public.crm_param(p, 'vip_fracao'))::int)), 0) AS v
    FROM (SELECT g180, row_number() OVER (ORDER BY g180 DESC) AS rn, count(*) OVER () AS cnt FROM agg) x
  )
  INSERT INTO public.crm_customer_stats AS s (store_id, customer_id, pedidos_total, primeiro_pedido_em,
      ultimo_pedido_em, dias_sem_pedir, intervalo_habitual, total_gasto_cents, gasto_180d_cents, pedidos_90d,
      pedidos_180d, valor_medio_cents, is_vip, calculado_para, computed_at)
  SELECT p_store, a.customer_id, a.n, a.primeiro, a.ultimo, p_hoje - a.ultimo,
         CASE WHEN iv.n12 >= 3 THEN iv.mediana::numeric END,
         a.total, a.g180, a.n90, a.n180, a.total / a.n,
         (a.g180 >= corte.v AND a.n180 >= public.crm_param(p, 'vip_min_pedidos_180d')), p_hoje, now()
  FROM agg a CROSS JOIN corte LEFT JOIN iv ON iv.customer_id = a.customer_id
  ON CONFLICT (store_id, customer_id) DO UPDATE SET
      pedidos_total = EXCLUDED.pedidos_total, primeiro_pedido_em = EXCLUDED.primeiro_pedido_em,
      ultimo_pedido_em = EXCLUDED.ultimo_pedido_em, dias_sem_pedir = EXCLUDED.dias_sem_pedir,
      intervalo_habitual = EXCLUDED.intervalo_habitual, total_gasto_cents = EXCLUDED.total_gasto_cents,
      gasto_180d_cents = EXCLUDED.gasto_180d_cents, pedidos_90d = EXCLUDED.pedidos_90d,
      pedidos_180d = EXCLUDED.pedidos_180d, valor_medio_cents = EXCLUDED.valor_medio_cents,
      is_vip = EXCLUDED.is_vip, calculado_para = EXCLUDED.calculado_para, computed_at = EXCLUDED.computed_at;
  GET DIAGNOSTICS v_stats = ROW_COUNT;

  -- 2b) Preferências: 2 sabores mais pedidos nos últimos 12 meses (meio a meio = 0,5; empate em ordem alfabética),
  --     cada um presente em ≥ 2 pedidos; dia da semana com ≥ 50% dos pedidos (≥ 4 pedidos; empate: segunda primeiro).
  WITH fs AS (
    SELECT f.customer_id, s.sabor, round(sum(s.fracao), 4) AS pontos, count(DISTINCT s.order_id) AS n_ped
    FROM public.crm_fatos_sabor s
    JOIN public.crm_fatos_pedido f ON f.store_id = s.store_id AND f.order_id = s.order_id
    WHERE s.store_id = p_store AND f.business_date <= p_hoje AND p_hoje - f.business_date <= 365
    GROUP BY f.customer_id, s.sabor
  ), rk AS (
    SELECT fs.*, row_number() OVER (PARTITION BY customer_id ORDER BY pontos DESC, sabor COLLATE "C") AS rn FROM fs
  ), fav AS (
    SELECT customer_id, COALESCE(array_agg(sabor ORDER BY rn) FILTER (WHERE n_ped >= 2), '{}') AS favs
    FROM rk WHERE rn <= 2 GROUP BY customer_id
  ), wd AS (
    SELECT customer_id, extract(isodow FROM business_date)::int - 1 AS dia, count(*) AS c,
           sum(count(*)) OVER (PARTITION BY customer_id) AS tot
    FROM public.crm_fatos_pedido WHERE store_id = p_store AND business_date <= p_hoje GROUP BY 1, 2
  ), wd1 AS (
    SELECT DISTINCT ON (customer_id) customer_id, dia, c, tot FROM wd ORDER BY customer_id, c DESC, dia
  )
  UPDATE public.crm_customer_stats st
     SET sabores_favoritos = COALESCE(x.favs, '{}'),
         dia_preferido = CASE WHEN x.tot >= 4 AND x.c::numeric / x.tot >= 0.5 THEN x.dia END
    FROM (SELECT s2.customer_id, fav.favs, wd1.dia, wd1.c, wd1.tot FROM public.crm_customer_stats s2
            LEFT JOIN fav ON fav.customer_id = s2.customer_id LEFT JOIN wd1 ON wd1.customer_id = s2.customer_id
           WHERE s2.store_id = p_store) x
   WHERE st.store_id = p_store AND st.customer_id = x.customer_id;

  -- 3) Oportunidades do dia: um cartão por cliente; quem já tem oportunidade viva de outro dia não entra.
  WITH base AS (
    SELECT s.customer_id, s.is_vip, s.gasto_180d_cents, s.dias_sem_pedir, s.intervalo_habitual,
           COALESCE(public.crm_gatilho(s.pedidos_total, s.dias_sem_pedir, s.intervalo_habitual, p),
                    CASE WHEN public.crm_dias_ate_aniversario(fc.birth_date, p_hoje) <= public.crm_param(p, 'g5_janela')
                         THEN 'G5' END) AS gatilho,
           fc.consentimento
    FROM public.crm_customer_stats s
    LEFT JOIN public.crm_fatos_cliente fc ON fc.store_id = s.store_id AND fc.customer_id = s.customer_id
    WHERE s.store_id = p_store
      AND NOT EXISTS (SELECT 1 FROM public.crm_oportunidades o WHERE o.store_id = p_store
                        AND o.customer_id = s.customer_id AND o.criada_para < p_hoje
                        AND o.status IN ('aberta','contatada') AND o.expira_em >= p_hoje)
  ), cont AS (
    SELECT customer_id,
           max((enviado_em AT TIME ZONE 'America/Sao_Paulo')::date) AS ultimo_contato,
           count(*) FILTER (WHERE p_hoje - (enviado_em AT TIME ZONE 'America/Sao_Paulo')::date < 30) AS n30
    FROM public.crm_contatos WHERE store_id = p_store AND desfeito_em IS NULL GROUP BY customer_id
  ), avaliada AS (
    SELECT b.*, CASE
        WHEN b.consentimento IS DISTINCT FROM 'granted' THEN 'sem_consentimento'
        WHEN EXISTS (SELECT 1 FROM public.crm_fatos_em_andamento e WHERE e.store_id = p_store
                       AND e.customer_id = b.customer_id) THEN 'pedido_em_andamento'
        WHEN p_hoje - c.ultimo_contato < public.crm_param(p, 'cooldown_dias') THEN 'contato_recente'
        WHEN c.n30 >= public.crm_param(p, 'max_contatos_30d') THEN 'limite_30d'
        WHEN EXISTS (SELECT 1 FROM public.crm_oportunidades o WHERE o.store_id = p_store
                       AND o.customer_id = b.customer_id AND o.gatilho = b.gatilho AND o.status = 'descartada'
                       AND p_hoje - o.criada_para < public.crm_param(p, 'descarte_dias')) THEN 'descartou'
      END AS motivo
    FROM base b LEFT JOIN cont c ON c.customer_id = b.customer_id
    WHERE b.gatilho IS NOT NULL
  )
  INSERT INTO public.crm_oportunidades AS o (store_id, customer_id, gatilho, elegivel, motivo_bloqueio, status,
                                             ordem, criada_para, expira_em, contexto)
  SELECT p_store, a.customer_id, a.gatilho, a.motivo IS NULL, a.motivo,
         CASE WHEN a.motivo IS NULL THEN 'aberta' ELSE 'bloqueada' END,
         row_number() OVER (PARTITION BY a.gatilho, (a.motivo IS NULL)
                            ORDER BY a.is_vip DESC, a.gasto_180d_cents DESC, a.customer_id),
         p_hoje, p_hoje + public.crm_param(p, 'expira_dias')::int,
         jsonb_build_object('dias_sem_pedir', a.dias_sem_pedir, 'intervalo_habitual', a.intervalo_habitual,
                            'vip', a.is_vip)
  FROM avaliada a
  ON CONFLICT (store_id, customer_id, criada_para) DO UPDATE SET
      gatilho = EXCLUDED.gatilho, elegivel = EXCLUDED.elegivel, motivo_bloqueio = EXCLUDED.motivo_bloqueio,
      status = EXCLUDED.status, ordem = EXCLUDED.ordem, contexto = EXCLUDED.contexto, updated_at = now()
    WHERE o.status IN ('aberta','bloqueada');     -- recalcular no mesmo dia não desfaz contato nem descarte
  GET DIAGNOSTICS v_novas = ROW_COUNT;

  RETURN jsonb_build_object('loja', p_store, 'dia', p_hoje, 'clientes', v_stats,
                            'oportunidades', v_novas, 'encerradas_por_compra', v_fechadas);
END $$;

-- Só o servidor (cron / service role) executa o motor e mexe nas regras.
DO $$ BEGIN
  REVOKE ALL ON FUNCTION public.crm_calcular(uuid, date) FROM PUBLIC;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON FUNCTION public.crm_calcular(uuid, date) FROM anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    GRANT EXECUTE ON FUNCTION public.crm_calcular(uuid, date) TO service_role;
  END IF;
END $$;
