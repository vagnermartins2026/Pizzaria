-- =====================================================================================================
-- Fornalia · Pacote de segurança (RLS, permissões e RPCs da equipe) para db/crm e db/pedidos.
-- Aplicar DEPOIS do adaptador da base, que precisa oferecer o contrato:
--   public.current_store_id() → uuid da loja ativa do usuário logado
--   public.fornalia_papel()   → 'dono' | 'gerente' | 'atendente' | 'cozinha' | 'entregador' | 'suporte' | NULL
-- Regras: cada loja só vê o que é seu; cardápio e configuração só dono/gerente alteram; pedido só nasce por RPC;
-- status muda pela equipe (o banco guarda as transições); nada de DELETE em movimento; anônimo não acessa nada
-- direto (o link público passa pela Edge Function com service_role). Idempotente.
-- =====================================================================================================
DO $$ BEGIN
  IF to_regprocedure('public.current_store_id()') IS NULL OR to_regprocedure('public.fornalia_papel()') IS NULL THEN
    RAISE EXCEPTION 'Contrato ausente: aplique antes o adaptador da base (current_store_id e fornalia_papel)';
  END IF;
END $$;

-- ---------- helpers de política (avaliados uma vez por consulta: (select ...)) ----------
CREATE OR REPLACE FUNCTION public.fornalia_pode_configurar() RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT public.fornalia_papel() IN ('dono', 'gerente')
$$;

-- ---------- tabelas com store_id: leitura da própria loja; escrita só dono/gerente ----------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['cardapio_categorias','cardapio_tamanhos','cardapio_sabores','cardapio_grupos_adicionais',
                           'cardapio_adicionais','cardapio_itens','loja_horarios','loja_bairros','loja_config_pedido',
                           'crm_regras','crm_modelos'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, authenticated', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE ON public.%I TO authenticated', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_ler', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (store_id = (select public.current_store_id())%s)',
                   t || '_ler', t, CASE WHEN t = 'crm_modelos' THEN ' OR store_id IS NULL' ELSE '' END);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_incluir', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO authenticated WITH CHECK (store_id = (select public.current_store_id()) AND (select public.fornalia_pode_configurar()))', t || '_incluir', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_alterar', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated USING (store_id = (select public.current_store_id()) AND (select public.fornalia_pode_configurar())) WITH CHECK (store_id = (select public.current_store_id()))', t || '_alterar', t);
  END LOOP;
END $$;
-- horário é configuração de linha: dono/gerente podem apagar um turno (não é movimento).
GRANT DELETE ON public.loja_horarios TO authenticated;
DROP POLICY IF EXISTS loja_horarios_apagar ON public.loja_horarios;
CREATE POLICY loja_horarios_apagar ON public.loja_horarios FOR DELETE TO authenticated
  USING (store_id = (select public.current_store_id()) AND (select public.fornalia_pode_configurar()));

-- ---------- preços por tamanho (sem store_id próprio: herdam do sabor / adicional) ----------
DO $$
DECLARE t text; pai text; col text;
BEGIN
  FOR t, pai, col IN VALUES ('cardapio_sabor_precos', 'cardapio_sabores', 'sabor_id'),
                            ('cardapio_adicional_precos', 'cardapio_adicionais', 'adicional_id') LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, authenticated', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_ler', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.%I p WHERE p.id = %I AND p.store_id = (select public.current_store_id())))', t || '_ler', t, pai, col);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_escrever', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR ALL TO authenticated USING ((select public.fornalia_pode_configurar()) AND EXISTS (SELECT 1 FROM public.%I p WHERE p.id = %I AND p.store_id = (select public.current_store_id()))) WITH CHECK ((select public.fornalia_pode_configurar()) AND EXISTS (SELECT 1 FROM public.%I p WHERE p.id = %I AND p.store_id = (select public.current_store_id())))', t || '_escrever', t, pai, col, pai, col);
  END LOOP;
END $$;

-- ---------- movimento: a equipe lê a própria loja; escrita só por RPC / servidor; nunca DELETE ----------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['pedidos','crm_customer_stats','crm_oportunidades','crm_contatos'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, authenticated', t);
    EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_ler', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (store_id = (select public.current_store_id()))', t || '_ler', t);
  END LOOP;
  FOREACH t IN ARRAY ARRAY['pedido_itens','pedido_item_sabores','pedido_item_adicionais','pedido_status_historico'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, authenticated', t);
    EXECUTE format('GRANT SELECT ON public.%I TO authenticated', t);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_ler', t);
    EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.pedidos p WHERE p.id = %s AND p.store_id = (select public.current_store_id())))',
                   t || '_ler', t, CASE WHEN t IN ('pedido_itens','pedido_status_historico') THEN 'pedido_id'
                                        ELSE '(SELECT i.pedido_id FROM public.pedido_itens i WHERE i.id = pedido_item_id)' END);
  END LOOP;
