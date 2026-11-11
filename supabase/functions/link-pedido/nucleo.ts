// Pizzalia · "porteiro" do link público de pedidos (PRD AD-02, AD-08, AD-10, M03).
// Lógica pura e testável: o acesso ao banco e a verificação do Turnstile chegam por injeção (ver index.ts).
// Rotas (sob /functions/v1/link-pedido):
//   GET  /cardapio?loja=<slug>     cardápio público, com cache de CDN e ETag
//   GET  /status?loja=<slug>       aberta / pausada / próxima abertura (cache curto)
//   POST /pedido                   cria o pedido (limite de tentativas, Turnstile opcional, canal sempre "link")
//   GET  /acompanhar?token=<hex>   situação do pedido, sem dados pessoais

export interface Loja { store_id: string; nome: string; whatsapp: string | null }
export interface ResultadoPedido { pedido_id: string; numero: number; total_cents: number; token_publico: string; repetido: boolean }
export class ErroBanco extends Error {
  constructor(mensagem: string, public detalhe?: string) { super(mensagem); }
}
export interface Banco {
  lojaPorSlug(slug: string): Promise<Loja | null>;
  cardapio(storeId: string): Promise<unknown>;
  statusLink(storeId: string): Promise<unknown>;
  consumirLimite(chave: string, max: number, janelaSeg: number): Promise<boolean>;
  criarPedido(storeId: string, pedido: Record<string, unknown>, chave: string): Promise<ResultadoPedido>;
  acompanhar(token: string): Promise<unknown | null>;
}
export interface Dependencias {
  banco: Banco;
  origens: string[];                       // sites que podem chamar (CORS)
  linkBase: string;                        // ex.: https://pizzalia.app
  turnstileObrigatorio: boolean;
  verificarTurnstile: (token: string, ip: string) => Promise<boolean>;
  registrarErro?: (contexto: string, erro: unknown) => void;
}

export const LIMITES = {
  ip: { max: 10, janelaSeg: 600 },         // 10 pedidos por IP a cada 10 min
  fone: { max: 5, janelaSeg: 600 },        // 5 por celular a cada 10 min
  loja: { max: 300, janelaSeg: 60 },       // 300 por loja por minuto (proteção contra enxurrada)
  leitura: { max: 120, janelaSeg: 60 },    // leituras de acompanhamento por IP por minuto
};
const TAMANHO_MAXIMO = 32 * 1024;
const FORMAS = new Set(["dinheiro", "pix", "debito", "credito", "vale"]);
const DIAS = ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"];

export function brl(cents: number): string {
  const s = (Math.abs(cents) / 100).toFixed(2).split(".");
  return (cents < 0 ? "-" : "") + "R$ " + s[0].replace(/\B(?=(\d{3})+(?!\d))/g, ".") + "," + s[1];
}

function quandoAbre(iso: string | undefined): string {
  const m = iso?.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}:\d{2})$/);
  if (!m) return "Estamos fechados agora.";
  const dia = DIAS[new Date(Date.UTC(+m[1], +m[2] - 1, +m[3])).getUTCDay()];
  return `Estamos fechados agora. Abrimos ${dia} (${m[3]}/${m[2]}) às ${m[4]}.`;
}

