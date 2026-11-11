// Teste de ponta a ponta: o núcleo do link chamando as funções SQL de verdade num Postgres local DESCARTÁVEL.
// Só roda com PIZZALIA_PG_DB definido (db/testar_tudo.sh prepara o banco e o socket); sem ele, é pulado.
import { assertEquals } from "jsr:@std/assert@1";
import postgres from "npm:postgres@3.4.5";
import { type Banco, criarTratador, ErroBanco } from "./nucleo.ts";

const BANCO_PG = Deno.env.get("PIZZALIA_PG_DB");
Deno.test({ name: "link de ponta a ponta contra o SQL real", ignore: !BANCO_PG, sanitizeResources: false, sanitizeOps: false, fn: async () => {
  const sql = postgres({ path: `${Deno.env.get("PIZZALIA_PG_SOCKET")}/.s.PGSQL.${Deno.env.get("PIZZALIA_PG_PORT") ?? "5432"}`,
    database: BANCO_PG, username: Deno.env.get("PIZZALIA_PG_USER") ?? "postgres", max: 4, onnotice: () => {} });
  const chamar = async (q: PromiseLike<readonly unknown[]>) => {
    try { return ((await q)[0] as Record<string, unknown>).r; }
    catch (e) { const x = e as { message: string; detail?: string }; throw new ErroBanco(x.message, x.detail); }
  };
  const banco: Banco = {
    lojaPorSlug: (s) => chamar(sql`SELECT public.link_loja(${s}) AS r`) as never,
    cardapio: (id) => chamar(sql`SELECT public.cardapio_publico(${id}) AS r`),
    statusLink: (id) => chamar(sql`SELECT public.loja_status_link(${id}) AS r`),
    consumirLimite: (k, m, j) => chamar(sql`SELECT public.link_consumir_limite(${k}, ${m}, ${j}) AS r`) as never,
    criarPedido: (id, p, k) => chamar(sql`SELECT public.pedido_criar(${id}, ${sql.json(p as never)}, ${k}) AS r`) as never,
    acompanhar: (t) => chamar(sql`SELECT public.pedido_acompanhar(${t}) AS r`),
  };
  const h = criarTratador({ banco, origens: [], linkBase: "https://pizzalia.app", turnstileObrigatorio: false, verificarTurnstile: async () => true });
  const L = "33333333-3333-4333-8333-333333333333", ITEM = "44444444-4444-4444-8444-444444444444";
  await sql`INSERT INTO public.loja_links (store_id, slug, nome) VALUES (${L}, 'pizzaria-ponta', 'Pizzaria Ponta')`;
  await sql`INSERT INTO public.cardapio_itens (id, store_id, nome, preco_cents) VALUES (${ITEM}, ${L}, 'Refri', 1400)`;
  await sql`INSERT INTO public.loja_bairros (store_id, nome, taxa_cents) VALUES (${L}, 'Centro', 600)`;
  await sql`INSERT INTO public.loja_config_pedido (store_id, pedido_minimo_cents) VALUES (${L}, 2000)`;
  const pedir = (pedido: unknown, chave: string) => h(new Request("https://x/link-pedido/pedido", { method: "POST",
    headers: { "x-forwarded-for": "10.0.0.1" }, body: JSON.stringify({ loja: "pizzaria-ponta", chave, pedido }) }));
  const base = { tipo: "retirada", forma_pagamento: "pix", cliente: { telefone: "19998765432" }, itens: [{ tipo: "produto", item_id: ITEM, quantidade: 2 }] };

  let r = await pedir(base, "ponta-sem-horario-0001");                       // loja ainda sem horário
  assertEquals(r.status, 423); assertEquals((await r.json()).codigo, "LOJA_SEM_HORARIO");
  await sql`INSERT INTO public.loja_horarios (store_id, dia_semana, abre, fecha) SELECT ${L}, d, '00:00', '24:00' FROM generate_series(0, 6) d`;
  r = await pedir(base, "ponta-pedido-000001");
  assertEquals(r.status, 201);
  const criado = await r.json();
  assertEquals(criado.total, "R$ 28,00");
  r = await pedir(base, "ponta-pedido-000001");                              // mesma chave: mesmo pedido
  assertEquals(r.status, 200); assertEquals((await r.json()).numero, criado.numero);
  r = await pedir({ ...base, tipo: "entrega", endereco: { rua: "Rua A", numero: "10", bairro: "centro" }, itens: [{ tipo: "produto", item_id: ITEM }] }, "ponta-minimo-00001");
  assertEquals(r.status, 422); assertEquals((await r.json()).mensagem, "Faltam R$ 6,00 para o pedido mínimo de entrega.");
  r = await pedir({ ...base, total_esperado_cents: 100 }, "ponta-preco-000001");
  const p = await r.json(); assertEquals(r.status, 409); assertEquals(p.detalhe.total_cents, 2800);
  const token = criado.acompanhar.split("/").pop();
  r = await h(new Request("https://x/link-pedido/acompanhar?token=" + token));
  const a = await r.json();
  assertEquals(a.etapa, "Recebemos seu pedido"); assertEquals(a.loja.nome, "Pizzaria Ponta");
  assertEquals(JSON.stringify(a).includes("19998765432"), false);           // sem telefone na resposta pública
  r = await h(new Request("https://x/link-pedido/cardapio?loja=pizzaria-ponta"));
  assertEquals((await r.json()).cardapio.itens[0].nome, "Refri");
  for (let i = 0; i < 4; i++) await pedir(base, "ponta-limite-00000" + i); // 5º, 6º... pedido do mesmo celular em 10 min
  r = await pedir(base, "ponta-limite-000009");
  assertEquals(r.status, 429);
  await sql.end();
} });
