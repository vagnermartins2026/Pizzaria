// Fornalia · Edge Function do link público de pedidos. Só liga o núcleo (nucleo.ts) ao Supabase.
// Segredos (nomes, nunca valores no código): SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (automáticos no Supabase),
// TURNSTILE_SECRET (opcional: liga a verificação anti-robô), LINK_ORIGENS (sites permitidos, separados por vírgula),
// LINK_BASE (ex.: https://fornalia.app). Publicar com verify_jwt = false: o link é público; a proteção é feita aqui.
import { createClient } from "npm:@supabase/supabase-js@2";
import { type Banco, criarTratador, ErroBanco } from "./nucleo.ts";

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function rpc<T>(nome: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await sb.rpc(nome, args);
  if (error) throw new ErroBanco(error.message, error.details ?? undefined);   // o cliente não lança: conferir sempre
  return data as T;
}

const banco: Banco = {
  lojaPorSlug: (slug) => rpc("link_loja", { p_slug: slug }),
  cardapio: (storeId) => rpc("cardapio_publico", { p_store: storeId }),
  statusLink: (storeId) => rpc("loja_status_link", { p_store: storeId }),
  consumirLimite: (chave, max, janelaSeg) => rpc("link_consumir_limite", { p_chave: chave, p_max: max, p_janela_seg: janelaSeg }),
  criarPedido: (storeId, pedido, chave) => rpc("pedido_criar", { p_store: storeId, p_pedido: pedido, p_idempotency_key: chave }),
  acompanhar: (token) => rpc("pedido_acompanhar", { p_token: token }),
};

const segredoTurnstile = Deno.env.get("TURNSTILE_SECRET") ?? "";
Deno.serve(criarTratador({
  banco,
  origens: (Deno.env.get("LINK_ORIGENS") ?? "").split(",").map((s) => s.trim()).filter(Boolean),
  linkBase: Deno.env.get("LINK_BASE") ?? "https://fornalia.app",
  turnstileObrigatorio: segredoTurnstile !== "",
  verificarTurnstile: async (token, ip) => {
    const r = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
      method: "POST", body: new URLSearchParams({ secret: segredoTurnstile, response: token, remoteip: ip }),
    });
    return r.ok && (await r.json()).success === true;
  },
  registrarErro: (contexto, erro) => console.error(JSON.stringify({ funcao: "link-pedido", contexto, erro: String(erro) })),
}));