// Erro do banco (código no começo da mensagem) → resposta para o cliente final, em português simples.
export function traduzirErro(e: ErroBanco): { status: number; codigo: string; mensagem: string; detalhe?: unknown } {
  const [codigo, ...resto] = e.message.split(":");
  const extra = resto.join(":").trim();
  const item = "Algum item do carrinho mudou ou não está mais disponível. Confira o carrinho e tente de novo.";
  const tabela: Record<string, [number, string]> = {
    PRECO_MUDOU: [409, "O preço de algum item mudou enquanto você montava o pedido. Confira o novo total antes de enviar."],
    TELEFONE_INVALIDO: [422, "Confira o número do celular, com DDD."],
    PEDIDO_SEM_ITENS: [422, "O carrinho está vazio."],
    TROCO_MENOR_QUE_TOTAL: [422, "O valor para troco precisa ser maior que o total do pedido."],
    BAIRRO_NAO_ATENDIDO: [422, "Ainda não entregamos nesse bairro. Você pode escolher retirar no balcão."],
    PEDIDO_MINIMO: [422, `Faltam ${brl(Number(extra.match(/\d+/)?.[0] ?? 0))} para o pedido mínimo de entrega.`],
    QUANTIDADE_DE_SABORES: [422, "A quantidade de sabores não cabe nesse tamanho de pizza."],
    SABOR_REPETIDO: [422, "Escolha sabores diferentes para a mesma pizza."],
    LOJA_FECHADA: [423, quandoAbre(extra)],
    PEDIDOS_PAUSADOS: [423, `Pausamos os pedidos online por alguns minutos${extra ? ` (${extra})` : ""}. Tente de novo em instantes.`],
    LOJA_SEM_HORARIO: [423, "Esta loja ainda não abriu os pedidos online."],
  };
  for (const c of ["TAMANHO_INDISPONIVEL", "SABOR_INDISPONIVEL_NO_TAMANHO", "ITEM_INDISPONIVEL", "ADICIONAL_INDISPONIVEL",
                   "ADICIONAL_REPETIDO", "ESCOLHAS_DO_GRUPO", "QUANTIDADE_INVALIDA", "TIPO_DE_ITEM_INVALIDO"]) tabela[c] = [422, item];
  const achado = tabela[codigo];
  if (!achado) return { status: 500, codigo: "ERRO_INTERNO", mensagem: "Não conseguimos registrar seu pedido agora. Tente de novo em instantes." };
  let detalhe: unknown;
  if (codigo === "PRECO_MUDOU" && e.detalhe) { try { detalhe = JSON.parse(e.detalhe); } catch { /* sem detalhe */ } }
  return { status: achado[0], codigo, mensagem: achado[1], detalhe };
}

type Pedido = Record<string, unknown>;
const texto = (v: unknown, max: number) => typeof v === "string" && v.length <= max;

// Só passa adiante o que o banco espera, com tipos conferidos; o canal é SEMPRE "link".
export function validarPedido(b: unknown): { ok: true; pedido: Pedido } | { ok: false; mensagem: string } {
  if (!b || typeof b !== "object" || Array.isArray(b)) return { ok: false, mensagem: "Pedido inválido." };
  const p = b as Pedido;
  if (p.tipo !== "entrega" && p.tipo !== "retirada") return { ok: false, mensagem: "Escolha entrega ou retirada." };
  if (p.forma_pagamento === "pix_online") return { ok: false, mensagem: "Pagamento por Pix online ainda não está disponível nesta loja." };
  if (!FORMAS.has(String(p.forma_pagamento))) return { ok: false, mensagem: "Escolha a forma de pagamento." };
  if (!Array.isArray(p.itens) || p.itens.length < 1 || p.itens.length > 30) return { ok: false, mensagem: "O carrinho precisa ter de 1 a 30 itens." };
  const cli = (p.cliente ?? {}) as Pedido;
  if (!texto(cli.telefone, 25) || (cli.nome !== undefined && !texto(cli.nome, 80))) return { ok: false, mensagem: "Informe nome e celular." };
  if (p.observacao !== undefined && !texto(p.observacao, 500)) return { ok: false, mensagem: "A observação pode ter até 500 caracteres." };
  const end = p.endereco as Pedido | undefined;
  if (p.tipo === "entrega") {
    if (!end || typeof end !== "object" || !texto(end.bairro, 80) || !texto(end.rua, 120) || !texto(end.numero, 20)) {
      return { ok: false, mensagem: "Informe rua, número e bairro para a entrega." };
    }
    for (const k of Object.keys(end)) if (!["cep", "rua", "numero", "complemento", "bairro", "referencia", "cidade"].includes(k) || !texto(end[k], 120)) {
      return { ok: false, mensagem: "Endereço inválido." };
    }
  }
  const itens: Pedido[] = [];
  for (const i of p.itens as Pedido[]) {
    if (!i || typeof i !== "object") return { ok: false, mensagem: "Item inválido." };
    const ids = (v: unknown) => Array.isArray(v) && v.length <= 4 && v.every((x) => typeof x === "string" && /^[0-9a-f-]{36}$/.test(x));
    const q = i.quantidade === undefined ? 1 : i.quantidade;
    if (!Number.isInteger(q) || (q as number) < 1 || (q as number) > 50) return { ok: false, mensagem: "Quantidade inválida." };
    if (i.tipo === "pizza" && texto(i.tamanho_id, 36) && ids(i.sabores) && (i.adicionais === undefined || ids(i.adicionais))) {
      itens.push({ tipo: "pizza", tamanho_id: i.tamanho_id, sabores: i.sabores, adicionais: i.adicionais ?? [], quantidade: q,
                   ...(texto(i.observacao, 200) ? { observacao: i.observacao } : {}) });   // preço do navegador é descartado
    } else if (i.tipo === "produto" && texto(i.item_id, 36)) {
      itens.push({ tipo: "produto", item_id: i.item_id, quantidade: q });
    } else return { ok: false, mensagem: "Item inválido." };
  }
  const pedido: Pedido = {
    canal: "link", tipo: p.tipo, forma_pagamento: p.forma_pagamento, itens,
    cliente: { telefone: cli.telefone, ...(cli.nome ? { nome: cli.nome } : {}) },
    ...(p.tipo === "entrega" ? { endereco: end } : {}),
    ...(p.observacao ? { observacao: p.observacao } : {}),
    ...(Number.isInteger(p.troco_para_cents) ? { troco_para_cents: p.troco_para_cents } : {}),
    ...(Number.isInteger(p.total_esperado_cents) ? { total_esperado_cents: p.total_esperado_cents } : {}),
  };
  return { ok: true, pedido };
}

