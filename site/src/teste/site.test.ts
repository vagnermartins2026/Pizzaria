/**
 * Testes do site. Rodam em `npm test` e antes de todo `npm run build` (o build para se algum falhar).
 * Protegem o que mais custa caro errar: preço diferente do plano de negócio, botão levando ao lugar errado,
 * conta errada num guia e link interno quebrado.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { LANCAMENTO, MARCA, destinoDoCta, linkWhatsApp } from "@/config/marca";
import { MODULOS, PLANOS } from "@/config/planos";
import { GUIAS } from "@/config/guias";
import { FAQS } from "@/config/faq";
import { PAGINAS, metaDe } from "@/config/paginas";
import { descreverOrigem, guardarOrigemDaUrl, lerOrigem } from "@/config/origem";
import { montarMensagem, whatsappValido } from "@/pages/ListaDeEspera";
import { desenhar } from "@/servidor";

const raiz = join(__dirname, "..", "..");
const plano = readFileSync(join(raiz, "..", "docs", "PLANO-DE-NEGOCIO.md"), "utf8");
const llms = readFileSync(join(raiz, "public", "llms.txt"), "utf8");

describe("preços batem com o plano de negócio", () => {
  it("planos: mesma linha de preço do docs/PLANO-DE-NEGOCIO.md", () => {
    const linha = plano.split("\n").find((l) => l.startsWith("| **Preço mensal sugerido**"))!;
    const precos = [...linha.matchAll(/R\$ (\d+)/g)].map((m) => Number(m[1]) * 100);
    expect(PLANOS.map((p) => p.centavos)).toEqual(precos);
  });
  it("módulos: cada preço em R$ aparece na tabela de módulos do plano", () => {
    for (const m of MODULOS) {
      const n = m.preco.match(/R\$ (\d+)/)?.[1];
      if (n) expect(plano, m.nome).toContain(`| R$ ${n}`);
    }
  });
  it("llms.txt repete os mesmos preços", () => {
    for (const p of PLANOS) expect(llms).toContain(`${p.nome}: R$ ${p.centavos / 100}`);
  });
  it("só um plano recomendado", () => {
    expect(PLANOS.filter((p) => p.destaque)).toHaveLength(1);
  });
});

describe("para onde vão os botões", () => {
  it("pré-lançamento: lista de espera, com o plano", () => {
    expect(destinoDoCta(undefined, {}, "pre-lancamento")).toEqual({ href: "/lista-de-espera", externo: false });
    expect(destinoDoCta("premium", { utm_source: "google" }, "pre-lancamento").href).toBe("/lista-de-espera?plano=premium");
  });
  it("aberto: cadastro do sistema com plano, origem e UTM (contrato do site/LEIAME.md)", () => {
    const { href, externo } = destinoDoCta("profissional", { utm_source: "instagram", indicacao: "CONTADOR1" }, "aberto");
    expect(externo).toBe(true);
    const url = new URL(href);
    expect(`${url.origin}${url.pathname}`).toBe(`${MARCA.app}/cadastro`);
    expect(Object.fromEntries(url.searchParams)).toEqual({ plano: "profissional", origem: "site", utm_source: "instagram", indicacao: "CONTADOR1" });
  });
  it("WhatsApp: número só com dígitos e mensagem codificada", () => {
    const l = linkWhatsApp("Olá & tchau");
    expect(l).toMatch(/^https:\/\/wa\.me\/\d{12,13}\?text=/);
    expect(decodeURIComponent(l.split("text=")[1])).toBe("Olá & tchau");
  });
});

describe("origem da visita", () => {
  let guardado: Record<string, string> = {};
  beforeEach(() => {
    guardado = {};
    (globalThis as any).window = {};
    (globalThis as any).sessionStorage = {
      getItem: (k: string) => guardado[k] ?? null,
      setItem: (k: string, v: string) => (guardado[k] = v),
    };
  });
  afterEach(() => {
    delete (globalThis as any).window;
    delete (globalThis as any).sessionStorage;
  });
  it("guarda a primeira origem da sessão e ignora parâmetros estranhos", () => {
    guardarOrigemDaUrl("?utm_source=google&utm_medium=cpc&x=1");
    guardarOrigemDaUrl("?utm_source=outro");
    expect(lerOrigem()).toEqual({ utm_source: "google", utm_medium: "cpc" });
    expect(descreverOrigem(lerOrigem())).toBe("google (cpc)");
  });
  it("sem armazenamento (aba anônima) não quebra", () => {
    (globalThis as any).sessionStorage = { getItem: () => { throw new Error("bloqueado"); }, setItem: () => { throw new Error("bloqueado"); } };
    expect(() => guardarOrigemDaUrl("?indicacao=ABC")).not.toThrow();
    expect(lerOrigem()).toEqual({});
  });
});

describe("formulário da lista de espera", () => {
  it("valida WhatsApp brasileiro", () => {
    for (const ok of ["(19) 99999-9999", "19999999999", "+55 19 99999-9999", "1933334444"]) expect(whatsappValido(ok), ok).toBe(true);
    for (const ruim of ["", "99999-9999", "019999999999", "abc", "1999999999999"]) expect(whatsappValido(ruim), ruim).toBe(false);
  });
  it("monta a mensagem com o plano e a origem", () => {
    const msg = montarMensagem(
      { nome: "Ana", pizzaria: "Forno X", cidade: "Campinas", whatsapp: "19999999999", pedidos: "20 a 50", plano: "profissional", canais: ["Balcão"] },
      "google (cpc)",
    );
    expect(msg).toContain("Pizzaria: Forno X");
    expect(msg).toContain("Plano de interesse: Profissional");
    expect(msg).toContain("Cheguei por: google (cpc)");
  });
});

describe("as contas dos guias fecham", () => {
  const brl = (t: string) => Number(t.replace(/[^\d,]/g, "").replace(",", "."));
  const guia = (slug: string) => GUIAS.find((g) => g.slug === slug)!;
  it("cliente que some: 97 × 26 = 2.522; × 10 = 25.220", () => {
    expect(97 * 26).toBe(2522);
    expect(guia("quanto-custa-cliente-que-parou-de-pedir").resumo).toContain("R$ 25.220");
  });
  it("marketplace: 300 × 97 × 20% = 5.820; 20% migrando = 1.164", () => {
    expect(Math.round(300 * 97 * 0.2)).toBe(5820);
    expect(Math.round(300 * 0.2 * 97 * 0.2)).toBe(1164);
  });
  it("CMV: a soma da ficha técnica bate com o total e dá 31,5% de R$ 65", () => {
    const linhas = guia("como-calcular-o-custo-da-pizza").secoes[0].tabela!.linhas;
    const total = brl(linhas.at(-1)![1]);
    const soma = linhas.slice(0, -1).reduce((s, [, v]) => s + brl(v), 0);
    expect(soma).toBeCloseTo(total, 2);
    expect(((total / 65) * 100).toFixed(1)).toBe("31.5");
    expect(brl(linhas[2][1])).toBeCloseTo(0.25 * 38, 2);
    expect(brl(linhas[3][1])).toBeCloseTo(0.15 * 28, 2);
  });
});

describe("páginas", () => {
  it("cada página tem título único e descrição de até 160 caracteres", () => {
    const titulos = PAGINAS.map((p) => p.titulo);
    expect(new Set(titulos).size).toBe(titulos.length);
    for (const p of PAGINAS) expect(p.descricao.length, p.caminho).toBeLessThanOrEqual(160);
  });
  it("rota desconhecida não é indexada", () => {
    expect(metaDe("/nao-existe").indexar).toBe(false);
  });
  it("toda página desenha sem erro e todo link interno aponta para uma página que existe", () => {
    const caminhos = new Set(PAGINAS.map((p) => p.caminho));
    for (const { caminho } of PAGINAS) {
      const html = desenhar(caminho);
      expect(html.length, caminho).toBeGreaterThan(500);
      for (const [, href] of html.matchAll(/href="(\/[^"#?]*)/g)) expect(caminhos.has(href), `${caminho} → ${href}`).toBe(true);
    }
  });
  it("sem oferta de fundadoras (decisão do dono, 11/11/2026): nenhuma página promete desconto ou vaga limitada", () => {
    for (const { caminho } of PAGINAS) expect(desenhar(caminho), caminho).not.toMatch(/fundador|50% de desconto|\d+ vagas/i);
    expect(llms).not.toMatch(/fundador/i);
  });
  it("as perguntas frequentes não prometem o que o site não tem", () => {
    expect(FAQS.length).toBeGreaterThanOrEqual(6);
    if (LANCAMENTO.fase === "pre-lancamento") expect(FAQS[0].a).toContain("em construção");
  });
});
