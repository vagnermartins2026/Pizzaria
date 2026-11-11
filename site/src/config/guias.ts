/**
 * Guias para donos de pizzaria (SEO de conteúdo, como os guias da Minha Maleta).
 * Regra: contas de verdade, em reais, com os valores de EXEMPLO ditos como exemplo. Nenhuma taxa de empresa
 * citada como fato e nenhuma promessa do sistema além do PRD. Toda conta tem teste (src/teste/guias.test.ts).
 */
import { MARCA } from "./marca";

export type Secao = { titulo: string; paragrafos: string[]; tabela?: { cabecalho: [string, string]; linhas: [string, string][] } };
export type Guia = { slug: string; h1: string; titulo: string; descricao: string; resumo: string; secoes: Secao[] };

export const GUIAS: Guia[] = [
  {
    slug: "quanto-custa-cliente-que-parou-de-pedir",
    h1: "Quanto custa um cliente que parou de pedir na sua pizzaria",
    titulo: "Quanto custa o cliente que parou de pedir na pizzaria",
    descricao: "A conta, em reais, do cliente fiel que some sem avisar, como perceber antes que seja tarde e o que mandar para ele voltar.",
    resumo: "Um cliente que pedia a cada 14 dias, com pedido médio de R$ 97, deixa R$ 2.522 por ano no caixa. Dez deles sumindo são R$ 25.220.",
    secoes: [
      {
        titulo: "A conta",
        paragrafos: [
          "Pegue um cliente bom: pede a cada 14 dias e gasta em média R$ 97 por pedido. São 26 pedidos por ano (52 semanas ÷ 2). Multiplicando, ele deixa R$ 2.522 por ano na sua pizzaria.",
          "Ele não liga para avisar que parou. Simplesmente começa a pedir em outro lugar. Se dez clientes assim somem num ano, são R$ 25.220 a menos, sem que ninguém perceba o motivo.",
        ],
        tabela: {
          cabecalho: ["Item", "Valor (exemplo)"],
          linhas: [
            ["Valor médio do pedido", "R$ 97"],
            ["Pedidos por ano (a cada 14 dias)", "26"],
            ["O que 1 cliente deixa por ano", "R$ 2.522"],
            ["10 clientes que somem", "R$ 25.220 por ano"],
          ],
        },
      },
      {
        titulo: "Como perceber antes que seja tarde",
        paragrafos: [
          "O sinal não é um número fixo de dias, é o ritmo de cada um. Quem pedia toda semana e está há 15 dias sem pedir já saiu do ritmo. Quem pedia uma vez por mês, ainda não.",
          "Uma regra simples: desconfie quando o cliente passa do dobro do intervalo habitual dele. Sem sistema, isso é impossível de acompanhar para centenas de clientes. Com o histórico de pedidos, dá para listar todo dia.",
          "Outro grupo merece atenção: quem pediu uma única vez. A segunda compra é a que mais define se o cliente fica.",
        ],
      },
      {
        titulo: "O que mandar para ele voltar",
        paragrafos: [
          "Mensagem curta, com o nome e algo que só a sua pizzaria sabe: a pizza favorita dele. Por exemplo: \"Oi, Sofia! Faz um tempinho que você não pede com a gente. Vimos que a Portuguesa está entre as suas favoritas. Que tal hoje?\" e o seu link de pedidos.",
          "Só mande para quem autorizou receber mensagens da pizzaria (é o que a LGPD pede) e não mande mais de uma por semana: cliente que se sente perseguido bloqueia o número.",
          "Depois, confira quem voltou a pedir. Sem essa conta, você não sabe se a mensagem funcionou.",
        ],
      },
    ],
  },
  {
    slug: "link-proprio-ou-marketplace",
    h1: "Link de pedidos próprio ou marketplace: a conta da comissão",
    titulo: "Link de pedidos próprio ou marketplace: a conta da comissão",
    descricao: "Quanto a pizzaria paga de comissão por mês, quanto economiza levando parte dos clientes para o próprio link e por que não precisa sair do marketplace.",
    resumo: "Com 300 pedidos por mês a R$ 97 e 20% de comissão (exemplo), são R$ 5.820 por mês. Levar 1 em cada 5 desses clientes para o link próprio economiza R$ 1.164 por mês.",
    secoes: [
      {
        titulo: "Quanto você paga hoje",
        paragrafos: [
          "Use a comissão do SEU contrato: ela muda conforme o plano e quem faz a entrega. No exemplo abaixo usamos 20% só para fazer a conta.",
          "300 pedidos por mês × R$ 97 = R$ 29.100 vendidos pelo marketplace. Com 20% de comissão, R$ 5.820 ficam com ele todo mês.",
        ],
        tabela: {
          cabecalho: ["Item", "Valor (exemplo)"],
          linhas: [
            ["Pedidos por mês no marketplace", "300"],
            ["Valor médio do pedido", "R$ 97"],
            ["Vendido pelo marketplace", "R$ 29.100"],
            ["Comissão de 20%", "R$ 5.820 por mês"],
            ["Se 20% passarem para o link próprio", "R$ 1.164 a menos de comissão por mês"],
          ],
        },
      },
      {
        titulo: "Não é sair do marketplace",
        paragrafos: [
          "O marketplace é bom para trazer cliente novo. O que pesa é pagar comissão para sempre por quem já é seu cliente e pede toda semana.",
          "A estratégia é ter os dois: o marketplace apresenta a pizzaria, e o cliente que gostou passa a pedir pelo seu link, com o seu cardápio e sem comissão.",
        ],
      },
      {
        titulo: "O que mais o link próprio dá",
        paragrafos: [
          "O contato e o histórico ficam com você: quem pediu, o quê, quando e com que frequência. É isso que permite perceber quem sumiu e mandar a mensagem certa.",
          "Antes de divulgar o link para clientes que vieram do marketplace, leia as regras do seu contrato com ele sobre material de divulgação.",
        ],
      },
    ],
  },
  {
    slug: "como-calcular-o-custo-da-pizza",
    h1: "Como calcular o custo de uma pizza (CMV), passo a passo",
    titulo: "Como calcular o custo de uma pizza (CMV)",
    descricao: "Ficha técnica de uma pizza grande, ingrediente por ingrediente, e a conta do CMV para saber quanto do preço vai para os insumos.",
    resumo: "Numa pizza grande de calabresa de exemplo, os insumos e a caixa somam R$ 20,50. Vendida a R$ 65, o CMV é de 31,5%.",
    secoes: [
      {
        titulo: "A ficha técnica",
        paragrafos: [
          "Ficha técnica é a receita com a quantidade e o custo de cada ingrediente. Pese de verdade uma pizza montada pela sua equipe: o \"mais ou menos\" no queijo é onde o custo escapa.",
          "Os valores abaixo são de exemplo. Troque pelos preços que você paga ao seu fornecedor.",
        ],
        tabela: {
          cabecalho: ["Ingrediente (pizza grande de calabresa)", "Custo (exemplo)"],
          linhas: [
            ["Massa", "R$ 2,10"],
            ["Molho de tomate", "R$ 1,20"],
            ["Mussarela, 250 g a R$ 38/kg", "R$ 9,50"],
            ["Calabresa, 150 g a R$ 28/kg", "R$ 4,20"],
            ["Cebola, azeitona e orégano", "R$ 1,00"],
            ["Caixa", "R$ 2,50"],
            ["Total", "R$ 20,50"],
          ],
        },
      },
      {
        titulo: "A conta do CMV",
        paragrafos: [
          "CMV (custo da mercadoria vendida) em porcentagem = custo dos insumos ÷ preço de venda × 100.",
          "No exemplo: R$ 20,50 ÷ R$ 65,00 × 100 = 31,5%. De cada R$ 65 que entram, R$ 20,50 vão para os ingredientes e a embalagem. O resto paga aluguel, equipe, gás, taxas e, no fim, o lucro.",
          "Não existe um número certo para todo mundo: depende do seu preço e dos seus outros custos. O importante é saber o seu, sabor por sabor, e acompanhar quando o preço do queijo sobe.",
        ],
      },
      {
        titulo: "E a meio a meio?",
        paragrafos: [
          "Conte metade de cada sabor: metade da cobertura de um e metade do outro, mais a massa e a caixa inteiras. Se um dos sabores é bem mais caro, a meio a meio pode ter um CMV maior que o das duas pizzas inteiras.",
          `Fazer essa conta na mão para todo o cardápio dá trabalho. Na ${MARCA.nome}, o estoque com ficha técnica e custo por pizza está previsto para a 3ª etapa do sistema.`,
        ],
      },
    ],
  },
];
