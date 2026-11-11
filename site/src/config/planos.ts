/**
 * Planos e módulos: valores de docs/PLANO-DE-NEGOCIO.md (seções 4 e 5).
 * São PREÇOS PREVISTOS. Decisão do dono (11/11/2026, D5, após docs/PESQUISA-DE-PRECOS.md): Essencial e
 * Profissional mantidos; o Premium aparece SEM preço ("sob consulta") até ficar completo; implantação de
 * R$ 190 no mensal. Mudou o plano de negócio? Mude aqui no mesmo commit (o teste confere).
 */
export type Plano = {
  id: "essencial" | "profissional" | "premium";
  nome: string;
  centavos: number;
  paraQuem: string;
  destaque?: boolean;
  /** Situação no lançamento (plano de negócio, seção 4.1). */
  situacao: string;
  /** false = o site mostra "Sob consulta" em vez do preço (decisão D5 para o Premium). */
  mostrarPreco?: boolean;
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
    mostrarPreco: false,
    paraQuem: "Para a operação maior que quer gestão completa e controle de margem.",
    situacao: "Em pré-venda, sob consulta: financeiro, estoque e compras chegam nas próximas etapas.",
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

/** Implantação no plano mensal (cadastro do cardápio, configuração e treinamento); no anual é sem custo. */
export const IMPLANTACAO_MENSAL_CENTAVOS = 19000;

export const reais = (centavos: number) =>
  (centavos / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL", minimumFractionDigits: centavos % 100 ? 2 : 0 });
