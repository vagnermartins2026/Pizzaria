<!-- Conversão fiel (pandoc) do briefing original "brief_sistema_pizzaria_crm_inteligente.docx". Não editar: fonte histórica do PRD. -->

**SISTEMA PARA PIZZARIAS\
COM CRM INTELIGENTE**

*Visão do produto, proposta de valor, experiência e escopo inicial*

Objetivo deste documento: consolidar a ideia apresentada na conversa em
um briefing claro, para que outra IA, equipe de produto ou desenvolvedor
consiga dar continuidade sem perder a linha de raciocínio original.

# 1. Visão geral

Criar um sistema simples, extremamente intuitivo e rápido de usar para
pizzarias. A solução deve reunir recebimento de pedidos, operação de
balcão/caixa, cadastro e histórico de clientes e, principalmente, um CRM
inteligente que identifica oportunidades comerciais automaticamente e
sugere campanhas prontas.

O produto deve ser robusto por trás, mas simples na experiência. O dono
ou funcionário da pizzaria não deve precisar entender de dashboards, BI,
indicadores, segmentação ou análise de dados para saber o que fazer. O
sistema deve transformar os dados da operação em ações objetivas e
fáceis de executar.

# 2. Princípio central do produto

**O sistema pensa pelo dono da pizzaria e mostra o que merece atenção
hoje.**

Em vez de exigir que o usuário abra relatórios, interprete números e
descubra oportunidades, o sistema analisa os pedidos e o comportamento
dos clientes em segundo plano. Depois, apresenta uma lista de
oportunidades explicadas em linguagem simples, acompanhadas de uma ação
sugerida.

Exemplo de transformação: em vez de mostrar apenas "taxa de recompra de
24,7%", mostrar "37 clientes estão perto de completar 30 dias sem
comprar. Quer criar uma campanha para trazê-los de volta?"

# 3. Público e necessidades

Público principal: proprietários e equipes de pizzarias, especialmente
operações que precisam de praticidade e não têm tempo ou conhecimento
para analisar relatórios.

-   O dono tem pouco tempo e precisa entender rapidamente o que está
    acontecendo.

-   A equipe precisa receber e registrar pedidos sem processos
    complicados.

-   A pizzaria quer vender por um link próprio, sem depender
    exclusivamente de marketplaces.

-   O negócio precisa organizar pedidos, entrega, caixa e clientes em um
    fluxo simples.

-   A pizzaria quer aumentar a recompra e recuperar clientes que pararam
    de comprar.

-   O CRM precisa funcionar automaticamente, sem exigir que alguém monte
    listas ou planilhas.

# 4. Fluxo de pedidos e operação

O cliente da pizzaria deve conseguir acessar um link próprio de pedidos,
escolher os produtos e concluir a compra de forma simples.

1.  Acessa o link/cardápio digital da pizzaria.

2.  Escolhe pizzas, tamanhos, sabores, adicionais, bebidas e outros
    itens cadastrados.

3.  Informa o endereço de entrega.

4.  O sistema calcula o frete conforme as regras de entrega configuradas
    pela pizzaria.

5.  O cliente revisa o pedido e envia a solicitação.

6.  O pedido aparece no sistema interno para a equipe, incluindo o
    balcão/caixa.

7.  A equipe acompanha e atualiza o andamento do pedido conforme o fluxo
    operacional definido.

Ponto importante: o pedido feito pelo link precisa chegar à operação
interna sem redigitação desnecessária. O objetivo é reduzir atrito e
evitar erros.

# 5. CRM inteligente --- principal diferencial

Cada pedido deve alimentar automaticamente o histórico do cliente. Com o
tempo, o sistema constrói uma visão prática dos hábitos de compra e usa
essas informações para identificar oportunidades de relacionamento e
venda.

## 5.1 Dados que o sistema pode organizar

-   Data da última compra e quantidade de dias desde o último pedido.

-   Frequência de compra e intervalo habitual entre pedidos.

-   Valor total comprado, ticket médio e maiores pedidos.

-   Produtos, sabores, combinações e adicionais mais pedidos.

-   Dias da semana e horários em que costuma comprar.

-   Endereço ou região de entrega, quando pertinente à operação.

-   Clientes novos, recorrentes, frequentes, inativos ou em possível
    risco de abandono.

Essas informações devem ser calculadas automaticamente. O usuário não
deve precisar gerar relatórios nem classificar clientes manualmente.

## 5.2 Oportunidades apresentadas em linguagem simples

