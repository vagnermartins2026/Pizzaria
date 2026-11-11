/**
 * FONTE ÚNICA da marca, do endereço e da fase de lançamento.
 *
 * Trocou o nome ou o domínio? Mude AQUI e também em: index.html (title, og:*), public/robots.txt e
 * public/sitemap.xml (são arquivos estáticos, não leem este arquivo). O texto do site acompanha sozinho.
 *
 * Checagem de domínio feita em 11/11/2026 nos registros públicos (RDAP do Registro.br, Verisign e Google):
 *   pizzalia.com.br  livre · pizzalia.app livre · pizzalia.com registrado por terceiro
 *   fornalia.com.br  REGISTRADO por terceiro (nome do plano original) · fornalia.app livre
 * Disponibilidade muda a qualquer hora: só vale depois de registrado. Ver docs/MARCA-E-DOMINIO.md.
 */
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

/** Para onde vai o botão principal, conforme a fase. */
export function destinoDoCta(): { href: string; externo: boolean } {
  return LANCAMENTO.fase === "aberto"
    ? { href: `${MARCA.app}/cadastro`, externo: true }
    : { href: "/fundadores", externo: false };
}

export const TEXTO_DO_CTA = LANCAMENTO.fase === "aberto" ? `Testar ${LANCAMENTO.diasDeTeste} dias grátis` : "Quero ser fundador";
