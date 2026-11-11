/**
 * De onde a visita veio (anúncio, indicação, campanha). Guardado na sessão do navegador e repassado ao
 * cadastro do sistema, para o sistema saber qual canal trouxe cada assinante (CAC por canal, comissão do
 * contador que indicou: plano de negócio, seção 8).
 *
 * Parâmetros aceitos no endereço do site: utm_source, utm_medium, utm_campaign, utm_content, indicacao.
 * Contrato com o sistema: ver site/LEIAME.md ("Contrato do cadastro").
 */
export const PARAMETROS_DE_ORIGEM = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "indicacao"] as const;
const CHAVE = "pz-origem";

export type Origem = Partial<Record<(typeof PARAMETROS_DE_ORIGEM)[number], string>>;

/** Lê a origem do endereço atual e guarda (a primeira origem da sessão vence: é ela que trouxe a pessoa). */
export function guardarOrigemDaUrl(busca: string = typeof window === "undefined" ? "" : window.location.search): void {
  const p = new URLSearchParams(busca);
  const achada: Origem = {};
  for (const k of PARAMETROS_DE_ORIGEM) {
    const v = p.get(k)?.trim();
    if (v) achada[k] = v.slice(0, 80);
  }
  if (!Object.keys(achada).length) return;
  try {
    if (!sessionStorage.getItem(CHAVE)) sessionStorage.setItem(CHAVE, JSON.stringify(achada));
  } catch {
    /* aba anônima ou armazenamento bloqueado: segue sem origem */
  }
}

export function lerOrigem(): Origem {
  try {
    const bruto = typeof window === "undefined" ? null : sessionStorage.getItem(CHAVE);
    return bruto ? (JSON.parse(bruto) as Origem) : {};
  } catch {
    return {};
  }
}

/** "Google (cpc) · campanha X · indicação ABC" para a mensagem de WhatsApp dos fundadores. */
export function descreverOrigem(o: Origem): string {
  const partes = [
    o.utm_source && `${o.utm_source}${o.utm_medium ? ` (${o.utm_medium})` : ""}`,
    o.utm_campaign && `campanha ${o.utm_campaign}`,
    o.indicacao && `indicação ${o.indicacao}`,
  ].filter(Boolean);
  return partes.join(" · ");
}
