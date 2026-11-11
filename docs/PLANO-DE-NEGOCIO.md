# Plano de negócio: Fornalia by Contera

| Campo | Valor |
|---|---|
| Versão | 0.2 (auditoria: fiscal no Premium, disponibilidade por release) |
| Data | 2026-11-08 |
| Documentos relacionados | [`PRD.md`](./PRD.md) (o produto) · [`PILOTO-DEMO.md`](./PILOTO-DEMO.md) (pizzaria fictícia) |

> **Atenção aos números.** Os preços abaixo são uma **recomendação de posicionamento**, não
> resultado de pesquisa de mercado feita nesta sessão. Antes de publicar a tabela, confira os
> preços atuais de 3 a 5 concorrentes (sistemas de gestão e cardápio digital para food service)
> e ajuste dentro das faixas sugeridas.

---

## 1. ERP ou SaaS? Os dois, e não são coisas opostas
- **ERP** descreve **o que o sistema faz**: integra operação, vendas, estoque, compras,
  financeiro e fiscal da empresa num lugar só.
- **SaaS** descreve **como ele é entregue e cobrado**: na nuvem, por assinatura mensal, sem instalação.

**Posicionamento recomendado:** *"ERP para pizzarias, na nuvem, que vende por você."*
Tecnicamente é um **ERP vertical** (feito para um único segmento) **entregue como SaaS**.
Na comunicação com o dono da pizzaria, use "sistema de gestão" mais do que "ERP": é a palavra
que ele usa. "ERP" fica para material com contador, investidor ou rede de franquias.

## 2. Nome e marca
**Recomendado: Fornalia, by Contera.**
- *Forno* + sufixo *-alia* (sonoridade italiana de festa e abundância). Curto, fácil de falar,
  e funciona como domínio e como link de cardápio (`fornalia.app/sua-pizzaria`).
- É um nome inventado, então tem mais chance de registro do que um nome genérico.
- Assinatura de marca: **"Fornalia, by Contera"**. A Contera é a fabricante (selo discreto no
  sistema); a Fornalia é o produto. Isso permite lançar depois outras verticais
  (hamburgueria, açaí) com a mesma base.

| Alternativa | Prós | Contras |
|---|---|---|
| **Contera Forno** | Reforça a marca Contera | Mais genérico, difícil de distinguir como produto |
| **Redonda** | Simpático, memorável | Muito genérico para registrar |

**Antes de adotar:** pesquise o nome no INPI (classes 9 e 42, software e SaaS), confira os
domínios `.com.br` e `.app` e os perfis em redes sociais.

## 3. Modelo de cobrança: plano base + módulos
A pizzaria contrata **um plano** (o pacote base) e liga **módulos adicionais** conforme
precisa. Tudo é cobrado **por loja (CNPJ/unidade), por mês**.

Por que esse modelo:
- **Entrada barata** derruba a objeção "é caro" e acelera a venda.
- **Crescimento dentro da conta** (expansão) é a forma mais barata de aumentar receita: o
  cliente já confia e só liga mais um módulo.
- **Cada módulo se paga com uma conta simples** que o vendedor mostra na hora (seção 6).

Tecnicamente isso já está previsto no PRD (seção 12.6, *direitos de uso por módulo*): ligar
ou desligar um módulo não exige mudar código nem migrar dados.

## 4. Planos

