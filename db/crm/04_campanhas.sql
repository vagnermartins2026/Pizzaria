-- =====================================================================================================
-- Pizzalia · Campanhas (PRD M07b, §10.7, RN-40 a RN-46, RN-53): modelos de mensagem, texto personalizado sem campo
-- vazio, link do WhatsApp (wa.me) com a mensagem pronta, registro de envio, "não enviei" em até 10 min e descarte.
-- Gabarito: demo/gabarito_mensagens_2026-11-08.csv (texto e link idênticos, cliente a cliente).
-- As RPCs conferem a loja por public.current_store_id() — contrato da base (o pacote de segurança, db/seguranca).
-- =====================================================================================================

CREATE TABLE IF NOT EXISTS public.crm_modelos (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id   uuid,                                  -- NULL = modelo padrão da plataforma
  gatilho    text NOT NULL CHECK (gatilho IN ('G1','G2','G3','G4','G5','G6','G7')),
  variante   int  NOT NULL CHECK (variante BETWEEN 1 AND 9),
  corpo      text NOT NULL CHECK (length(corpo) BETWEEN 10 AND 700),
  ativo      boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE NULLS NOT DISTINCT (store_id, gatilho, variante)
);

-- Modelos padrão (os MESMOS textos do gerador demo). Variante 1 usa mais dados; a 2 é o plano B sem o sabor.
INSERT INTO public.crm_modelos (store_id, gatilho, variante, corpo) VALUES
 (NULL,'G1',1,'Oi, {primeiro_nome}! Faz um tempinho que você não pede com a gente 😊 Vimos que {sabor_favorito} está entre as suas favoritas. Que tal matar a vontade hoje? É só pedir por aqui: {link_pedido} 🍕'),
 (NULL,'G1',2,'Oi, {primeiro_nome}! Faz um tempinho que você não pede com a gente 😊 Que tal uma pizza hoje? É só pedir por aqui: {link_pedido} 🍕'),
 (NULL,'G2',1,'Oi, {primeiro_nome}! Sentimos sua falta por aqui 😊 Que tal uma pizza de {sabor_favorito} hoje? Peça por aqui: {link_pedido} 🍕'),
 (NULL,'G2',2,'Oi, {primeiro_nome}! Sentimos sua falta por aqui 😊 Que tal uma pizza hoje? Peça por aqui: {link_pedido} 🍕'),
 (NULL,'G3',1,'Oi, {primeiro_nome}! Obrigado por ter pedido com a gente 😊 Que tal repetir a experiência? Peça por aqui: {link_pedido} 🍕'),
 (NULL,'G4',1,'Oi, {primeiro_nome}! Faz tempo que a gente não se vê 😊 Que tal matar a saudade com uma pizza de {sabor_favorito}? Peça por aqui: {link_pedido} 🍕'),
 (NULL,'G4',2,'Oi, {primeiro_nome}! Faz tempo que a gente não se vê 😊 Que tal matar a saudade com uma pizza hoje? Peça por aqui: {link_pedido} 🍕'),
 (NULL,'G5',1,'Feliz aniversário, {primeiro_nome}! 🎉 A equipe {pizzaria} deseja um dia incrível. Se quiser comemorar com pizza, é só pedir por aqui: {link_pedido} 🍕')
ON CONFLICT (store_id, gatilho, variante) DO UPDATE SET corpo = EXCLUDED.corpo, updated_at = now();

-- Codificação de URL (RFC 3986: só letras, números e - _ . ~ ficam como estão), byte a byte em UTF-8.
CREATE OR REPLACE FUNCTION public.url_codificar(p text) RETURNS text LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(string_agg(CASE WHEN b BETWEEN 48 AND 57 OR b BETWEEN 65 AND 90 OR b BETWEEN 97 AND 122
                                       OR b IN (45, 46, 95, 126) THEN chr(b)
                                  ELSE '%' || upper(lpad(to_hex(b), 2, '0')) END, '' ORDER BY i), '')
  FROM (SELECT i, get_byte(convert_to(p, 'UTF8'), i) AS b
          FROM generate_series(0, octet_length(convert_to(coalesce(p, ''), 'UTF8')) - 1) AS i) x
$$;

