// Testes do núcleo do link com um banco de mentira. Rodar: deno test supabase/functions/link-pedido/
import { assert, assertEquals } from "jsr:@std/assert@1";
import { type Banco, brl, criarTratador, ErroBanco, traduzirErro, validarPedido } from "./nucleo.ts";

const LOJA = { store_id: "11111111-1111-4111-8111-111111111111", nome: "Pizzaria Teste", whatsapp: null };
const SABOR = "22222222-2222-4222-8222-222222222222";
const pedidoOk = { tipo: "retirada", forma_pagamento: "pix", cliente: { nome: "Ana", telefone: "(19) 99876-5432" },
  itens: [{ tipo: "pizza", tamanho_id: SABOR, sabores: [SABOR], preco_unitario_cents: 1 }] };

function montar(over: Partial<Banco> = {}, opc: { turnstile?: boolean; ok?: boolean } = {}) {
  const chamadas: { criar: unknown[]; limites: string[] } = { criar: [], limites: [] };
  const banco: Banco = {
    lojaPorSlug: async (s) => (s === "teste" ? LOJA : null),
    cardapio: async () => ({ sabores: [{ id: SABOR, nome: "Calabresa" }] }),
    statusLink: async () => ({ aberta: true }),
    consumirLimite: async (k) => { chamadas.limites.push(k); return true; },
    criarPedido: async (_s, p, k) => { chamadas.criar.push({ p, k }); return { pedido_id: "x", numero: 7, total_cents: 6190, token_publico: "a".repeat(64), repetido: false }; },
    acompanhar: async (t) => (t === "b".repeat(64) ? { numero: 7, etapa: "Saiu para entrega" } : null),
    ...over,
  };
  const h = criarTratador({ banco, origens: ["https://fornalia.app"], linkBase: "https://fornalia.app",
    turnstileObrigatorio: opc.turnstile ?? false, verificarTurnstile: async () => opc.ok ?? false });
  return { h, chamadas };
}
const post = (corpo: unknown, headers: Record<string, string> = {}) =>
  new Request("https://x/functions/v1/link-pedido/pedido", { method: "POST", body: typeof corpo === "string" ? corpo : JSON.stringify(corpo),
    headers: { "x-forwarded-for": "200.1.2.3", ...headers } });
const CHAVE = "a1b2c3d4-e5f6-4789-9abc-def012345678";

Deno.test("cria o pedido: canal forçado para link, preço do navegador descartado, link de acompanhamento", async () => {
  const { h, chamadas } = montar();
  const r = await h(post({ loja: "teste", chave: CHAVE, pedido: { ...pedidoOk, canal: "balcao" } }));
  assertEquals(r.status, 201);
  const b = await r.json();
  assertEquals(b.numero, 7); assertEquals(b.total, "R$ 61,90");
  assertEquals(b.acompanhar, "https://fornalia.app/teste/pedido/" + "a".repeat(64));
  const enviado = (chamadas.criar[0] as { p: Record<string, unknown>; k: string });
  assertEquals(enviado.p.canal, "link"); assertEquals(enviado.k, CHAVE);
  assertEquals(JSON.stringify(enviado.p).includes("preco_unitario_cents"), false);
  assertEquals(chamadas.limites, ["ip:200.1.2.3", "fone:19998765432", "loja:" + LOJA.store_id]);
});

Deno.test("recusas de entrada: JSON, tamanho, chave, loja, pagamento, endereço, item", async () => {
  const { h, chamadas } = montar();
  assertEquals((await h(post("{quebrado"))).status, 400);
  assertEquals((await h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk, lixo: "x".repeat(40000) }))).status, 413);
  assertEquals((await h(post({ loja: "teste", chave: "curta", pedido: pedidoOk }))).status, 422);
  assertEquals((await h(post({ loja: "nao-existe", chave: CHAVE, pedido: pedidoOk }))).status, 404);
  assertEquals((await h(post({ loja: "teste", chave: CHAVE, pedido: { ...pedidoOk, forma_pagamento: "pix_online" } }))).status, 422);
  assertEquals((await h(post({ loja: "teste", chave: CHAVE, pedido: { ...pedidoOk, tipo: "entrega" } }))).status, 422);
  assertEquals((await h(post({ loja: "teste", chave: CHAVE, pedido: { ...pedidoOk, itens: [{ tipo: "pizza", sabores: ["<script>"] }] } }))).status, 422);
  assertEquals((await h(post({ loja: "teste", chave: CHAVE, pedido: { ...pedidoOk, itens: [] } }))).status, 422);
  assertEquals(chamadas.criar.length, 0);
});

