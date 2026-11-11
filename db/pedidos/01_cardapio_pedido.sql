-- =====================================================================================================
-- Fornalia · Cardápio de pizzaria e criação de pedido (PRD M02, M03, M04; RN-01 a RN-07, RN-30 a RN-33, §9).
-- Independente da base remixada: só usa store_id (a loja). Prefixos próprios (cardapio_*, pedido*) para não
-- colidir com products / loja_pedidos / sales do MayFlower. Idempotente, só aditivo. Dinheiro em centavos.
-- Entrega, horário, pausa e pedido mínimo: 02_entrega_horario.sql (substitui pedido_validar_operacao).
-- =====================================================================================================

-- ---------- configuração da loja para pedidos ----------
CREATE TABLE IF NOT EXISTS public.loja_config_pedido (
  store_id            uuid PRIMARY KEY,
  regra_preco_pizza   text NOT NULL DEFAULT 'maior' CHECK (regra_preco_pizza IN ('maior','media')),  -- RN-03
  pedido_minimo_cents bigint NOT NULL DEFAULT 0 CHECK (pedido_minimo_cents >= 0),
  tempo_preparo_min   int    NOT NULL DEFAULT 40 CHECK (tempo_preparo_min BETWEEN 5 AND 240),
  pausado             boolean NOT NULL DEFAULT false,
  pausado_motivo      text,
  updated_at          timestamptz NOT NULL DEFAULT now()
);

