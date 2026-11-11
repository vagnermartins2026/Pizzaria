import { LANCAMENTO, MARCA } from "./marca";

/** Perguntas da página inicial. Só responde o que o PRD já decidiu (docs/PRD.md). */
export const FAQS: { q: string; a: string }[] = [
  {
    q: `A ${MARCA.nome} já está funcionando?`,
    a: `Ainda não: o sistema está em construção. Entre na lista de espera e avisamos pelo WhatsApp assim que abrir, por ordem de inscrição. Na abertura, todo plano começa com ${LANCAMENTO.diasDeTeste} dias grátis.`,
  },
  {
    q: "Vou ter que largar o iFood?",
    a: "Não. A ideia é você ter o seu próprio link de pedidos, sem comissão, e trazer para ele quem já é seu cliente. Para quem continua no iFood, há um módulo que faz o pedido cair direto no painel e na cozinha, sem redigitar.",
  },
  {
    q: "O sistema manda mensagem sozinho para os meus clientes?",
    a: "Não. Ele mostra quem sumiu e deixa a mensagem pronta no WhatsApp, mas quem confere e envia é você. Só entra na lista quem autorizou receber mensagens, e ninguém recebe mais de uma por semana.",
  },
  {
    q: "Emite nota fiscal?",
    a: "Sim, NFC-e e NF-e: já vem no Premium e é um módulo à parte nos outros planos. Você só precisa do certificado digital A1 da pizzaria.",
  },
  {
    q: "Funciona no celular?",
    a: "Sim. O painel abre no navegador do celular, do tablet do balcão e do computador, e dá para instalar como aplicativo sem passar pela loja.",
  },
  {
    q: "Preciso de impressora especial?",
    a: "Não. A comanda sai pelo navegador em qualquer impressora. A impressão automática na térmica da cozinha chega numa etapa seguinte.",
  },
  {
    q: "E se eu assinar e não gostar?",
    a: "O primeiro pagamento tem 7 dias de garantia: se pedir nesse prazo, devolvemos o valor inteiro.",
  },
  {
    q: "Tem fidelidade ou multa?",
    a: "No plano mensal, não: você cancela quando quiser. No anual você ganha 2 meses e a implantação sai de graça.",
  },
  {
    q: "Meus dados e os dos meus clientes ficam seguros?",
    a: "Cada pizzaria só enxerga os próprios dados, o acesso tem verificação em duas etapas e os dados são seus: você exporta quando quiser.",
  },
];