Deno.test("limite de tentativas: 429 e o pedido não chega ao banco", async () => {
  const { h, chamadas } = montar({ consumirLimite: async (k) => !k.startsWith("fone:") });
  const r = await h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk }));
  assertEquals(r.status, 429); assertEquals(chamadas.criar.length, 0);
});

Deno.test("Turnstile ligado: sem token ou token ruim = 403; token bom = 201", async () => {
  assertEquals((await montar({}, { turnstile: true, ok: false }).h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk }))).status, 403);
  assertEquals((await montar({}, { turnstile: true, ok: false }).h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk, turnstile: "t" }))).status, 403);
  assertEquals((await montar({}, { turnstile: true, ok: true }).h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk, turnstile: "t" }))).status, 201);
});

Deno.test("erros do banco viram mensagens claras", async () => {
  const caso = async (msg: string, det?: string) => {
    const { h } = montar({ criarPedido: async () => { throw new ErroBanco(msg, det); } });
    const r = await h(post({ loja: "teste", chave: CHAVE, pedido: pedidoOk }));
    return { status: r.status, corpo: await r.json() };
  };
  let c = await caso("PRECO_MUDOU", '{"total_cents": 7000, "itens": []}');
  assertEquals(c.status, 409); assertEquals(c.corpo.detalhe.total_cents, 7000);
  c = await caso("LOJA_FECHADA: 2026-11-20T18:00");
  assertEquals(c.status, 423); assertEquals(c.corpo.mensagem, "Estamos fechados agora. Abrimos sexta-feira (20/11) às 18:00.");
  c = await caso("PEDIDO_MINIMO: faltam 800 centavos");
  assertEquals(c.corpo.mensagem, "Faltam R$ 8,00 para o pedido mínimo de entrega.");
  c = await caso("PEDIDOS_PAUSADOS: cozinha cheia");
  assert(c.corpo.mensagem.includes("(cozinha cheia)"));
  c = await caso("ESCOLHAS_DO_GRUPO: Bordas (escolhidos 2, mínimo 0, máximo 1)");
  assertEquals(c.status, 422);
  c = await caso('duplicate key value violates unique constraint "x"');
  assertEquals(c.status, 500); assertEquals(c.corpo.codigo, "ERRO_INTERNO");
  assert(!JSON.stringify(c.corpo).includes("duplicate"));              // detalhe técnico nunca vaza para o cliente
});

Deno.test("cardápio com cache e ETag; status com cache curto", async () => {
  const { h } = montar();
  const r = await h(new Request("https://x/functions/v1/link-pedido/cardapio?loja=teste", { headers: { origin: "https://fornalia.app" } }));
  assertEquals(r.status, 200);
  assert(r.headers.get("cache-control")!.includes("s-maxage=300"));
  assertEquals(r.headers.get("access-control-allow-origin"), "https://fornalia.app");
  const etag = r.headers.get("etag")!;
  const r2 = await h(new Request("https://x/functions/v1/link-pedido/cardapio?loja=teste", { headers: { "if-none-match": etag } }));
  assertEquals(r2.status, 304);
  const s = await h(new Request("https://x/functions/v1/link-pedido/status?loja=teste"));
  assertEquals(s.headers.get("cache-control"), "public, max-age=10");
  const fora = await h(new Request("https://x/functions/v1/link-pedido/cardapio?loja=teste", { headers: { origin: "https://site-estranho.com" } }));
  assertEquals(fora.headers.get("access-control-allow-origin"), null);
  assertEquals((await h(new Request("https://x/functions/v1/link-pedido/cardapio?loja=X;drop"))).status, 400);
});

Deno.test("acompanhar: token inválido ou desconhecido = 404; conhecido = situação sem cache", async () => {
  const { h } = montar();
  assertEquals((await h(new Request("https://x/functions/v1/link-pedido/acompanhar?token=123"))).status, 404);
  assertEquals((await h(new Request("https://x/functions/v1/link-pedido/acompanhar?token=" + "c".repeat(64)))).status, 404);
  const r = await h(new Request("https://x/functions/v1/link-pedido/acompanhar?token=" + "b".repeat(64)));
  assertEquals(r.status, 200); assertEquals(r.headers.get("cache-control"), "no-store");
});

Deno.test("funções de apoio", () => {
  assertEquals(brl(123456789), "R$ 1.234.567,89"); assertEquals(brl(5), "R$ 0,05");
  assertEquals(traduzirErro(new ErroBanco("LOJA_FECHADA: ")).mensagem, "Estamos fechados agora.");
  assertEquals(validarPedido({ ...pedidoOk, cliente: { telefone: "1".repeat(30) } }).ok, false);
});