-- ---------- cardápio ----------
CREATE TABLE IF NOT EXISTS public.cardapio_categorias (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  nome text NOT NULL CHECK (length(btrim(nome)) BETWEEN 1 AND 60), ordem int NOT NULL DEFAULT 0,
  ativo boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.cardapio_tamanhos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  nome text NOT NULL CHECK (length(btrim(nome)) BETWEEN 1 AND 40),
  fatias int CHECK (fatias BETWEEN 1 AND 32),
  max_sabores int NOT NULL DEFAULT 1 CHECK (max_sabores BETWEEN 1 AND 4),
  ordem int NOT NULL DEFAULT 0, ativo boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS public.cardapio_sabores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  categoria_id uuid REFERENCES public.cardapio_categorias(id),
  nome text NOT NULL CHECK (length(btrim(nome)) BETWEEN 1 AND 80), descricao text, foto_url text,
  ativo boolean NOT NULL DEFAULT true, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.cardapio_sabor_precos (                 -- sabor sem preço no tamanho = não oferecido
  sabor_id uuid NOT NULL REFERENCES public.cardapio_sabores(id),
  tamanho_id uuid NOT NULL REFERENCES public.cardapio_tamanhos(id),
  preco_cents bigint NOT NULL CHECK (preco_cents > 0),
  PRIMARY KEY (sabor_id, tamanho_id)
);
CREATE TABLE IF NOT EXISTS public.cardapio_grupos_adicionais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  nome text NOT NULL, min_escolhas int NOT NULL DEFAULT 0 CHECK (min_escolhas >= 0),
  max_escolhas int NOT NULL DEFAULT 1 CHECK (max_escolhas >= 1), CHECK (max_escolhas >= min_escolhas),
  obrigatorio_em_pizza boolean NOT NULL DEFAULT false, ativo boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS public.cardapio_adicionais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  grupo_id uuid NOT NULL REFERENCES public.cardapio_grupos_adicionais(id),
  nome text NOT NULL, preco_cents bigint NOT NULL CHECK (preco_cents >= 0), ativo boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS public.cardapio_adicional_precos (             -- opcional: preço do adicional por tamanho
  adicional_id uuid NOT NULL REFERENCES public.cardapio_adicionais(id),
  tamanho_id uuid NOT NULL REFERENCES public.cardapio_tamanhos(id),
  preco_cents bigint NOT NULL CHECK (preco_cents >= 0), PRIMARY KEY (adicional_id, tamanho_id)
);
CREATE TABLE IF NOT EXISTS public.cardapio_itens (                        -- bebidas, porções, sobremesas
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), store_id uuid NOT NULL,
  categoria_id uuid REFERENCES public.cardapio_categorias(id),
  nome text NOT NULL, preco_cents bigint NOT NULL CHECK (preco_cents > 0), ativo boolean NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS cardapio_sabores_loja ON public.cardapio_sabores (store_id, ativo);
CREATE INDEX IF NOT EXISTS cardapio_itens_loja ON public.cardapio_itens (store_id, ativo);

-- ---------- pedidos ----------
CREATE TABLE IF NOT EXISTS public.loja_contadores (                       -- número do pedido por loja (RN-06)
  store_id uuid PRIMARY KEY, ultimo_pedido bigint NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS public.pedidos (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id           uuid   NOT NULL,
  numero             bigint NOT NULL,
  data_negocio       date   NOT NULL DEFAULT (now() AT TIME ZONE 'America/Sao_Paulo')::date,   -- RN-02
  canal              text   NOT NULL CHECK (canal IN ('link','balcao','telefone','marketplace')),
  tipo               text   NOT NULL CHECK (tipo IN ('entrega','retirada','local')),
  status             text   NOT NULL CHECK (status IN ('novo','em_preparo','pronto','saiu_entrega',
                                                         'aguardando_retirada','concluido','cancelado')),
  customer_id        uuid,                                                   -- ligado ao cadastro da base
  cliente_nome       text,
  cliente_telefone   text CHECK (cliente_telefone IS NULL OR cliente_telefone ~ '^\+55[1-9][0-9]{9,10}$'),
  endereco           jsonb,                                                  -- cópia do endereço no momento
  bairro_id          uuid,
  subtotal_cents     bigint NOT NULL CHECK (subtotal_cents >= 0),
  taxa_entrega_cents bigint NOT NULL DEFAULT 0 CHECK (taxa_entrega_cents >= 0),
  desconto_cents     bigint NOT NULL DEFAULT 0 CHECK (desconto_cents >= 0),
  total_cents        bigint NOT NULL CHECK (total_cents = subtotal_cents + taxa_entrega_cents - desconto_cents),
  forma_pagamento    text   NOT NULL CHECK (forma_pagamento IN ('dinheiro','pix','debito','credito','vale','pix_online')),
  troco_para_cents   bigint CHECK (troco_para_cents IS NULL OR troco_para_cents >= 0),
  observacao         text CHECK (observacao IS NULL OR length(observacao) <= 500),
  idempotency_key    text   NOT NULL CHECK (length(idempotency_key) BETWEEN 8 AND 100),
  token_publico      text   NOT NULL DEFAULT replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),  -- 64 hex, sem extensão
  cancelamento_motivo text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (store_id, numero), UNIQUE (store_id, idempotency_key), UNIQUE (token_publico),
  CHECK (status <> 'cancelado' OR length(btrim(coalesce(cancelamento_motivo, ''))) >= 3)
);
CREATE INDEX IF NOT EXISTS pedidos_loja_dia ON public.pedidos (store_id, data_negocio, status);
CREATE INDEX IF NOT EXISTS pedidos_loja_cliente ON public.pedidos (store_id, cliente_telefone, data_negocio);

CREATE TABLE IF NOT EXISTS public.pedido_itens (                          -- cópia de nome e preço (RN-07)
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
  tipo text NOT NULL CHECK (tipo IN ('pizza','produto')),
  tamanho_id uuid, item_id uuid,
  nome text NOT NULL, tamanho_nome text,
  preco_unitario_cents bigint NOT NULL CHECK (preco_unitario_cents > 0),
  quantidade int NOT NULL CHECK (quantidade BETWEEN 1 AND 50),
  observacao text CHECK (observacao IS NULL OR length(observacao) <= 200)
);
CREATE TABLE IF NOT EXISTS public.pedido_item_sabores (
  pedido_item_id uuid NOT NULL REFERENCES public.pedido_itens(id), sabor_id uuid NOT NULL,
  nome text NOT NULL, fracao numeric(4,3) NOT NULL CHECK (fracao > 0 AND fracao <= 1)
);
CREATE TABLE IF NOT EXISTS public.pedido_item_adicionais (
  pedido_item_id uuid NOT NULL REFERENCES public.pedido_itens(id), adicional_id uuid NOT NULL,
  nome text NOT NULL, preco_cents bigint NOT NULL CHECK (preco_cents >= 0)
);
CREATE TABLE IF NOT EXISTS public.pedido_status_historico (               -- só inserção
  id bigserial PRIMARY KEY, pedido_id uuid NOT NULL REFERENCES public.pedidos(id),
  de text, para text NOT NULL, motivo text, por uuid, em timestamptz NOT NULL DEFAULT now()
);

-- ---------- telefone (RN-13) ----------
-- Celular ou fixo brasileiro → E.164 (+55DDDNÚMERO). Inválido → NULL. Sem DDD não é aceito.
CREATE OR REPLACE FUNCTION public.fone_e164_br(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  WITH d AS (SELECT regexp_replace(coalesce(p, ''), '\D', '', 'g') AS n),
       s AS (SELECT CASE WHEN length(n) IN (12, 13) AND left(n, 2) = '55' THEN substr(n, 3)
                         WHEN length(n) IN (11, 12) AND left(n, 1) = '0' THEN substr(n, 2)   -- 0 + DDD
                         ELSE n END AS n FROM d)
  SELECT CASE
    WHEN n ~ '^[1-9][1-9]9[0-9]{8}$' THEN '+55' || n           -- celular: DDD + 9 + 8 dígitos
    WHEN n ~ '^[1-9][1-9][2-5][0-9]{7}$' THEN '+55' || n        -- fixo: DDD + 8 dígitos (2 a 5)
  END FROM s
$$;

-- ---------- preço de um item (RN-03; o navegador nunca dita preço — RN-04) ----------
CREATE OR REPLACE FUNCTION public.cardapio_preco_item(p_store uuid, p_item jsonb) RETURNS jsonb
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_regra text := COALESCE((SELECT regra_preco_pizza FROM public.loja_config_pedido WHERE store_id = p_store), 'maior');
  v_qtd int := COALESCE((p_item->>'quantidade')::int, 1);
  v_tam record; v_n int; v_precos bigint[]; v_base bigint; v_adic bigint := 0; v_sabores jsonb; v_adicionais jsonb;
  v_item record; g record;
BEGIN
  IF v_qtd NOT BETWEEN 1 AND 50 THEN RAISE EXCEPTION 'QUANTIDADE_INVALIDA: %', v_qtd; END IF;
  IF p_item->>'tipo' = 'produto' THEN
    SELECT id, nome, preco_cents INTO v_item FROM public.cardapio_itens
     WHERE id = (p_item->>'item_id')::uuid AND store_id = p_store AND ativo;
    IF NOT FOUND THEN RAISE EXCEPTION 'ITEM_INDISPONIVEL: %', p_item->>'item_id'; END IF;
    RETURN jsonb_build_object('tipo','produto','item_id',v_item.id,'nome',v_item.nome,
                              'preco_unitario_cents',v_item.preco_cents,'quantidade',v_qtd);
  ELSIF p_item->>'tipo' IS DISTINCT FROM 'pizza' THEN
    RAISE EXCEPTION 'TIPO_DE_ITEM_INVALIDO: %', p_item->>'tipo';
  END IF;

  SELECT id, nome, max_sabores INTO v_tam FROM public.cardapio_tamanhos
   WHERE id = (p_item->>'tamanho_id')::uuid AND store_id = p_store AND ativo;
  IF NOT FOUND THEN RAISE EXCEPTION 'TAMANHO_INDISPONIVEL: %', p_item->>'tamanho_id'; END IF;
  v_n := jsonb_array_length(COALESCE(p_item->'sabores', '[]'));
  IF v_n < 1 OR v_n > v_tam.max_sabores THEN
    RAISE EXCEPTION 'QUANTIDADE_DE_SABORES: % sabor(es) para o tamanho % (máximo %)', v_n, v_tam.nome, v_tam.max_sabores;
  END IF;
  IF (SELECT count(DISTINCT x) FROM jsonb_array_elements_text(p_item->'sabores') x) <> v_n THEN
    RAISE EXCEPTION 'SABOR_REPETIDO';
  END IF;
  SELECT array_agg(sp.preco_cents), jsonb_agg(jsonb_build_object('sabor_id', s.id, 'nome', s.nome,
                                                                  'fracao', round(1.0 / v_n, 3)) ORDER BY s.nome)
    INTO v_precos, v_sabores
    FROM jsonb_array_elements_text(p_item->'sabores') x
    JOIN public.cardapio_sabores s ON s.id = x::uuid AND s.store_id = p_store AND s.ativo
    JOIN public.cardapio_sabor_precos sp ON sp.sabor_id = s.id AND sp.tamanho_id = v_tam.id;
  IF COALESCE(array_length(v_precos, 1), 0) <> v_n THEN
    RAISE EXCEPTION 'SABOR_INDISPONIVEL_NO_TAMANHO: algum sabor está inativo ou não existe no tamanho %', v_tam.nome;
  END IF;
  v_base := CASE v_regra WHEN 'media' THEN (SELECT ceil(sum(x)::numeric / v_n)::bigint FROM unnest(v_precos) x)  -- média, ↑ ao centavo
                         ELSE (SELECT max(x) FROM unnest(v_precos) x) END;

  -- adicionais: ativos, da loja, sem repetição, respeitando mínimo/máximo por grupo
  IF (SELECT count(DISTINCT x) FROM jsonb_array_elements_text(COALESCE(p_item->'adicionais','[]')) x)
     <> jsonb_array_length(COALESCE(p_item->'adicionais','[]')) THEN RAISE EXCEPTION 'ADICIONAL_REPETIDO'; END IF;
  SELECT COALESCE(sum(COALESCE(ap.preco_cents, a.preco_cents)), 0),
         COALESCE(jsonb_agg(jsonb_build_object('adicional_id', a.id, 'nome', a.nome,
                                               'preco_cents', COALESCE(ap.preco_cents, a.preco_cents)) ORDER BY a.nome), '[]'),
         count(*)
    INTO v_adic, v_adicionais, v_n
    FROM jsonb_array_elements_text(COALESCE(p_item->'adicionais','[]')) x
    JOIN public.cardapio_adicionais a ON a.id = x::uuid AND a.store_id = p_store AND a.ativo
    JOIN public.cardapio_grupos_adicionais ga ON ga.id = a.grupo_id AND ga.ativo
    LEFT JOIN public.cardapio_adicional_precos ap ON ap.adicional_id = a.id AND ap.tamanho_id = v_tam.id;
  IF v_n <> jsonb_array_length(COALESCE(p_item->'adicionais','[]')) THEN RAISE EXCEPTION 'ADICIONAL_INDISPONIVEL'; END IF;
  FOR g IN SELECT ga.nome, ga.min_escolhas, ga.max_escolhas, ga.obrigatorio_em_pizza,
                  count(x.x) AS escolhidos
             FROM public.cardapio_grupos_adicionais ga
             LEFT JOIN public.cardapio_adicionais a ON a.grupo_id = ga.id
             LEFT JOIN jsonb_array_elements_text(COALESCE(p_item->'adicionais','[]')) x(x) ON x.x::uuid = a.id
            WHERE ga.store_id = p_store AND ga.ativo GROUP BY ga.id LOOP
    IF g.escolhidos > g.max_escolhas
       OR (g.obrigatorio_em_pizza AND g.escolhidos < GREATEST(g.min_escolhas, 1))
       OR (g.escolhidos > 0 AND g.escolhidos < g.min_escolhas) THEN
      RAISE EXCEPTION 'ESCOLHAS_DO_GRUPO: % (escolhidos %, mínimo %, máximo %)', g.nome, g.escolhidos, g.min_escolhas, g.max_escolhas;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('tipo','pizza','tamanho_id',v_tam.id,'tamanho_nome',v_tam.nome,
                            'nome','Pizza ' || v_tam.nome,'preco_unitario_cents', v_base + v_adic,
                            'quantidade', v_qtd, 'sabores', v_sabores, 'adicionais', v_adicionais);
END $$;

-- ---------- dia de negócio (substituída por 02_entrega_horario.sql: o dia do TURNO) ----------
CREATE OR REPLACE FUNCTION public.loja_dia_negocio(p_store uuid, p_quando timestamptz DEFAULT now()) RETURNS date
LANGUAGE sql STABLE AS $$ SELECT (p_quando AT TIME ZONE 'America/Sao_Paulo')::date $$;

-- ---------- regras de operação (substituída por 02_entrega_horario.sql) ----------
-- Devolve a taxa de entrega e o bairro; levanta erro se a operação não aceita o pedido.
CREATE OR REPLACE FUNCTION public.pedido_validar_operacao(p_store uuid, p_pedido jsonb, p_subtotal bigint,
                                                          p_quando timestamptz DEFAULT now())
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
BEGIN
  IF p_pedido->>'tipo' = 'entrega' THEN RAISE EXCEPTION 'ENTREGA_NAO_CONFIGURADA'; END IF;
  RETURN jsonb_build_object('taxa_entrega_cents', 0, 'bairro_id', NULL);
END $$;

-- ---------- criar pedido (RN-04 recálculo, RN-05 idempotência, RN-06 número, RN-07 cópia) ----------
-- Chamado pela Edge Function do link (com limite de requisições) e pelo PDV. Nunca pelo navegador direto (AD-02).
CREATE OR REPLACE FUNCTION public.pedido_criar(p_store uuid, p_pedido jsonb, p_idempotency_key text,
                                               p_quando timestamptz DEFAULT now())
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_exist record; v_itens jsonb := '[]'; v_it jsonb; v_calc jsonb; v_sub bigint := 0; v_op jsonb;
  v_total bigint; v_num bigint; v_id uuid; v_fone text; v_canal text := p_pedido->>'canal';
  v_status text; v_item_id uuid; s jsonb; a jsonb;
BEGIN
  -- mesma chave → mesmo pedido, sem gastar número (trava por chave antes de olhar)
  PERFORM pg_advisory_xact_lock(hashtextextended(p_store::text || '/' || coalesce(p_idempotency_key, ''), 0));
  SELECT id, numero, total_cents, token_publico INTO v_exist FROM public.pedidos
   WHERE store_id = p_store AND idempotency_key = p_idempotency_key;
  IF FOUND THEN
    RETURN jsonb_build_object('pedido_id', v_exist.id, 'numero', v_exist.numero, 'total_cents', v_exist.total_cents,
                              'token_publico', v_exist.token_publico, 'repetido', true);
  END IF;

  IF jsonb_array_length(COALESCE(p_pedido->'itens', '[]')) = 0 THEN RAISE EXCEPTION 'PEDIDO_SEM_ITENS'; END IF;
  FOR v_it IN SELECT * FROM jsonb_array_elements(p_pedido->'itens') LOOP
    v_calc := public.cardapio_preco_item(p_store, v_it) || jsonb_build_object('observacao', v_it->>'observacao');
    v_sub := v_sub + (v_calc->>'preco_unitario_cents')::bigint * (v_calc->>'quantidade')::int;
    v_itens := v_itens || jsonb_build_array(v_calc);
  END LOOP;

  v_op := public.pedido_validar_operacao(p_store, p_pedido, v_sub, p_quando);
  v_total := v_sub + (v_op->>'taxa_entrega_cents')::bigint;
  IF p_pedido ? 'total_esperado_cents' AND (p_pedido->>'total_esperado_cents')::bigint <> v_total THEN
    RAISE EXCEPTION 'PRECO_MUDOU' USING DETAIL = jsonb_build_object('total_cents', v_total, 'itens', v_itens)::text;
  END IF;
  IF p_pedido->>'forma_pagamento' = 'dinheiro' AND (p_pedido->>'troco_para_cents')::bigint < v_total THEN
    RAISE EXCEPTION 'TROCO_MENOR_QUE_TOTAL';
  END IF;
  v_fone := public.fone_e164_br(p_pedido #>> '{cliente,telefone}');
  IF v_canal = 'link' AND v_fone IS NULL THEN RAISE EXCEPTION 'TELEFONE_INVALIDO'; END IF;
  v_status := CASE WHEN v_canal = 'link' THEN 'novo' ELSE 'em_preparo' END;   -- balcão/telefone não precisa aceite

  INSERT INTO public.loja_contadores (store_id, ultimo_pedido) VALUES (p_store, 1)
  ON CONFLICT (store_id) DO UPDATE SET ultimo_pedido = public.loja_contadores.ultimo_pedido + 1
  RETURNING ultimo_pedido INTO v_num;

  INSERT INTO public.pedidos (store_id, numero, data_negocio, canal, tipo, status, cliente_nome, cliente_telefone,
         endereco, bairro_id, subtotal_cents, taxa_entrega_cents, total_cents, forma_pagamento, troco_para_cents,
         observacao, idempotency_key)
  VALUES (p_store, v_num, public.loja_dia_negocio(p_store, p_quando), v_canal, p_pedido->>'tipo', v_status,
          NULLIF(btrim(p_pedido #>> '{cliente,nome}'), ''), v_fone, p_pedido->'endereco',
          (v_op->>'bairro_id')::uuid, v_sub, (v_op->>'taxa_entrega_cents')::bigint, v_total,
          p_pedido->>'forma_pagamento', (p_pedido->>'troco_para_cents')::bigint, p_pedido->>'observacao',
          p_idempotency_key)
  RETURNING id INTO v_id;
  INSERT INTO public.pedido_status_historico (pedido_id, de, para, por) VALUES (v_id, NULL, v_status, auth_uid_ou_nulo());

  FOR v_calc IN SELECT * FROM jsonb_array_elements(v_itens) LOOP
    INSERT INTO public.pedido_itens (pedido_id, tipo, tamanho_id, item_id, nome, tamanho_nome, preco_unitario_cents,
                                     quantidade, observacao)
    VALUES (v_id, v_calc->>'tipo', (v_calc->>'tamanho_id')::uuid, (v_calc->>'item_id')::uuid, v_calc->>'nome',
            v_calc->>'tamanho_nome', (v_calc->>'preco_unitario_cents')::bigint, (v_calc->>'quantidade')::int,
            v_calc->>'observacao')
    RETURNING id INTO v_item_id;
    FOR s IN SELECT * FROM jsonb_array_elements(COALESCE(v_calc->'sabores', '[]')) LOOP
      INSERT INTO public.pedido_item_sabores VALUES (v_item_id, (s->>'sabor_id')::uuid, s->>'nome', (s->>'fracao')::numeric);
    END LOOP;
    FOR a IN SELECT * FROM jsonb_array_elements(COALESCE(v_calc->'adicionais', '[]')) LOOP
      INSERT INTO public.pedido_item_adicionais VALUES (v_item_id, (a->>'adicional_id')::uuid, a->>'nome', (a->>'preco_cents')::bigint);
    END LOOP;
  END LOOP;

  RETURN (SELECT jsonb_build_object('pedido_id', id, 'numero', numero, 'total_cents', total_cents,
                                    'token_publico', token_publico, 'repetido', false)
            FROM public.pedidos WHERE id = v_id);
END $$;

-- auth.uid() quando existe (Supabase); NULL no banco de teste.
CREATE OR REPLACE FUNCTION public.auth_uid_ou_nulo() RETURNS uuid LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN COALESCE(nullif(current_setting('request.jwt.claim.sub', true), ''),
                  nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid;
END $$;

-- ---------- máquina de estados (§9): o banco recusa transição inválida ----------
CREATE OR REPLACE FUNCTION public.pedido_guardar_status() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE ok boolean;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    IF OLD.status IN ('concluido','cancelado') AND (NEW.total_cents, NEW.subtotal_cents, NEW.forma_pagamento)
       IS DISTINCT FROM (OLD.total_cents, OLD.subtotal_cents, OLD.forma_pagamento) THEN
      RAISE EXCEPTION 'PEDIDO_ENCERRADO: valores de pedido % não mudam (RN-32)', OLD.status;
    END IF;
    RETURN NEW;
  END IF;
  ok := (OLD.status, NEW.status) IN (
    ('novo','em_preparo'), ('em_preparo','pronto'),
    ('pronto','saiu_entrega'), ('pronto','aguardando_retirada'),
    ('saiu_entrega','concluido'), ('aguardando_retirada','concluido'),
    ('novo','cancelado'), ('em_preparo','cancelado'), ('pronto','cancelado'),
    ('saiu_entrega','cancelado'), ('aguardando_retirada','cancelado'));
  IF NOT ok THEN RAISE EXCEPTION 'TRANSICAO_INVALIDA: % → %', OLD.status, NEW.status; END IF;
  IF NEW.status = 'saiu_entrega' AND NEW.tipo <> 'entrega' THEN RAISE EXCEPTION 'TRANSICAO_INVALIDA: só pedido de entrega sai para entrega'; END IF;
  IF NEW.status = 'aguardando_retirada' AND NEW.tipo = 'entrega' THEN RAISE EXCEPTION 'TRANSICAO_INVALIDA: pedido de entrega não aguarda retirada'; END IF;
  NEW.updated_at := now();
  INSERT INTO public.pedido_status_historico (pedido_id, de, para, motivo, por)
  VALUES (NEW.id, OLD.status, NEW.status, NEW.cancelamento_motivo, public.auth_uid_ou_nulo());
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS pedido_guardar_status ON public.pedidos;
CREATE TRIGGER pedido_guardar_status BEFORE UPDATE ON public.pedidos
  FOR EACH ROW EXECUTE FUNCTION public.pedido_guardar_status();

-- Histórico e itens não se apagam nem se reescrevem (tabelas de movimento).
CREATE OR REPLACE FUNCTION public.pedido_somente_insercao() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'SOMENTE_INSERCAO: % não aceita %', TG_TABLE_NAME, TG_OP; END $$;
DROP TRIGGER IF EXISTS pedido_status_historico_imutavel ON public.pedido_status_historico;
CREATE TRIGGER pedido_status_historico_imutavel BEFORE UPDATE OR DELETE ON public.pedido_status_historico
  FOR EACH ROW EXECUTE FUNCTION public.pedido_somente_insercao();
DROP TRIGGER IF EXISTS pedidos_sem_delete ON public.pedidos;
CREATE TRIGGER pedidos_sem_delete BEFORE DELETE ON public.pedidos
  FOR EACH ROW EXECUTE FUNCTION public.pedido_somente_insercao();

-- ---------- cardápio público (JSON para o CDN; AD-10) ----------
CREATE OR REPLACE FUNCTION public.cardapio_publico(p_store uuid) RETURNS jsonb LANGUAGE sql STABLE AS $$
  SELECT jsonb_build_object(
    'tamanhos', (SELECT COALESCE(jsonb_agg(jsonb_build_object('id', id, 'nome', nome, 'fatias', fatias,
                  'max_sabores', max_sabores) ORDER BY ordem), '[]') FROM public.cardapio_tamanhos
                  WHERE store_id = p_store AND ativo),
    'sabores', (SELECT COALESCE(jsonb_agg(jsonb_build_object('id', s.id, 'nome', s.nome, 'descricao', s.descricao,
                  'categoria', c.nome, 'precos', (SELECT jsonb_object_agg(sp.tamanho_id, sp.preco_cents)
                    FROM public.cardapio_sabor_precos sp JOIN public.cardapio_tamanhos t ON t.id = sp.tamanho_id AND t.ativo
                    WHERE sp.sabor_id = s.id)) ORDER BY c.ordem, s.nome), '[]')
                FROM public.cardapio_sabores s LEFT JOIN public.cardapio_categorias c ON c.id = s.categoria_id
                WHERE s.store_id = p_store AND s.ativo),
    'adicionais', (SELECT COALESCE(jsonb_agg(jsonb_build_object('id', a.id, 'grupo', g.nome, 'nome', a.nome,
                  'preco_cents', a.preco_cents) ORDER BY g.nome, a.nome), '[]')
                  FROM public.cardapio_adicionais a JOIN public.cardapio_grupos_adicionais g ON g.id = a.grupo_id AND g.ativo
                  WHERE a.store_id = p_store AND a.ativo),
    'itens', (SELECT COALESCE(jsonb_agg(jsonb_build_object('id', i.id, 'nome', i.nome, 'categoria', c.nome,
                  'preco_cents', i.preco_cents) ORDER BY c.ordem, i.nome), '[]')
              FROM public.cardapio_itens i LEFT JOIN public.cardapio_categorias c ON c.id = i.categoria_id
              WHERE i.store_id = p_store AND i.ativo),
    'regra_preco_pizza', COALESCE((SELECT regra_preco_pizza FROM public.loja_config_pedido WHERE store_id = p_store), 'maior'))
$$;

-- Só o servidor cria pedido (a Edge Function do link aplica limite de requisições antes).
DO $$ BEGIN
  REVOKE ALL ON FUNCTION public.pedido_criar(uuid, jsonb, text, timestamptz) FROM PUBLIC;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON FUNCTION public.pedido_criar(uuid, jsonb, text, timestamptz) FROM anon, authenticated;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    GRANT EXECUTE ON FUNCTION public.pedido_criar(uuid, jsonb, text, timestamptz) TO service_role;
  END IF;
END $$;