A tela de CRM deve priorizar oportunidades acionáveis, não gráficos
complexos. Cada oportunidade pode apresentar: nome do cliente, motivo do
alerta, informação relevante do histórico e uma ação.

  -----------------------------------------------------------------------
  Cliente           Oportunidade      Contexto          Ação
  ----------------- ----------------- ----------------- -----------------
  Maria José        29 dias sem       Costuma pedir     Criar campanha
                    comprar           Calabresa com     
                                      Mussarela         

  João              21 dias sem       Costuma comprar   Criar campanha
                    comprar           aos finais de     
                                      semana            

  Cliente frequente Redução na        Comprava          Tentar recuperar
                    frequência        regularmente e    
                                      está há mais      
                                      tempo sem pedir   
  -----------------------------------------------------------------------

# 6. Campanhas automáticas

O CRM deve identificar grupos e situações relevantes automaticamente e
sugerir campanhas com mensagens personalizadas. A campanha é alimentada
pelos dados reais do sistema, sem que o usuário tenha que montar filtros
ou analisar relatórios.

## 6.1 Exemplos de gatilhos/segmentos

-   Cliente próximo de completar 30 dias sem comprar.

-   Cliente há 60 dias ou mais sem comprar.

-   Cliente frequente que deixou de seguir seu padrão habitual.

-   Cliente que comprou uma única vez e não voltou.

-   Cliente VIP ou com alto volume de compras.

-   Aniversariantes, caso a data de nascimento tenha sido informada.

-   Clientes que costumam comprar em determinado dia da semana.

-   Clientes com preferência recorrente por determinado sabor ou
    produto.

## 6.2 Exemplo de campanha personalizada

Situação identificada: Maria José está há 29 dias sem comprar. O
histórico mostra que Calabresa com Mussarela está entre os sabores que
ela mais pede.

> *"Oi, Maria! Faz um tempinho que você não pede com a gente. 😊 Vimos
> que a Calabresa com Mussarela é uma das suas favoritas. Que tal matar
> a vontade hoje? Podemos preparar seu pedido para chegar rapidinho. 🍕
> Quer pedir novamente?"*

A mensagem acima é apenas um exemplo de tom e personalização. O sistema
deve permitir que a pizzaria revise e adapte o texto antes do envio.

## 6.3 Experiência desejada para o usuário

8.  O sistema identifica a oportunidade.

9.  Gera uma sugestão de mensagem com dados do cliente.

10. O usuário pode aprovar, editar ou descartar.

11. O usuário seleciona ou confirma o canal de envio disponível.

12. O sistema registra a campanha e, quando tecnicamente possível, o
    resultado associado.

A integração de envio --- por exemplo, WhatsApp --- ainda precisa ser
definida tecnicamente. Não assumir que o envio automático está incluído
sem validar API, custos, regras da plataforma e consentimento do
cliente. Como alternativa inicial, pode-se avaliar uma ação de abertura
de conversa com mensagem preenchida, caso seja adequada ao fluxo.

# 7. Interface e experiência

A interface deve ser limpa, objetiva e compreensível para pessoas
leigas. Evitar excesso de menus, gráficos, indicadores e configurações.
A complexidade analítica deve ficar nos bastidores.

Uma hipótese inicial de navegação principal:

-   Pedidos

-   Caixa

-   Clientes

-   Oportunidades

A área "Oportunidades" é especialmente importante: deve funcionar como
uma central de ações recomendadas, explicando o motivo de cada sugestão
e permitindo agir sem navegar por relatórios.

# 8. Ciclo de crescimento do produto

O ciclo desejado é contínuo: o pedido gera dados; os dados enriquecem o
histórico do cliente; o sistema identifica uma oportunidade; o CRM
sugere uma campanha; a campanha pode gerar um novo pedido; e o novo
pedido atualiza o histórico.

**PEDIDO → HISTÓRICO DO CLIENTE → INTELIGÊNCIA → OPORTUNIDADE → CAMPANHA
→ NOVA VENDA**

# 9. O que o produto não deve ser

-   Não deve ser um sistema que exige que o dono acompanhe dashboards
    diariamente.

-   Não deve obrigar o usuário a exportar planilhas ou montar filtros
    para descobrir clientes inativos.

-   Não deve transformar tarefas simples em fluxos longos e cheios de
    etapas.

-   Não deve exibir métricas sem explicar o que elas significam e qual
    ação pode ser tomada.

-   Não deve depender de conhecimento técnico ou de marketing para criar
    uma campanha básica.

# 10. Diretrizes para decisões de produto

-   Simplicidade acima de quantidade de funcionalidades.

-   Ação acima de relatório: toda análise relevante deve apontar uma
    próxima ação.

