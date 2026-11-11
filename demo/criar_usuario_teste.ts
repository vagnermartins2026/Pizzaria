// Pizzalia · cria o USUÁRIO DE TESTE (papel Dono) da pizzaria demo, depois do remix e do carregador.
// Uso (no computador da Contera ou numa sessão com os segredos, NUNCA com a chave no código ou no chat):
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... deno run --allow-env --allow-net demo/criar_usuario_teste.ts
// O que faz: (1) gera uma senha forte ÚNICA (20 caracteres), (2) cria o login no Supabase Auth já confirmado e marcado
// como demo, (3) liga o login à loja demo com o papel "dono" pela função da base pizzalia_vincular_usuario_demo
// (o adaptador da base cria essa função no remix), (4) mostra a senha UMA vez, para a Contera entregar ao dono.
// Rodar de novo com o mesmo e-mail não cria outro login: avisa e para.
import { createClient } from "npm:@supabase/supabase-js@2";

export const EMAIL_PADRAO = "dono.demo@pizzalia.app";
export const LOJA_DEMO = "1e45234c-bd80-52ab-b4e0-983c9d2eee6b"; // tenant da pizzaria demo (uuid5 estável do gerador)

export function senhaForte(tamanho = 20): string {
  const letras = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%*-_";
  const bytes = crypto.getRandomValues(new Uint8Array(tamanho * 2));
  let s = "";
  for (const b of bytes) {
    if (b < 256 - (256 % letras.length)) s += letras[b % letras.length]; // sem viés
    if (s.length === tamanho) break;
  }
  if (!/[A-Z]/.test(s) || !/[a-z]/.test(s) || !/[0-9]/.test(s) || !/[!@#%*\-_]/.test(s)) return senhaForte(tamanho);
  return s;
}

if (import.meta.main) {
  const url = Deno.env.get("SUPABASE_URL"), chave = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !chave) { console.error("Faltam SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY no ambiente."); Deno.exit(1); }
  const email = Deno.env.get("EMAIL_TESTE") ?? EMAIL_PADRAO;
  const sb = createClient(url, chave, { auth: { persistSession: false, autoRefreshToken: false } });
  const senha = senhaForte();
  const { data, error } = await sb.auth.admin.createUser({ email, password: senha, email_confirm: true,
    user_metadata: { nome: "Dono (DEMO)", is_demo: true }, app_metadata: { is_demo: true } });
  if (error) { console.error(`Não criei o login (${error.message}). Se ele já existe, use "esqueci a senha" ou apague pelo painel.`); Deno.exit(1); }
  const { error: e2 } = await sb.rpc("pizzalia_vincular_usuario_demo", { p_user: data.user.id, p_store: LOJA_DEMO, p_papel: "dono" });
  if (e2) { console.error(`Login criado, mas não liguei à loja demo (${e2.message}). Rode o adaptador da base e tente de novo.`); Deno.exit(1); }
  console.log(`Usuário de teste pronto.\n  E-mail: ${email}\n  Senha (mostrada só agora; guarde e entregue ao dono): ${senha}`);
}
