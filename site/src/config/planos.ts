/**
 * Planos e módulos: valores de docs/PLANO-DE-NEGOCIO.md (seções 4 e 5).
 * São PREÇOS PREVISTOS, ainda não validados com a pesquisa de concorrentes. O site diz isso na tela.
 * Mudou o plano de negócio? Mude aqui no mesmo commit.
 */
export type Plano = {
  id: "essencial" | "profissional" | "premium";
  nome: string;
  centavos: number;
  paraQuem: string;
  destaque?: boolean;
  /** Situação no lançamento (plano de negócio, seção 4.1). */
  situacao: string;
  itens: string[];
};

export const PLANOS: Plano[] = [
  {
    id: "essencial",
    nome: "Essencial",
    centavos: 14900,
    paraQuem: "Para a pizzaria pequena que quer sair do caderno e do WhatsApp.",
    situacao: "Completo já na abertura.",
    itens: [
      "Cardápio digital e link de pedidos próprio",
      "Pedidos do link, do balcão e do telefone num painel só",
      "PDV de balcão e caixa com fechamento",
      "Clientes com histórico de pedidos",
      "Comanda impressa pelo navegador",
      "Resumo do dia",
      "3 usuários",
    ],
  },
  {
    id: "profissional",
    nome: "Profissional",
    centavos: 29900,
    destaque: true,
    paraQuem: "Para a pizzaria que quer vender mais e organizar a operação.",
    situacao: "Na abertura sai por R$ 249: cozinha, entregadores e fidelidade chegam depois, sem custo extra.",
    itens: [
      "Tudo do Essencial",
      "CRM inteligente: quem sumiu, todo dia, com a mensagem pronta",
      "Pix online no link de pedidos",
      "Tela da cozinha e gestão de entregadores (2ª etapa)",
      "Cupons e fidelidade (2ª etapa)",
      "8 usuários · suporte até 23h",
    ],
  },
  {
    id: "premium",
    nome: "Premium",
    centavos: 54900,
    paraQuem: "Para a operação maior que quer gestão completa e controle de margem.",
    situacao: "Em pré-venda: financeiro, estoque e compras chegam nas próximas etapas.",
    itens: [
      "Tudo do Profissional",
      "Nota fiscal: NFC-e e NF-e",
      "Financeiro com conciliação de cartões e banco",
      "Estoque, ficha técnica e custo por pizza (CMV)",
      "Salão, mesas e app do garçom",
      "20 usuários · suporte prioritário no horário de pico",
    ],
  },
];

export const MODULOS: { nome: string; preco: string }[] = [
  { nome: "Nota fiscal (NFC-e e NF-e)", preco: "R$ 79/mês" },
  { nome: "Integração iFood", preco: "R$ 79/mês" },
  { nome: "CRM + campanhas (para o Essencial)", preco: "R$ 129/mês" },
  { nome: "Pix online (para o Essencial)", preco: "R$ 39/mês" },
  { nome: "Loja adicional", preco: "70% do plano" },
  { nome: "Usuário extra", preco: "R$ 15/mês" },
];

export const reais = (centavos: number) =>
  (centavos / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: centavos % 100 ? 2 : 0 });
