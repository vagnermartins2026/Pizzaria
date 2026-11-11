/**
 * FONTE ÚNICA da marca, do endereço e da fase de lançamento.
 *
 * Trocou o nome ou o domínio? Mude AQUI e também em index.html (og:site_name, theme-color) e public/robots.txt
 * (arquivos estáticos). Títulos, descrições, canonical e sitemap saem daqui no build (scripts/prerender.mjs).
 *
 * Checagem de domínio feita em 11/11/2026 nos registros públicos (RDAP do Registro.br, Verisign e Google):
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
  /** Endereço oficial do site (canonical). */
  site: "https://www.pizzalia.com.br",
  /** Onde o sistema vai morar. O cadastro de assinante fica em `${app}/cadastro`. */
  app: "https://app.pizzalia.com.br",
  /** Formato do link de pedidos de cada pizzaria (domínio curto, separado do site). */
  linkDePedidos: "pizzalia.app",
  descricaoCurta: "Sistema de gestão para pizzarias, com CRM que traz o cliente de volta.",
} as const;

/**
 * Fase do site.
 *  - "pre-lancamento": o sistema ainda está sendo construído. Os botões levam à página /fundadores, que monta
 *    a mensagem e abre o WhatsApp comercial. Nada fica guardado no site.
 *  - "aberto": o cadastro do sistema existe. Os botões levam direto a `${MARCA.app}/cadastro`.
 * Virar a chave é mudar só esta linha.
 */
export const LANCAMENTO = {
  fase: "pre-lancamento" as "pre-lancamento" | "aberto",
  vagasFundadores: 10,
  descontoFundadores: "50% de desconto por 6 meses",
  diasDeTeste: 14,
};

/**
 * Quem vende. Contato comercial copiado do site da Minha Maleta (Contera): CONFIRME antes de publicar.
 * Razão social e CNPJ ficam em branco até o dono decidir qual empresa assina o produto.
 */
export const EMPRESA = {
  razaoSocial: "", // ex.: "VHM LABS LTDA" (a definir)
  cnpj: "", // a definir
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
 *  - pré-lançamento: `/fundadores?plano=…` (a página já abre com o plano escolhido)
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
  return { href: q ? `/fundadores?${q}` : "/fundadores", externo: false };
}

export const TEXTO_DO_CTA = LANCAMENTO.fase === "aberto" ? `Testar ${LANCAMENTO.diasDeTeste} dias grátis` : "Quero ser fundador";
