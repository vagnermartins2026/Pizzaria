/**
 * Título, descrição e endereço de cada página. Fonte única para o navegador (usePagina) e para o
 * pré-renderizador do build (scripts/prerender.mjs), que grava isso no HTML de cada rota para o Google.
 */
import { useEffect } from "react";
import { GUIAS } from "./guias";
import { MARCA } from "./marca";

export type MetaPagina = { caminho: string; titulo: string; descricao: string; indexar?: boolean };

export const PAGINAS: MetaPagina[] = [
  {
    caminho: "/",
    titulo: `${MARCA.nome} · Sistema para pizzarias que traz o cliente de volta`,
    descricao:
      "Sistema para pizzarias: link de pedidos próprio, caixa e um CRM que mostra todo dia quem parou de pedir, com a mensagem pronta no WhatsApp.",
  },
  {
    caminho: "/fundadores",
    titulo: `Pizzarias fundadoras · ${MARCA.nome}`,
    descricao: "Seja uma das 10 primeiras pizzarias a usar o sistema, com desconto e voz no que vem primeiro.",
  },
  {
    caminho: "/guias",
    titulo: `Guias para donos de pizzaria · ${MARCA.nome}`,
    descricao: "Contas de verdade, em reais: cliente que some, comissão de marketplace e custo da pizza.",
  },
  ...GUIAS.map((g) => ({ caminho: `/guias/${g.slug}`, titulo: `${g.titulo} · ${MARCA.nome}`, descricao: g.descricao })),
  { caminho: "/termos", titulo: `Termos de Uso · ${MARCA.nome}`, descricao: `Termos de uso do site da ${MARCA.nome}.` },
  { caminho: "/privacidade", titulo: `Política de Privacidade · ${MARCA.nome}`, descricao: `Como a ${MARCA.nome} trata dados pessoais.` },
];

export const urlAbsoluta = (caminho: string) => `${MARCA.site}${caminho === "/" ? "/" : caminho}`;

export function metaDe(caminho: string): MetaPagina {
  return PAGINAS.find((p) => p.caminho === caminho) ?? { caminho, titulo: `Página não encontrada · ${MARCA.nome}`, descricao: "", indexar: false };
}

function definirMeta(seletor: string, criar: () => HTMLElement, atributo: string, valor: string) {
  let el = document.head.querySelector(seletor) as HTMLElement | null;
  if (!el) {
    el = criar();
    document.head.appendChild(el);
  }
  el.setAttribute(atributo, valor);
}

/** Atualiza título, descrição e canonical ao navegar entre páginas (o HTML pré-renderizado já chega certo). */
export function usePagina(caminho: string) {
  useEffect(() => {
    const m = metaDe(caminho);
    document.title = m.titulo;
    const meta = (nome: string, prop = false) => () => {
      const e = document.createElement("meta");
      e.setAttribute(prop ? "property" : "name", nome);
      return e;
    };
    definirMeta('meta[name="description"]', meta("description"), "content", m.descricao);
    definirMeta('meta[property="og:title"]', meta("og:title", true), "content", m.titulo);
    definirMeta('meta[property="og:description"]', meta("og:description", true), "content", m.descricao);
    definirMeta('meta[property="og:url"]', meta("og:url", true), "content", urlAbsoluta(caminho));
    definirMeta('link[rel="canonical"]', () => Object.assign(document.createElement("link"), { rel: "canonical" }), "href", urlAbsoluta(caminho));
    definirMeta('meta[name="robots"]', meta("robots"), "content", m.indexar === false ? "noindex" : "index, follow");
  }, [caminho]);
}