-   Automação com controle: sugerir e preparar, mas permitir revisão
    humana antes de comunicações externas.

-   Personalização baseada em histórico real, sem inventar preferências
    ou promessas.

-   Operação integrada: evitar retrabalho entre link de pedidos, equipe
    interna, caixa e CRM.

-   Explicações em linguagem comum: o usuário deve entender por que o
    sistema está sugerindo algo.

# 11. Escopo inicial sugerido para organizar o desenvolvimento

A conversa definiu a visão e os diferenciais, mas ainda não fechou todos
os requisitos técnicos. Como ponto de partida para a próxima etapa,
recomenda-se organizar o produto em módulos:

**Módulo 1 --- Cadastro e configuração da pizzaria:** Produtos,
categorias, tamanhos, sabores, adicionais, preços, horários e regras de
entrega/frete.

**Módulo 2 --- Cardápio e link de pedidos:** Experiência do cliente,
carrinho, endereço, cálculo de frete e envio do pedido.

**Módulo 3 --- Operação interna:** Recebimento e acompanhamento dos
pedidos pela equipe, incluindo caixa/balcão. Detalhar posteriormente
cozinha, impressão e status.

**Módulo 4 --- Clientes e histórico:** Cadastro, identificação do
cliente e consolidação automática de compras e preferências observadas.

**Módulo 5 --- Motor de oportunidades:** Regras para detectar
inatividade, frequência, preferências, recorrência e outros padrões.

**Módulo 6 --- CRM e campanhas:** Segmentos automáticos, mensagens
sugeridas, revisão, envio por canal integrado e registro de resultados.

**Módulo 7 --- Visão gerencial simplificada:** Resumo curto do que exige
atenção, sem transformar dashboards em centro da experiência.

# 12. Questões ainda em aberto

Os pontos abaixo não foram definidos na conversa. Devem ser discutidos
antes de fechar arquitetura, escopo, estimativa e implementação:

-   A operação será focada em delivery, retirada no balcão ou ambos?

-   Como serão configuradas as áreas, taxas e regras de frete: por
    bairro, distância, faixa de CEP ou outra regra?

-   Quais status de pedido e etapas da cozinha serão necessários?

-   O caixa terá abertura/fechamento, sangria, formas de pagamento e
    conciliação ou apenas registro dos pedidos?

-   Quais meios de pagamento serão aceitos no link?

-   O cliente poderá acompanhar o pedido e receber atualizações?

-   Qual canal será usado para campanhas e qual modalidade de integração
    será viável?

-   Como será obtido e registrado o consentimento para mensagens
    promocionais? Como tratar descadastro e preferências?

-   Quais limites de frequência serão aplicados para evitar excesso de
    mensagens?

-   Como serão identificados clientes que compram sem cadastro ou usam
    números diferentes?

-   Haverá múltiplas unidades, usuários, permissões ou franquias?

-   Quais indicadores internos serão úteis para o dono, sem
    sobrecarregar a interface?

# 13. Orientação para a IA/equipe que dará continuidade

Use este documento como briefing-base e preserve a intenção principal:
um sistema operacional para pizzarias cuja grande diferença é um CRM
proativo e automático. Não comece adicionando dashboards complexos ou
funcionalidades genéricas só porque são comuns em ERPs.

Próximo trabalho recomendado: transformar esta visão em um PRD
(documento de requisitos do produto), mapear os fluxos de ponta a ponta,
definir regras de negócio e separar MVP de funcionalidades posteriores.
Antes de implementar, apresentar uma proposta de arquitetura de módulos,
entidades principais e automações do CRM para validação.

Critério de sucesso: uma pessoa sem conhecimento técnico consegue operar
pedidos e, ao abrir o sistema, entende rapidamente quais clientes
merecem atenção e consegue iniciar uma campanha personalizada em poucos
passos.

# 14. Resumo executivo

A proposta é desenvolver um sistema simples e intuitivo para pizzarias,
com link próprio para pedidos, cálculo de frete a partir do endereço
informado e integração com a operação interna da loja/caixa. O
diferencial competitivo é um CRM inteligente que aprende com o histórico
de compras e identifica automaticamente clientes inativos, clientes
frequentes, preferências de sabores, padrões de compra e oportunidades
de recompra. Em vez de exigir análises e relatórios, o sistema apresenta
oportunidades em linguagem simples e prepara campanhas personalizadas
para revisão e envio. A tecnologia deve ser robusta, mas a experiência
deve ser extremamente simples: menos análise manual, mais ações que
ajudam a vender.