| | **Essencial** | **Profissional** (recomendado) | **Premium** |
|---|---|---|---|
| **Preço mensal sugerido** | **R$ 149** | **R$ 299** | **R$ 549** |
| Faixa para ajuste após pesquisa | R$ 119 a 179 | R$ 249 a 349 | R$ 449 a 649 |
| Para quem | Pizzaria pequena saindo do caderno/WhatsApp | Pizzaria que quer vender mais e organizar a operação | Operação maior que quer gestão completa e controle de margem |
| Cardápio digital e link de pedidos próprio | Sim | Sim | Sim |
| Pedidos (link, balcão, telefone) e status em tempo real | Sim | Sim | Sim |
| PDV de balcão e caixa (abertura, sangria, fechamento) | Sim | Sim | Sim |
| Clientes com histórico | Sim | Sim | Sim |
| Impressão de comanda | Sim | Sim | Sim |
| Resumo do dia | Sim | Sim | Sim |
| **CRM inteligente + campanhas por WhatsApp (link)** | Módulo | **Sim** | **Sim** |
| Cupons e fidelidade (pontos/cashback) | Módulo | **Sim** | **Sim** |
| Tela de cozinha (KDS) | — | **Sim** | **Sim** |
| Gestão de entregadores e despacho | — | **Sim** | **Sim** |
| Pix online no link | Módulo | **Sim** | **Sim** |
| **Fiscal (NFC-e e NF-e)** | Módulo | Módulo | **Sim** |
| Salão, mesas, comandas e app do garçom | — | Módulo | **Sim** |
| **Financeiro completo + conciliação automática** | — | Módulo | **Sim** |
| Estoque de insumos, ficha técnica e CMV | — | Módulo | **Sim** |
| Compras e fornecedores | — | — | **Sim** |
| Relatórios avançados e engenharia de cardápio | — | — | **Sim** |
| Copiloto com IA (previsão de demanda, sugestão de compra) | — | — | **Sim** |
| Usuários incluídos | 3 | 8 | 20 |
| Suporte | Chat e e-mail em horário comercial | Chat estendido até 23h | Prioritário, inclusive no horário de pico, com gerente de conta |

### 4.1 Disponibilidade por release (o que vender e quando)
Os planos dependem de módulos que chegam em releases diferentes (PRD, seção 15). Regra:
**só se cobra preço cheio de um plano quando todos os itens dele estiverem liberados.**

| Release | Essencial | Profissional | Premium |
|---|---|---|---|
| **R1** (mês 5) | Completo: preço cheio | Sem KDS, entregadores e fidelidade → **preço de lançamento R$ 249**, com os itens chegando sem custo na R2 | **Não vender** (falta financeiro, estoque, compras) |
| **R2** (mês 8) | — | Completo: preço cheio | Vender como **pré-venda** com preço de lançamento (estoque e compras chegam na R3) |
| **R3** (mês 11) | — | — | Completo, exceto a IA (R4): preço cheio, IA entra como bônus na R4 |

## 5. Módulos avulsos (ligam em qualquer plano compatível)

| Módulo | Preço/mês sugerido | Observações |
|---|---|---|
| **CRM Inteligente + Campanhas** (para o Essencial) | R$ 129 | Já incluso no Profissional e no Premium |
| **Fiscal: NFC-e e NF-e** (Essencial e Profissional) | R$ 79 | Incluso no Premium. O cliente fornece o certificado digital A1. Custo do emissor parceiro já embutido. Nunca é bloqueado no expediente por atraso de pagamento (PRD 12.6) |
| **Integração iFood** | R$ 79 | Pedidos do iFood caem direto no painel, na cozinha e no caixa |
| **Integração 99Food** | R$ 59 | Mesma lógica; disponibilidade da API a confirmar com a 99 |
| **Pacote Marketplaces** (iFood + 99Food + futuros) | R$ 119 | Mais barato que somar os dois |
| **Financeiro + Conciliação automática** (para o Profissional) | R$ 149 | Conciliação bancária e de cartões (taxas e recebíveis) |
| **Estoque + Ficha técnica + CMV** (para o Profissional) | R$ 99 | — |
| **Salão e mesas** (para o Profissional) | R$ 79 | Comandas, divisão de conta, taxa de serviço, QR na mesa |
| **WhatsApp oficial (API) + robô de pedidos** | R$ 149 + custo por conversa | O custo das conversas da Meta é repassado sem margem ou com margem pequena. Previsto para a release R4 |
| **Pix online** (para o Essencial) | R$ 39 | As tarifas do Mercado Pago são pagas pela pizzaria |
| **Loja adicional** (multi-loja) | 70% do plano da loja | Cardápio central, relatórios consolidados |
| **Usuário extra** | R$ 15 | Acima do limite do plano |

