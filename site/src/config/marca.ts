/**
 * FONTE ÚNICA da marca, do endereço e da fase de lançamento.
 *
 * Trocou o nome ou o domínio? Mude AQUI e também em index.html (og:site_name, theme-color) e public/robots.txt
 * (arquivos estáticos). Títulos, descrições, canonical e sitemap saem daqui no build (scripts/prerender.mjs).
 *
 * Nome aprovado pelo dono em 11/11/2026. Checagem de domínio feita no mesmo dia nos registros públicos (RDAP do Registro.br, Verisign e Google):
 *   pizzalia.com.br  livre · pizzalia.app livre · pizzalia.com registrado por terceiro
 *   fornalia.com.br  REGISTRADO por terceiro (nome do plano original) · fornalia.app livre
 * Disponibilidade muda a qualquer hora: só vale depois de registrado. Ver docs/MARCA-E-DOMINIO.md.
 */
import type { Origem } from "./origem";
export const MARCA = {
  nome: "Pizzalia",
  /** Selo do fabricante. A marca que aparece para o cliente final é sempre a da pizzaria. */
  assinatura: "by Contera",
  dominio: "pizzalia.com.br",
  /**
   * Endereço oficial do site (canonical, imagem de prévia, sitemap). A prévia na Cloudflare é gerada com
   * VITE_SITE=https://pizzalia.pages.dev VITE_PREVIA=1 (ver docs/PUBLICAR-SITE.md).
   */
  site: (import.meta.env?.VITE_SITE as string | undefined) || "https://www.pizzalia.com.br",
  /** Onde o sistema vai morar. O cadastro de assinante fica em `${app}/cadastro`. */
  app: "https://app.pizzalia.com.br",
  /** Formato do link de pedidos de cada pizzaria (domínio curto, separado do site). */
  linkDePedidos: "pizzalia.app",
  descricaoCurta: "Sistema de gestão para pizzarias, com CRM que traz o cliente de volta.",
} as const;

/**
 * Fase do site.
 *  - "pre-lancamento": o sistema ainda está sendo construído. Os botões levam à lista de espera (/lista-de-espera),
 *    que monta a mensagem e abre o WhatsApp comercial. Nada fica guardado no site. Sem desconto nem vaga limitada
 *    (decisão do dono, 11/11/2026: sem oferta de fundadoras).
 *  - "aberto": o cadastro do sistema existe. Os botões levam direto a `${MARCA.app}/cadastro`.
 * Virar a chave é mudar só esta linha.
 */
export const LANCAMENTO = {
  fase: "pre-lancamento" as "pre-lancamento" | "aberto",
  diasDeTeste: 14,
};

/**
 * Quem vende (Decreto 7.962/2013, art. 2º: dados públicos da empresa, não segredo). Decisões do dono em 11/11/2026
 * (D4 e D6, "siga as opções recomendadas"): a mesma empresa e os mesmos contatos comerciais da Minha Maleta.
 */
export const EMPRESA = {
  razaoSocial: "VHM LABS LTDA",
  cnpj: "64.393.377/0001-30",
  cidade: "Campinas/SP",
  email: "comercial@contera.com",
  /** Com DDI, só dígitos: é o formato do wa.me. */
  whatsapp: "5519982147840",
  whatsappVisivel: "(19) 98214-7840",
  horarioAtendimento: "seg a sex, 8h às 18h · sáb, 8h às 12h",
} as const;

export function linkWhatsApp(mensagem = `Olá! Vim pelo site da ${MARCA.nome} e tenho uma dúvida.`): string {
  return `https://wa.me/${EMPRESA.whatsapp}?text=${encodeURIComponent(mensagem)}`;
}

/**
 * Para onde vai o botão principal, conforme a fase.
 *  - aberto: `${MARCA.app}/cadastro?plano=…&origem=site&utm_…&indicacao=…` (contrato em site/LEIAME.md)
 *  - pré-lançamento: `/lista-de-espera?plano=…` (a página já abre com o plano escolhido)
 */
export function destinoDoCta(plano?: string, origem: Origem = {}, fase = LANCAMENTO.fase): { href: string; externo: boolean } {
  const p = new URLSearchParams();
  if (plano) p.set("plano", plano);
  if (fase === "aberto") {
    p.set("origem", "site");
    for (const [k, v] of Object.entries(origem)) if (v) p.set(k, v);
    return { href: `${MARCA.app}/cadastro?${p}`, externo: true };
  }
  const q = p.toString();
  return { href: q ? `/lista-de-espera?${q}` : "/lista-de-espera", externo: false };
}

export const TEXTO_DO_CTA = LANCAMENTO.fase === "aberto" ? `Testar ${LANCAMENTO.diasDeTeste} dias grátis` : "Entrar na lista de espera";