function ipDe(req: Request): string {
  return req.headers.get("cf-connecting-ip") ?? req.headers.get("x-forwarded-for")?.split(",")[0].trim() ?? "desconhecido";
}

async function etagDe(corpo: string): Promise<string> {
  const h = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(corpo));
  return 'W/"' + Array.from(new Uint8Array(h).slice(0, 12)).map((b) => b.toString(16).padStart(2, "0")).join("") + '"';
}

export function criarTratador(dep: Dependencias): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    const origem = req.headers.get("origin");
    const cors: Record<string, string> = origem && dep.origens.includes(origem)
      ? { "access-control-allow-origin": origem, "vary": "origin", "access-control-allow-headers": "content-type, if-none-match",
          "access-control-allow-methods": "GET, POST, OPTIONS" }
      : {};
    const json = (status: number, corpo: unknown, extra: Record<string, string> = {}) =>
      new Response(JSON.stringify(corpo), { status, headers: { "content-type": "application/json; charset=utf-8", ...cors, ...extra } });
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

    const url = new URL(req.url);
    const rota = url.pathname.replace(/\/+$/, "").split("/").pop();
    try {
      if (req.method === "GET" && (rota === "cardapio" || rota === "status")) {
        const slug = url.searchParams.get("loja") ?? "";
        if (!/^[a-z0-9-]{3,40}$/.test(slug)) return json(400, { codigo: "LOJA_INVALIDA", mensagem: "Endereço de loja inválido." });
        const loja = await dep.banco.lojaPorSlug(slug);
        if (!loja) return json(404, { codigo: "LOJA_NAO_ENCONTRADA", mensagem: "Não encontramos esta pizzaria." });
        if (rota === "status") {
          return json(200, await dep.banco.statusLink(loja.store_id), { "cache-control": "public, max-age=10" });
        }
        const corpo = JSON.stringify({ loja: { nome: loja.nome, whatsapp: loja.whatsapp }, cardapio: await dep.banco.cardapio(loja.store_id) });
        const etag = await etagDe(corpo);
        const cache = { "cache-control": "public, max-age=60, s-maxage=300, stale-while-revalidate=600", "etag": etag };
        if (req.headers.get("if-none-match") === etag) return new Response(null, { status: 304, headers: { ...cors, ...cache } });
        return new Response(corpo, { status: 200, headers: { "content-type": "application/json; charset=utf-8", ...cors, ...cache } });
      }

      if (req.method === "GET" && rota === "acompanhar") {
        const token = url.searchParams.get("token") ?? "";
        if (!/^[0-9a-f]{64}$/.test(token)) return json(404, { codigo: "PEDIDO_NAO_ENCONTRADO", mensagem: "Pedido não encontrado." });
        if (!await dep.banco.consumirLimite("ler:" + ipDe(req), LIMITES.leitura.max, LIMITES.leitura.janelaSeg)) {
          return json(429, { codigo: "MUITAS_TENTATIVAS", mensagem: "Muitas consultas em pouco tempo. Aguarde um minuto." });
        }
        const situacao = await dep.banco.acompanhar(token);
        return situacao ? json(200, situacao, { "cache-control": "no-store" })
                        : json(404, { codigo: "PEDIDO_NAO_ENCONTRADO", mensagem: "Pedido não encontrado." });
      }

      if (req.method === "POST" && rota === "pedido") {
        const bruto = await req.text();
        if (new TextEncoder().encode(bruto).length > TAMANHO_MAXIMO) return json(413, { codigo: "PEDIDO_GRANDE_DEMAIS", mensagem: "Pedido grande demais." });
        let corpo: Record<string, unknown>;
        try { corpo = JSON.parse(bruto); } catch { return json(400, { codigo: "JSON_INVALIDO", mensagem: "Pedido inválido." }); }
        const slug = String(corpo.loja ?? ""); const chave = String(corpo.chave ?? "");
        if (!/^[a-z0-9-]{3,40}$/.test(slug)) return json(400, { codigo: "LOJA_INVALIDA", mensagem: "Endereço de loja inválido." });
        if (!/^[A-Za-z0-9-]{16,100}$/.test(chave)) return json(422, { codigo: "CHAVE_INVALIDA", mensagem: "Atualize a página e tente de novo." });
        const v = validarPedido(corpo.pedido);
        if (!v.ok) return json(422, { codigo: "PEDIDO_INVALIDO", mensagem: v.mensagem });
        const ip = ipDe(req);
        if (dep.turnstileObrigatorio && !(typeof corpo.turnstile === "string" && await dep.verificarTurnstile(corpo.turnstile, ip))) {
          return json(403, { codigo: "VERIFICACAO_FALHOU", mensagem: "Não conseguimos confirmar que você não é um robô. Atualize a página." });
        }
        const loja = await dep.banco.lojaPorSlug(slug);
        if (!loja) return json(404, { codigo: "LOJA_NAO_ENCONTRADA", mensagem: "Não encontramos esta pizzaria." });
        const fone = String((v.pedido.cliente as Record<string, unknown>).telefone).replace(/\D/g, "");
        for (const [k, l] of [["ip:" + ip, LIMITES.ip], ["fone:" + fone, LIMITES.fone], ["loja:" + loja.store_id, LIMITES.loja]] as const) {
          if (!await dep.banco.consumirLimite(k, l.max, l.janelaSeg)) {
            return json(429, { codigo: "MUITAS_TENTATIVAS", mensagem: "Muitas tentativas em pouco tempo. Aguarde alguns minutos ou fale com a pizzaria." });
          }
        }
        try {
          const r = await dep.banco.criarPedido(loja.store_id, v.pedido, chave);
          return json(r.repetido ? 200 : 201, {
            numero: r.numero, total_cents: r.total_cents, total: brl(r.total_cents), repetido: r.repetido,
            acompanhar: `${dep.linkBase}/${slug}/pedido/${r.token_publico}`,
          });
        } catch (e) {
          if (e instanceof ErroBanco) {
            const t = traduzirErro(e);
            if (t.status === 500) dep.registrarErro?.("criarPedido", e);
            return json(t.status, { codigo: t.codigo, mensagem: t.mensagem, ...(t.detalhe ? { detalhe: t.detalhe } : {}) });
          }
          throw e;
        }
      }
      return json(404, { codigo: "ROTA_INEXISTENTE", mensagem: "Endereço não encontrado." });
    } catch (e) {
      dep.registrarErro?.(rota ?? "?", e);
      return json(500, { codigo: "ERRO_INTERNO", mensagem: "Tivemos um problema. Tente de novo em instantes." });
    }
  };
}