**Cobranças únicas e condições**
| Item | Recomendação |
|---|---|
| Implantação (cadastro do cardápio, configuração, treinamento de 1 h) | R$ 390 no mensal; **grátis no anual** |
| Pagamento anual | **2 meses grátis** (cerca de 17% de desconto) |
| Teste grátis | 14 dias com o Profissional (no que estiver liberado), com a pizzaria demonstrativa carregada como exemplo, separada da conta real do cliente |
| Fidelidade mínima | Nenhuma no mensal (reduz a objeção de compra) |
| Reajuste | Anual, por IPCA |

## 6. Argumento de venda por módulo (a conta que o vendedor mostra)
| Módulo | Conta simples |
|---|---|
| CRM Inteligente (R$ 129) | Valor médio do pedido ~R$ 97. **Basta recuperar 2 pedidos por mês** para pagar o módulo. Na pizzaria demo (29 pedidos/dia), o motor encontra 218 clientes com oportunidade num único dia; outros 248 ficam de fora só por falta de autorização |
| Link próprio vs. marketplace | Cada pedido que migra do marketplace para o link próprio deixa de pagar a comissão do marketplace. Poucos pedidos por mês cobrem o plano |
| Conciliação automática (R$ 149) | Encontra taxa de cartão cobrada a mais e recebível que não caiu, além de poupar horas de planilha por mês |
| Estoque + CMV (R$ 99) | Um desperdício de insumo de 2% numa pizzaria de R$ 80 mil/mês é R$ 1.600 |
| Integração iFood (R$ 79) | Acaba com a redigitação e com o erro de pedido entre tablet do iFood e cozinha |

## 7. Projeção ilustrativa com 100 lojas
Premissas: 30% Essencial, 50% Profissional, 20% Premium; em média 1 módulo avulso por loja (R$ 80).

| Componente | Cálculo | MRR |
|---|---|---|
| Essencial | 30 × R$ 149 | R$ 4.470 |
| Profissional | 50 × R$ 299 | R$ 14.950 |
| Premium | 20 × R$ 549 | R$ 10.980 |
| Módulos avulsos | 100 × R$ 80 | R$ 8.000 |
| **Total** | | **≈ R$ 38.400/mês (≈ R$ 460 mil/ano)** |

Custos variáveis a medir no piloto: infraestrutura (banco, hospedagem, filas), emissor
fiscal por CNPJ, tarifas de meios de pagamento, custo das conversas de WhatsApp (repassado) e
suporte. Com essa base, a margem bruta típica de SaaS fica acima de 70%; **confirmar com
os custos reais do piloto**.

Indicadores a acompanhar desde o primeiro cliente: MRR, cancelamento mensal (meta < 3%),
expansão (% de clientes que ligaram mais um módulo), custo de aquisição (CAC), tempo até o
primeiro pedido no sistema e **pedidos recuperados pelo CRM** (o número que mais vende).

## 8. Estratégia de entrada no mercado
1. **Demonstração com a pizzaria fictícia** "Forno da Vila" (dados já gerados): o prospect vê
   as oportunidades do CRM em 2 minutos.
2. ~~**Primeiros 10 clientes** com 50% de desconto por 6 meses, em troca de depoimento e
   reuniões de feedback quinzenais.~~ **Decisão do dono (11/11/2026): sem oferta de fundadoras.**
   No pré-lançamento o site tem uma lista de espera, sem desconto nem vaga limitada.
3. **Canal de contadores** (rede do Grupo Contabilize): o contador indica e recebe comissão
   recorrente (ex.: 10% por 12 meses). O módulo fiscal e o financeiro facilitam a vida do
   próprio contador, o que dá a ele um bom motivo para indicar.
4. **Prova social com número:** "a pizzaria X recuperou 41 pedidos em 30 dias".
5. Conteúdo e anúncios regionais primeiro (Campinas e região), depois expansão.

## 9. Decisões pendentes deste plano
- [ ] Aprovar o nome (após checagem no INPI e de domínio). **11/11/2026:** `fornalia.com.br` já
  está registrado por terceiro; nova recomendação **Pizzalia** em [`MARCA-E-DOMINIO.md`](./MARCA-E-DOMINIO.md).
- [ ] Validar os preços com a pesquisa de concorrentes (faixas da seção 4).
- [ ] Definir o percentual de comissão do canal de contadores.
- [ ] Confirmar a disponibilidade e as condições da API da 99Food antes de vender o módulo.