-- Texto pronto + link do WhatsApp para uma oportunidade elegível. Modelos da loja substituem os da plataforma
-- (por gatilho). Escolhe a 1ª variante cujas variáveis TODAS têm valor (RN-46).
CREATE OR REPLACE FUNCTION public.crm_mensagem(p_oportunidade uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE AS $$
DECLARE
  o public.crm_oportunidades; v jsonb; m record; t text; k text; val text; tel text;
BEGIN
  SELECT * INTO o FROM public.crm_oportunidades WHERE id = p_oportunidade;
  IF NOT FOUND OR NOT o.elegivel OR o.status NOT IN ('aberta','contatada') THEN
    RAISE EXCEPTION 'OPORTUNIDADE_NAO_ELEGIVEL';
  END IF;
  SELECT jsonb_build_object(
           'primeiro_nome', split_part(btrim(fc.nome), ' ', 1),
           'pizzaria', fl.nome,
           'sabor_favorito', st.sabores_favoritos[1],
           'link_pedido', fl.link_pedido), fc.telefone
    INTO v, tel
    FROM public.crm_fatos_cliente fc
    LEFT JOIN public.crm_fatos_loja fl ON fl.store_id = o.store_id
    LEFT JOIN public.crm_customer_stats st ON st.store_id = o.store_id AND st.customer_id = o.customer_id
   WHERE fc.store_id = o.store_id AND fc.customer_id = o.customer_id;
  FOR m IN SELECT * FROM public.crm_modelos md
            WHERE md.gatilho = o.gatilho AND md.ativo
              AND (md.store_id = o.store_id
                   OR (md.store_id IS NULL AND NOT EXISTS (SELECT 1 FROM public.crm_modelos x WHERE x.store_id = o.store_id
                                                            AND x.gatilho = o.gatilho AND x.ativo)))
            ORDER BY md.variante LOOP
    CONTINUE WHEN EXISTS (SELECT 1 FROM regexp_matches(m.corpo, '\{(\w+)\}', 'g') AS r
                           WHERE COALESCE(v->>r[1], '') = '');
    t := m.corpo;
    FOR k, val IN SELECT key, replace(replace(COALESCE(value, ''), '{', ''), '}', '') FROM jsonb_each_text(v) LOOP   -- nulo nunca apaga o texto
      t := replace(t, '{' || k || '}', val);
    END LOOP;
    t := t || E'\n\nNão quer mais receber nossas mensagens? Responda SAIR.';             -- RN-53
    IF t IS NULL OR t ~ '\{\w+\}' THEN RAISE EXCEPTION 'MENSAGEM_INCOMPLETA: %', m.id; END IF;   -- trava final (RN-46)
    RETURN jsonb_build_object('oportunidade_id', o.id, 'modelo_id', m.id, 'modelo', o.gatilho || '.' || m.variante,
                              'texto', t, 'whatsapp_url',
                              CASE WHEN tel IS NOT NULL THEN 'https://wa.me/' || ltrim(tel, '+') || '?text=' || public.url_codificar(t) END);
  END LOOP;
  RAISE EXCEPTION 'SEM_MODELO_COMPATIVEL: %', o.gatilho;
END $$;

-- ---------- ações do atendente (conferem a loja ativa) ----------
CREATE OR REPLACE FUNCTION public.crm_registrar_contato(p_oportunidade uuid, p_modelo_id uuid DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE o public.crm_oportunidades; v_id uuid;
BEGIN
  SELECT * INTO o FROM public.crm_oportunidades WHERE id = p_oportunidade FOR UPDATE;
  IF NOT FOUND OR o.store_id IS DISTINCT FROM public.current_store_id() THEN RAISE EXCEPTION 'SEM_ACESSO'; END IF;
  IF o.status = 'contatada' THEN                                    -- toque duplo: devolve o mesmo registro
    SELECT id INTO v_id FROM public.crm_contatos WHERE oportunidade_id = o.id AND desfeito_em IS NULL
     ORDER BY enviado_em DESC LIMIT 1;
    IF v_id IS NOT NULL THEN RETURN v_id; END IF;
  END IF;
  IF NOT o.elegivel OR o.status NOT IN ('aberta','contatada') THEN RAISE EXCEPTION 'OPORTUNIDADE_NAO_ELEGIVEL'; END IF;
  INSERT INTO public.crm_contatos (store_id, customer_id, oportunidade_id, gatilho, modelo, enviado_por)
  VALUES (o.store_id, o.customer_id, o.id, o.gatilho,
          (SELECT gatilho || '.' || variante FROM public.crm_modelos WHERE id = p_modelo_id), public.auth_uid_ou_nulo())
  RETURNING id INTO v_id;
  UPDATE public.crm_oportunidades SET status = 'contatada', updated_at = now() WHERE id = o.id;
  RETURN v_id;
END $$;

-- "Não enviei": só em até 10 minutos; o registro fica (desfeito_em), nunca é apagado (RN-40).
CREATE OR REPLACE FUNCTION public.crm_desfazer_contato(p_contato uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE c public.crm_contatos;
BEGIN
  SELECT * INTO c FROM public.crm_contatos WHERE id = p_contato FOR UPDATE;
  IF NOT FOUND OR c.store_id IS DISTINCT FROM public.current_store_id() THEN RAISE EXCEPTION 'SEM_ACESSO'; END IF;
  IF c.desfeito_em IS NOT NULL THEN RETURN; END IF;
  IF now() - c.enviado_em > interval '10 minutes' THEN RAISE EXCEPTION 'PRAZO_ENCERRADO'; END IF;
  UPDATE public.crm_contatos SET desfeito_em = now() WHERE id = c.id;
  UPDATE public.crm_oportunidades SET status = 'aberta', updated_at = now()
   WHERE id = c.oportunidade_id AND status = 'contatada';
END $$;

CREATE OR REPLACE FUNCTION public.crm_descartar(p_oportunidade uuid, p_motivo text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE o public.crm_oportunidades;
BEGIN
  SELECT * INTO o FROM public.crm_oportunidades WHERE id = p_oportunidade FOR UPDATE;
  IF NOT FOUND OR o.store_id IS DISTINCT FROM public.current_store_id() THEN RAISE EXCEPTION 'SEM_ACESSO'; END IF;
  IF o.status NOT IN ('aberta','bloqueada') THEN RAISE EXCEPTION 'OPORTUNIDADE_JA_TRATADA: %', o.status; END IF;
  UPDATE public.crm_oportunidades
     SET status = 'descartada', contexto = contexto || jsonb_build_object('motivo_descarte', left(p_motivo, 200)),
         updated_at = now()
   WHERE id = o.id;
END $$;