END $$;
ALTER TABLE public.loja_contadores ENABLE ROW LEVEL SECURITY;          -- só o servidor (sem policy = ninguém)
REVOKE ALL ON public.loja_contadores FROM anon, authenticated;

-- A equipe muda status (o gatilho do banco guarda as transições) e liga o cliente; nada de mexer em valores.
GRANT UPDATE (status, cancelamento_motivo, customer_id) ON public.pedidos TO authenticated;
DROP POLICY IF EXISTS pedidos_status ON public.pedidos;
CREATE POLICY pedidos_status ON public.pedidos FOR UPDATE TO authenticated
  USING (store_id = (select public.current_store_id()) AND (select public.fornalia_papel()) IS NOT NULL)
  WITH CHECK (store_id = (select public.current_store_id()));

-- Os gatilhos gravam o histórico mesmo quando quem muda o status não pode inserir no histórico.
ALTER FUNCTION public.pedido_guardar_status() SECURITY DEFINER SET search_path = public;

-- Depois de "saiu para entrega", só o dono cancela (PRD §9).
CREATE OR REPLACE FUNCTION public.pedido_cancelamento_papel() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'cancelado' AND OLD.status = 'saiu_entrega' AND current_user = 'authenticated'
     AND public.fornalia_papel() IS DISTINCT FROM 'dono' THEN
    RAISE EXCEPTION 'SO_O_DONO_CANCELA_APOS_SAIDA';
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS pedido_cancelamento_papel ON public.pedidos;
CREATE TRIGGER pedido_cancelamento_papel BEFORE UPDATE OF status ON public.pedidos
  FOR EACH ROW EXECUTE FUNCTION public.pedido_cancelamento_papel();

-- ---------- RPCs da equipe ----------
-- Pedido de balcão/telefone pelo PDV: a loja vem da sessão, nunca do navegador.
CREATE OR REPLACE FUNCTION public.pedido_criar_balcao(p_pedido jsonb, p_idempotency_key text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_store uuid := public.current_store_id();
BEGIN
  IF v_store IS NULL OR public.fornalia_papel() IS NULL THEN RAISE EXCEPTION 'SEM_ACESSO'; END IF;
  IF COALESCE(p_pedido->>'canal', '') NOT IN ('balcao', 'telefone') THEN RAISE EXCEPTION 'CANAL_INVALIDO: use balcao ou telefone'; END IF;
  RETURN public.pedido_criar(v_store, p_pedido, p_idempotency_key);
END $$;

-- "Pausar pedidos" e tempo estimado: qualquer pessoa da equipe, só na própria loja (RF-11, RF-12).
CREATE OR REPLACE FUNCTION public.loja_ajustar_operacao(p_pausado boolean, p_motivo text DEFAULT NULL,
                                                        p_tempo_preparo_min int DEFAULT NULL) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_store uuid := public.current_store_id();
BEGIN
  IF v_store IS NULL OR public.fornalia_papel() IS NULL THEN RAISE EXCEPTION 'SEM_ACESSO'; END IF;
  INSERT INTO public.loja_config_pedido (store_id, pausado, pausado_motivo, tempo_preparo_min)
  VALUES (v_store, p_pausado, left(p_motivo, 120), COALESCE(p_tempo_preparo_min, 40))
  ON CONFLICT (store_id) DO UPDATE SET pausado = EXCLUDED.pausado, pausado_motivo = EXCLUDED.pausado_motivo,
      tempo_preparo_min = COALESCE(p_tempo_preparo_min, public.loja_config_pedido.tempo_preparo_min), updated_at = now();
END $$;

-- ---------- execução de funções: anônimo nada; equipe só o que precisa; o resto é do servidor ----------
DO $$
DECLARE f regprocedure;
BEGIN
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE n.nspname = 'public' AND p.prokind = 'f'
              AND p.proname ~ '^(cardapio_|pedido_|loja_|crm_|fone_e164_br$|brl$|url_codificar$|normalizar_bairro$|resumo_hoje$|auth_uid_ou_nulo$|fornalia_pode_configurar$)' LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', f);
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN EXECUTE format('REVOKE ALL ON FUNCTION %s FROM anon', f); END IF;
    IF f::text !~ '^(pedido_criar\(|crm_calcular\(|pedido_validar_operacao\()' THEN
      EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
    ELSE
      EXECUTE format('REVOKE ALL ON FUNCTION %s FROM authenticated', f);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO service_role', f); END IF;
  END LOOP;
END $$;
