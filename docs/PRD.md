# PRD: Fornalia by Contera (ERP para pizzarias com CRM inteligente)

| Campo | Valor |
|---|---|
| Versão | 0.3 (auditoria: lacuna de gatilhos, IDs de módulo, bloqueio fiscal, papéis, LGPD) |
| Data | 2026-11-08 |
| Status | Aguardando aprovação do nome, dos preços e do roadmap |
| Fonte | [`docs/briefing-original.md`](./briefing-original.md) · [`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md) · [`PILOTO-DEMO.md`](./PILOTO-DEMO.md) |
| Próximo passo | Aprovar o plano de negócio e iniciar a R0 (seção 15) |

> **Como ler este documento.** As seções 1 a 3 trazem o porquê. A seção 4 lista o que foi
> **decidido por padrão** (e pode mudar) e o que **ainda precisa de você**. As seções 5 a 11
> trazem o quê: escopo, fluxos, requisitos e regras. As seções 12 a 14 trazem o como:
> arquitetura e dados. A seção 15 é o roadmap (releases R0 a R4).
>
> Convenções: `RF-xx` = requisito funcional, `RN-xx` = regra de negócio, `RNF-xx` =
> requisito não funcional. **[R1]** a **[R4]** indicam a release em que o item entra (seção 15).

---

## 1. Resumo executivo

Um sistema operacional enxuto para pizzarias: **link próprio de pedidos**, **painel de
operação** (pedidos, status, caixa) e um **CRM que trabalha sozinho**. Todo pedido alimenta
o histórico do cliente. Toda noite, o sistema transforma esse histórico numa lista curta de
**oportunidades em linguagem simples** ("37 clientes estão perto de 30 dias sem pedir"), cada
uma com uma **mensagem pronta e personalizada**. O dono revisa e envia em poucos toques.
O sistema então **mede quantos desses clientes voltaram a comprar**.

O ciclo que o produto precisa fechar, e provar com números, é:

```
PEDIDO → HISTÓRICO → INTELIGÊNCIA → OPORTUNIDADE → CAMPANHA → NOVO PEDIDO (atribuído)
```

**Produto:** um **ERP vertical para pizzarias, entregue como SaaS por assinatura**, contratado
por **plano + módulos** (seção 5 e [`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md)), pronto
para 100+ pizzarias desde o lançamento (seção 12.5). O CRM inteligente continua sendo o
diferencial; o restante do ERP existe para que a pizzaria rode **tudo** num lugar só.

**Tese da primeira release:** uma pizzaria pequena ou média, sem ninguém de marketing, troca
o sistema atual pelo Fornalia e recupera clientes inativos usando apenas o que o sistema sugere.

---

## 2. Problema, visão e princípios

### 2.1 Problema
- O dono não tem tempo nem formação para ler relatórios. Os dados existem, mas ninguém age sobre eles.
- Depender de marketplaces custa comissão e **esconde o cliente**: a pizzaria não fica com
  o contato nem com o histórico de quem compra por lá.
- Pedidos chegam por WhatsApp, telefone e balcão, cada um num lugar diferente. Há redigitação e erro.
- Ninguém percebe quando um cliente fiel some, e quando alguém percebe já é tarde.

### 2.2 Visão
> **O sistema pensa pelo dono da pizzaria e mostra o que merece atenção hoje.**

### 2.3 Princípios de produto (filtro para toda decisão)
| # | Princípio | Implicação prática |
|---|---|---|
| P1 | Simplicidade acima de quantidade de funcionalidades | Uma função só entra numa release se aquela release não for vendável sem ela |
| P2 | Ação acima de relatório | Nenhum número na tela sem uma frase explicando o que ele significa e qual ação fazer |
| P3 | Automação com controle | O sistema sugere e prepara; **nenhuma mensagem sai sem um humano aprovar** |
| P4 | Personalização baseada em fatos | A mensagem só cita o que está no histórico. Nada inventado, nenhuma promessa que a pizzaria não fez |
| P5 | Operação integrada | Pedido do link cai pronto no painel, sem redigitação |
| P6 | Linguagem comum | "Clientes que sumiram", não "churn". "Valor médio do pedido", não "ticket médio" (na UI) |
| P7 | Medir o resultado | Toda campanha registra o contato e mostra se o cliente voltou |

### 2.4 O que o produto NÃO é
- Não é um ERP genérico: é um ERP **vertical** para pizzarias. A profundidade fica nos módulos; a tela continua simples.
- Não é um painel de dashboards para acompanhar todo dia.
- Não é ferramenta de disparo em massa nem de spam.
- Não é marketplace: cada pizzaria tem seu próprio link e sua própria marca.

---

## 3. Personas e trabalhos a realizar

| Persona | Contexto | Trabalho principal | Medo |
|---|---|---|---|
| **Dono(a)** | Trabalha na operação, olha o sistema no celular nos intervalos | "Me diga o que fazer para vender mais hoje" | Perder tempo com sistema complicado; incomodar cliente com mensagem |
| **Atendente / caixa** | Rush das 19h às 22h, várias coisas ao mesmo tempo | Registrar e acompanhar pedidos sem errar; fechar o caixa sem diferença | Pedido perdido, pedido errado, caixa que não bate |
| **Cozinha** | Mãos ocupadas, olha a tela ou a comanda impressa | Saber o que preparar e em que ordem | Pedido que chegou e ninguém viu |
| **Cliente final** | Pede pelo celular, geralmente vindo do WhatsApp ou do Instagram | Pedir rápido, saber o preço com frete antes de fechar, acompanhar o pedido | Formulário longo; não saber quando a pizza chega |
| **Entregador** [R2] | Na rua | Saber endereço, valor e forma de pagamento | Endereço errado; troco errado |

---

## 4. Decisões

### 4.1 Decisões assumidas por padrão
As 12 perguntas da seção 12 do briefing receberam uma resposta padrão para o PRD poder
avançar. **Toda linha pode ser mudada.** A coluna "Custo de mudar depois" diz o quanto
dói trocar a decisão depois de construído.

| # | Questão do briefing | Decisão padrão | Por quê | Custo de mudar depois |
|---|---|---|---|---|
| D1 | Delivery, retirada ou ambos? | **Ambos**, mais pedido de balcão/telefone lançado pela equipe | Cobre o dia a dia real; retirada não tem frete, então é barata de incluir | Baixo |
| D2 | Regra de frete | **Por bairro** (tabela bairro → taxa + tempo extra), com CEP autopreenchendo o endereço | É o modelo mais comum em pizzaria, não precisa de mapa nem de API paga, e o dono entende | Médio: distância/raio entra na R2 sem refazer o pedido |
| D3 | Status do pedido | **Novo → Em preparo → Pronto → Saiu para entrega / Aguardando retirada → Concluído**, mais **Cancelado** | Mínimo que a cozinha e o balcão precisam; ver seção 9 | Baixo |
| D4 | Caixa | **Caixa simples:** abertura com troco, recebimentos por forma de pagamento, sangria/suprimento, fechamento com conferência. Sem conciliação bancária | A aba "Caixa" está na navegação principal do briefing; conciliação é ERP | Baixo |
| D5 | Pagamento no link | Pagamento na entrega/retirada (dinheiro com troco, cartão na maquininha, Pix na entrega) **e Pix online via Mercado Pago já na R1** (planos Profissional/Premium ou módulo avulso) | Revisto na v0.2: Pix online é esperado pelo cliente final; webhook idempotente obrigatório | Médio |
| D6 | Cliente acompanha o pedido? | **Sim**, por uma página de status (link recebido ao finalizar), sem login | Corta as ligações de "cadê minha pizza" e custa pouco | Baixo |
| D7 | Canal das campanhas | **R1: WhatsApp via link `wa.me`** com a mensagem preenchida; o atendente confere e envia no próprio WhatsApp. **R4: WhatsApp Business API** oficial para envio automático | Custo zero, sem credencial, sem risco de bloqueio do número, e atende o P3 (humano aprova) | Médio: a API oficial é paga por conversa, exige templates aprovados e opt-in formal |
| D8 | Consentimento e descadastro | **Opt-in explícito** no checkout (caixa desmarcada) e no cadastro de balcão; opt-out a qualquer momento pelo painel ou por pedido do cliente; registro de quando, onde e como | LGPD: mensagem promocional exige base legal; consentimento é a mais segura | Alto se for ignorado: retroativo é impossível |
| D9 | Limite de frequência | No máximo **1 contato promocional a cada 7 dias** e **4 a cada 30 dias** por cliente (configurável) | Evita a sensação de spam e protege o número de WhatsApp da pizzaria | Baixo |
| D10 | Identificação do cliente | **Celular (formato E.164) como chave única por pizzaria**; mesclagem manual de duplicados [R2] | O telefone é o que o cliente sempre informa e é por onde a campanha chega | Alto: é a espinha do CRM |
| D11 | Unidades, usuários e permissões | **Multi-pizzaria (SaaS) no modelo de dados desde o início**, 1 loja por pizzaria na R1 (multi-loja na R4); papéis por release na seção 12.4 | Isolar por pizzaria desde o dia 1 custa pouco; adaptar depois custa uma reescrita | Alto: por isso já entra no MVP |
| D12 | Indicadores para o dono | No máximo **4 números** no "Resumo de hoje", cada um com uma frase de leitura (seção 8, M7) | P2: ação acima de relatório | Baixo |

### 4.2 Decisões tomadas na v0.2 (respostas às perguntas Q1 a Q6)
| # | Pergunta | Decisão | Efeito no PRD |
|---|---|---|---|
| Q1 | Assinatura ou sob medida? | **Assinatura (SaaS multi-pizzaria)**, contratada **por plano + módulos**, para **100+ pizzarias e 200 a 300+ usuários desde o início** | Plataforma SaaS completa na R1 (cadastro, cobrança, módulos, painel master, suporte); escalabilidade na seção 12.5 |
| Q2 | Pizzaria piloto | **Não há.** O piloto é a pizzaria fictícia **Forno da Vila (DEMO)**, com dados gerados | [`PILOTO-DEMO.md`](./PILOTO-DEMO.md) e `demo/gerar_dados_demo.py` |
| Q3 | Preço | Planos Essencial / Profissional / Premium + módulos avulsos | [`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md) |
| Q4 | Nome e marca | Recomendado **Fornalia, by Contera** (pendente de checagem no INPI e de domínio) | Plano de negócio, seção 2 |
| Q5 | iFood | **Módulo pago opcional: iFood e 99Food** (pacote marketplaces) | Módulo M14 e seção 12.7 |
| Q6 | Impressora térmica | Sem piloto físico. Impressão pelo navegador na R1; agente local para impressoras ESC/POS na R2 | M04 |
| — | Escopo | **ERP completo para pizzarias**, premium, simples de usar | Seção 5 (catálogo de módulos e lacunas) |

**Ajustes nas decisões da 4.1:** D5 passa a ser **Pix online já na R1** (planos Profissional e
Premium); D11 está confirmada e ampliada (multi-pizzaria + multi-loja na R4).

---

## 5. Catálogo de módulos do ERP e releases

### 5.1 Análise de lacunas: o que a v0.1 não tinha e um ERP completo precisa
| Lacuna | Por que importa para uma pizzaria | Módulo |
|---|---|---|
| Plataforma SaaS (cadastro self-service, cobrança da assinatura, módulos, painel master, suporte) | Sem isso não há como vender para 100+ pizzarias | M01 |
| **Fiscal (NFC-e/NF-e)** | A maioria das pizzarias **precisa emitir nota** na venda. Sem fiscal, o dono mantém outro sistema e não migra | M12 |
| Financeiro com conciliação automática | Contas, fluxo de caixa, DRE, taxa de cartão cobrada a mais, recebível que não caiu | M13 |
| Marketplaces (iFood, 99Food) | Grande parte dos pedidos chega por eles; redigitar gera erro | M14 |
| Estoque de insumos, ficha técnica e CMV | Pizzaria vive de margem; sem CMV o dono não sabe quanto ganha por pizza | M15 |
| Compras e fornecedores | Fecha o ciclo do estoque e do custo | M16 |
| Salão, mesas e comandas | Muitas pizzarias têm consumo no local | M17 |
| Tela de cozinha (KDS) | Organiza a produção no pico; substitui papel | M09 |
| Entregadores e despacho | Agrupar entregas, acerto com motoboy, rastreio | M10 |
| Fidelidade e cupons | Complementa o CRM: dá motivo para o cliente voltar | M11 |
| Contingência offline | Internet cai no pico; o balcão não pode parar | M22 |
| Multi-loja e franquia | Redes e donos com mais de uma unidade | M19 |
| Relatórios avançados e engenharia de cardápio | Saber quais sabores dão lucro, não só volume | M18 |
| IA (previsão de demanda, sugestão de compra, copiloto) | Diferencial premium e inovador | M21 |
| WhatsApp oficial e robô de pedidos | Automação em escala, após comprovar o CRM | M20 |
| API pública, TEF/maquininha, autoatendimento | Ecossistema e operação sem atrito | M23, M24 |
| Equipe (permissões finas, escala, comissões) | Controle de quem faz o quê; comissão de garçom/entregador | M25 |

### 5.2 Catálogo de módulos
Planos: **E** = Essencial, **P** = Profissional, **Pr** = Premium, **+** = módulo avulso.
Preços em [`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md).

| ID | Módulo | Inclui | Planos | Release |
|---|---|---|---|---|
| M01 | **Plataforma SaaS** | Cadastro self-service, teste grátis com loja demo, assinatura (cartão recorrente e Pix via Mercado Pago) com aviso de vencimento e cobrança, direitos por módulo, usuários e papéis, MFA, auditoria, painel master Contera, suporte in-app (chamados), central de ajuda, backup, LGPD | Todos | R1 |
| M02 | Cardápio e configuração | Seção 8, M02 | Todos | R1 |
| M03 | Link de pedidos | Cardápio digital, construtor de pizza, frete, página de status; **Pix online** | Todos (Pix: P, Pr, +) | R1 |
| M04 | Pedidos e operação | Fila em tempo real, balcão/telefone, status, comanda pelo navegador; agente de impressão ESC/POS automática na R2 | Todos | R1 |
| M05 | PDV e caixa | Pagamentos mistos, troco, sangria/suprimento, **fechamento cego** (o operador conta sem ver o valor esperado); vários pontos de venda na R2 | Todos | R1 |
| M06 | Clientes e histórico | Seção 8, M06 | Todos | R1 |
| M07 | **CRM inteligente e campanhas** | Seções 10 e 11.6 | P, Pr, + | R1 |
| M08 | Resumo do dia | Seção 8, M08 | Todos | R1 |
| M12 | **Fiscal** | NFC-e e NF-e, contingência, cancelamento e inutilização, certificado A1 cifrado, campos da reforma tributária (CBS/IBS) | Pr, + | **R1** |
| M09 | Tela de cozinha (KDS) | Praças (forno, montagem, bebidas), tempos por etapa, alerta de atraso | P, Pr | R2 |
| M10 | Delivery e entregadores | Despacho, agrupamento por rota, acerto com entregador, link de rastreio | P, Pr | R2 |
| M11 | Cupons e fidelidade | Cupom por campanha, pontos ou cashback, indicação | P, Pr, + | R2 |
| M13 | **Financeiro + conciliação automática** | Contas a pagar/receber, fluxo de caixa, DRE gerencial, centros de custo, conciliação bancária (Open Finance ou OFX) e de cartões (taxas, recebíveis, chargebacks), exportação para o contador | Pr, + | R2 |
| M14 | **Marketplaces** | iFood e 99Food: pedido entra direto na operação, status sincronizado; sincronização de cardápio na R3 | + | R2 |
| M15 | Estoque, ficha técnica e CMV | Baixa automática por venda (inclusive por fração de sabor), inventário, perdas, estoque mínimo | Pr, + | R3 |
| M16 | Compras e fornecedores | Pedido de compra, entrada por XML da NF-e, custo médio, sugestão de compra | Pr | R3 |
| M17 | Salão e mesas | Mapa de mesas, comanda por mesa, app do garçom, divisão de conta, taxa de serviço, QR na mesa | Pr, + | R3 |
| M18 | Relatórios e engenharia de cardápio | Curva ABC, margem por sabor, matriz popularidade × margem, vendas por hora | Pr | R3 |
| M22 | Contingência offline | Pedidos e caixa funcionam sem internet e sincronizam depois, sem duplicar | Todos | R3 |
| M19 | Multi-loja e franquia | Cardápio central, preço por loja, relatórios consolidados, transferência de estoque | + | R4 |
| M20 | WhatsApp oficial e robô de pedidos | API oficial, notificações automáticas de status, campanhas com opt-in formal | + | R4 |
| M21 | IA | Previsão de demanda (massa, insumos, equipe), sugestão de compra, copiloto em linguagem natural, texto de campanha com trava de fatos | Pr | R4 |
| M23 | API pública e integrações | API e webhooks documentados, TEF/maquininha integrada | Pr, + | R4 |
| M24 | Autoatendimento | Totem e pedido pela mesa com pagamento | + | R4 |
| M25 | Equipe | Permissões finas, escala, comissões | P, Pr | R4 |

**Fora do escopo do produto:** folha de pagamento e contabilidade completa (atribuições do
contador; o M13 exporta os dados para ele) e venda de produtos fora do food service.

---

## 6. Navegação e experiência

### 6.1 Painel interno (PWA instalável no celular e no computador)
```
[ Pedidos ]  [ Caixa ]  [ Clientes ]  [ Oportunidades (•3) ]        ⚙ Configurações
```
- **Tela inicial:** durante o horário de funcionamento, abre em **Pedidos**. Fora dele, abre
  em **Oportunidades**. Sempre há um selo com quantas oportunidades estão abertas.
- **Oportunidades** é a central de ações. No topo fica o **Resumo de hoje** (M7). Logo abaixo,
  os **cartões agrupados por motivo**, do mais importante para o menos importante.
- **Configurações** fica fora da navegação principal: é usada na implantação, não no dia a dia.
- **Módulos de gestão** (Financeiro, Estoque, Compras, Fiscal, Salão, Entregas, Relatórios)
  ficam num segundo nível, **Gestão**, e só aparecem se o módulo estiver ligado e o papel do
  usuário puder vê-lo. A barra principal continua com 4 itens: o atendente nunca vê um menu de ERP.

### 6.2 Metas de experiência (critérios testáveis)
| Meta | Critério |
|---|---|
| Lançar um pedido de balcão | ≤ 60 s para um atendente treinado, com cliente já cadastrado |
| Do cartão de oportunidade ao WhatsApp aberto com a mensagem | **≤ 3 toques** |
| Cliente final do link até pedido enviado | ≤ 2 min num celular comum, em 4G |
| Novo pedido online aparece no painel | ≤ 5 s, com alerta sonoro |
| Entender uma oportunidade | Frase única, sem jargão, testada com o dono da pizzaria piloto |

### 6.3 Diretrizes de interface
- Linguagem do dono, nunca de analista (P6). Glossário da UI no apêndice A.
- Botões grandes, pensados para celular e para tela de toque no balcão.
- Ações destrutivas (cancelar pedido, fechar caixa) pedem confirmação e explicam o efeito.
- Nenhum gráfico na R1. Os gráficos do M18 (R3) também vêm sempre acompanhados de uma frase de leitura.
- Selo discreto do fabricante ("by Contera") no rodapé do login e na tela Sobre. A marca principal é a da pizzaria.

---

## 7. Fluxos de ponta a ponta

### 7.1 Pedido pelo link (cliente final)
1. O cliente abre `dominio/<slug-da-pizzaria>`. Se a loja estiver fechada ou pausada, o
   cardápio aparece, mas com o aviso "Fechado agora: abre às 18h" e sem botão de finalizar.
2. Monta a pizza: **tamanho → sabores** (até o máximo do tamanho) **→ borda/adicionais → observação**.
   O preço é recalculado a cada escolha (RN-03).
3. Adiciona bebidas e outros itens. O carrinho mostra o subtotal.
4. Informa o **celular** (primeiro campo). Se o número já é conhecido **neste aparelho**, os
   dados são preenchidos ("Bem-vinda de volta, Maria"). Ver RN-12 sobre privacidade.
5. Escolhe **Entrega** (informa o CEP, o endereço é autopreenchido e confirmado, o bairro
   define o frete) ou **Retirada**.
6. Escolhe a forma de pagamento (e o troco, se for dinheiro).
7. Marca, se quiser, a caixa "Quero receber novidades e promoções pelo WhatsApp" (desmarcada por padrão).
8. Revisa (itens, frete, total, tempo estimado) e envia.
9. O servidor **recalcula tudo** (RN-04), cria o pedido e devolve o **link de acompanhamento**.
10. A página de status mostra a etapa atual e um botão "Falar com a pizzaria" (`wa.me`).

### 7.2 Pedido de balcão/telefone (atendente)
1. Em Pedidos, toca em **Novo pedido**, digita o celular e o sistema encontra ou cria o cliente.
2. Monta os itens com o mesmo construtor de pizza do link.
3. Escolhe entrega (endereço salvo ou novo) ou retirada/consumo no local.
4. Escolhe a forma de pagamento. O pedido entra direto em **Em preparo** (pedido de balcão não precisa de aceite).
5. Pedido sem telefone é permitido ("cliente não identificado"), mas o sistema avisa:
   "Sem telefone, esse pedido não entra no histórico do cliente."

### 7.3 Operação do pedido
Ver a máquina de estados na seção 9. Na fila, cada pedido mostra número, há quantos minutos
chegou, tipo (entrega/retirada), bairro, total e forma de pagamento. Um pedido parado em
**Novo** por mais de 3 min (configurável) fica destacado e repete o alerta.

### 7.4 Caixa
1. **Abrir caixa:** o operador informa o troco inicial (obrigatório, pode ser R$ 0,00).
2. Durante o turno, todo pagamento recebido é lançado no caixa aberto, por forma de pagamento.
3. **Sangria** (retirada) e **suprimento** (reforço) com valor e motivo.
4. **Fechar caixa:** o sistema mostra o **dinheiro esperado na gaveta** (RN-21). O operador
   informa o valor contado e o sistema mostra a diferença. Cartão e Pix aparecem separados,
   com o rótulo "não fica na gaveta".

### 7.5 Oportunidade → campanha → nova venda (o coração do produto)
1. **De madrugada (entre 03:00 e 06:00, horário de Brasília, escalonado por loja; AD-12):** o motor recalcula as métricas dos clientes e gera as oportunidades do dia (seção 10).
2. O dono abre **Oportunidades** e vê, por exemplo:
   > **47 clientes passaram de 25 dias sem pedir.** Normalmente pediam a cada 2 a 5 semanas.
   > [Ver e enviar mensagens]
3. Ao abrir o cartão, vê a lista ordenada por importância. Cada linha tem nome, motivo,
   contexto ("Costuma pedir Calabresa com Mussarela, geralmente às sextas") e a mensagem pronta.
4. Toca em **Enviar**. O WhatsApp abre com o texto preenchido, ele confere e envia.
   O sistema registra o contato e passa para o próximo cliente (modo sequência).
   Também pode **editar** o texto antes ou **descartar** a oportunidade, com motivo opcional.
5. Se o cliente fizer um pedido em até **7 dias** depois do contato, o pedido é **atribuído à
   campanha** (RN-41). O Resumo de hoje mostra: "Mensagens desta semana trouxeram 9 pedidos (R$ 812)".
6. A nova compra atualiza o histórico, a oportunidade é encerrada e o ciclo recomeça.

---

## 8. Requisitos funcionais por módulo (R1)
Os IDs são os do catálogo da seção 5.2. Os módulos das releases R2 a R4 ganham sua seção de
requisitos no início de cada release.

### M02. Cardápio e configuração
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-01 | Cadastrar **categorias** (Pizzas, Doces, Bebidas, ...) com ordem de exibição | A ordem definida é a do cardápio público |
| RF-02 | Cadastrar **tamanhos** de pizza com nome, nº de fatias e **máximo de sabores** | Exemplo: Broto (1 sabor), Grande (2), Família (3) |
| RF-03 | Cadastrar **sabores** com descrição, foto opcional e **preço por tamanho** | Sabor sem preço num tamanho não aparece nesse tamanho |
| RF-04 | Cadastrar **grupos de adicionais** (borda, extras) com mínimo/máximo de escolha e preço por tamanho | O link respeita o mínimo e o máximo |
| RF-05 | Cadastrar **produtos simples** (bebidas, porções) com preço | — |
| RF-06 | **Ativar/desativar** item sem apagar ("acabou a massa de chocolate") | O item some do link na hora; o histórico continua com o nome dele |
| RF-07 | **Horários** por dia da semana, com mais de um turno por dia | O link mostra "Fechado" fora do horário |
| RF-08 | **Bairros atendidos** com taxa e tempo extra; opção "bairro não listado: não entregamos" | — |
| RF-09 | **Pedido mínimo** para entrega (opcional) | O link bloqueia o envio abaixo do mínimo e explica o motivo |
| RF-10 | **Formas de pagamento** aceitas (dinheiro, Pix na entrega, débito, crédito, vale-refeição) | Só as ativas aparecem no link |
| RF-11 | **Tempo estimado** de entrega/retirada, ajustável na hora pelo painel | Mostrado no link e na página de status |
| RF-12 | **Pausar pedidos online** com um toque ("cozinha cheia") | O link exibe aviso e bloqueia o envio; balcão segue funcionando |
| RF-13 | Dados da loja: nome, logo, cor de destaque, endereço, WhatsApp, slug do link | O slug é único na plataforma |
| RF-14 | Regra de preço de pizza com vários sabores: **maior preço** (padrão) ou **média** | Ver RN-03 |

### M03. Link de pedidos
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-20 | Cardápio público por slug, sem login, mobile-first | Abre em ≤ 2,5 s (LCP) em 4G |
| RF-21 | Construtor de pizza (tamanho → sabores → adicionais → observação) | Não deixa passar do máximo de sabores; mostra o preço ao vivo |
| RF-22 | Carrinho com editar/remover e subtotal | — |
| RF-23 | Identificação por celular com máscara brasileira | Número inválido bloqueia o avanço com mensagem clara |
| RF-24 | Endereço com CEP autopreenchido (ViaCEP) e edição manual | Falha do ViaCEP não bloqueia: o cliente digita o endereço |
| RF-25 | Frete calculado pelo bairro; bairro não atendido avisa e oferece retirada | — |
| RF-26 | Revisão final com itens, frete, total, pagamento e tempo estimado | — |
| RF-27 | Caixa de consentimento para promoções, **desmarcada por padrão** | O registro guarda data, origem e texto exibido (RN-50) |
| RF-28 | Página de status do pedido por link com token não adivinhável | Mostra a etapa atual; atualiza sozinha a cada ≤ 15 s |
| RF-29 | Proteção contra pedido duplicado (duplo clique, rede ruim) | Ver RN-05 |

### M04. Pedidos e operação
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-30 | Fila de pedidos em tempo real, agrupada por status | Pedido novo aparece em ≤ 5 s, com som |
| RF-31 | Alerta sonoro repetido para pedido em "Novo" sem aceite | Repete a cada 30 s até alguém tocar no pedido |
| RF-32 | Aceitar / avançar status com um toque | Transições válidas na seção 9 |
| RF-33 | Cancelar com motivo obrigatório | Ver RN-31 |
| RF-34 | Pedido de balcão/telefone (fluxo 7.2) | — |
| RF-35 | Imprimir comanda (80 mm) pelo navegador | Layout legível numa térmica de 80 mm; inclui observações em destaque |
| RF-36 | Detalhe do pedido: itens, observações, endereço, pagamento, troco, histórico de status | — |
| RF-37 | Botão de WhatsApp para falar com o cliente sobre o pedido | Abre `wa.me` com "Olá {nome}, sobre seu pedido #{numero}..." |

### M05. PDV e caixa
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-40 | Abrir caixa com troco inicial obrigatório | Um caixa aberto por ponto de venda; vários pontos de venda por loja na R2 |
| RF-41 | Registrar pagamento do pedido (forma, valor, troco) | Pagamento em mais de uma forma é permitido ("metade Pix, metade dinheiro") |
| RF-42 | Sangria e suprimento com motivo | Registro imutável; correção só por lançamento inverso |
| RF-43 | Fechar caixa com contagem obrigatória | Botão desabilitado enquanto a contagem estiver vazia (RN-22) |
| RF-44 | Resumo do fechamento por forma de pagamento | Separa "na gaveta" de "fora da gaveta" |

### M06. Clientes e histórico
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-50 | Cliente criado ou atualizado automaticamente a cada pedido com celular | Nunca dois clientes com o mesmo celular na mesma pizzaria |
| RF-51 | Ficha do cliente: dados, endereços, consentimento, linha do tempo de pedidos e contatos | — |
| RF-52 | **"O que sabemos sobre este cliente"** em frases: "Pede a cada ~12 dias", "Favorito: Calabresa", "Costuma pedir às sextas, à noite", "Último pedido há 29 dias" | Só aparece o que tem base mínima (seção 10.2) |
| RF-53 | Busca por nome ou telefone | Resultado em ≤ 1 s |
| RF-54 | Filtros prontos (sem montar filtro): Novos, Frequentes, VIP, Sumindo, Inativos | Os mesmos segmentos da seção 10.2 |
| RF-55 | **Importar clientes** por planilha (CSV: nome, celular, data de nascimento, data da última compra opcional) | Relatório de importação: X novos, Y atualizados, Z inválidos com motivo |
| RF-56 | Data de nascimento opcional | Usada só no gatilho de aniversário |
| RF-57 | Opt-out com um toque ("não quer mais receber") | Remove o cliente de todas as oportunidades de campanha |
| RF-58 | Exportar/excluir os dados de um cliente a pedido dele (LGPD) | Exclusão = anonimização; o pedido continua no caixa e no histórico sem dados pessoais |

### M07a. Motor de oportunidades
Ver seção 10 (é a especificação completa).

### M07b. Campanhas
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-60 | Mensagem sugerida por modelo + dados do cliente | Só usa variáveis com valor; nunca exibe `{sabor_favorito}` vazio (RN-46) |
| RF-61 | 2 a 3 variações de texto por gatilho; o dono escolhe uma e pode editar | O texto editado vale só para aquele envio, ou vira o novo modelo se ele quiser |
| RF-62 | Enviar via `wa.me` e registrar o contato | O contato é registrado ao tocar em Enviar; o atendente pode marcar "não enviei" |
| RF-63 | Modo sequência: após enviar, abre o próximo cliente do grupo | Mostra o progresso ("4 de 12") |
| RF-64 | Descartar oportunidade com motivo opcional | O cliente não volta para o mesmo gatilho por 14 dias |
| RF-65 | Resultado: contatados, voltaram a pedir, valor trazido | Por gatilho e no total; regra de atribuição RN-41 |
| RF-66 | Editar modelos de mensagem em Configurações, com prévia | Variáveis documentadas na tela |

### M08. Resumo de hoje
| ID | Requisito | Critério de aceite |
|---|---|---|
| RF-70 | Até 4 indicadores com frase: **Pedidos hoje** (vs. mesmo dia da semana passada), **Vendas hoje**, **Valor médio do pedido**, **Resultado das mensagens (7 dias)** | Toda linha é uma frase completa, ex.: "Hoje: 48 pedidos, 6 a mais que na sexta passada" |
| RF-71 | "O que merece atenção": até 3 itens | Ex.: "3 clientes VIP estão sumindo"; "Caixa de ontem fechou com R$ 20 a menos" |

---

## 9. Máquina de estados do pedido

```
            aceitar                pronto            despachar
  [Novo] ───────────► [Em preparo] ─────► [Pronto] ──────────► [Saiu p/ entrega] ──┐
    │                     │                  │   └─(retirada)► [Aguardando retirada]┤
    │                     │                  │                                       ▼
    └──── cancelar ───────┴──── cancelar ────┘                                [Concluído]
                    ▼
               [Cancelado]
```

| De → Para | Quem | Regra |
|---|---|---|
| Novo → Em preparo | Atendente/Dono | Pedido de balcão já nasce em Em preparo. Aceite automático do online é configurável [R2] |
| Em preparo → Pronto | Atendente/Dono | — |
| Pronto → Saiu para entrega | Atendente/Dono | Só pedidos de entrega |
| Pronto → Aguardando retirada | Atendente/Dono | Só pedidos de retirada |
| Saiu / Aguardando → Concluído | Atendente/Dono | **Concluído** é o evento que alimenta o CRM (RN-30) |
| Novo / Em preparo / Pronto → Cancelado | Atendente/Dono | Motivo obrigatório. Depois de Saiu para entrega, só o Dono cancela |
| Concluído → qualquer outro | — | **Proibido.** Correção só por estorno/ajuste registrado |

Toda transição grava quem fez, quando e de qual status saiu (`order_status_history`).
O banco recusa transições fora da tabela, não só a tela.

---

## 10. Motor de oportunidades (especificação)

### 10.1 Métricas por cliente (recalculadas a cada pedido concluído e toda madrugada)
Consideram **apenas pedidos Concluídos** e a data no fuso `America/Sao_Paulo`.

| Métrica | Definição |
|---|---|
| `pedidos_total` | Nº de pedidos concluídos |
| `primeiro_pedido_em`, `ultimo_pedido_em` | Datas do primeiro e do último pedido concluído |
| `dias_sem_pedir` | Hoje (data de Brasília) − data do último pedido |
| `intervalo_habitual_dias` | **Mediana** dos intervalos entre pedidos consecutivos dos **últimos 12 meses**. Exige ≥ 3 pedidos; senão fica nulo |
| `total_gasto_cents`, `gasto_180d_cents` | Soma dos totais (geral e últimos 180 dias) |
| `valor_medio_cents` | `total_gasto_cents / pedidos_total` |
| `sabores_favoritos` | Top 2 sabores por frequência nos últimos 12 meses; pizza meio a meio conta 0,5 para cada sabor. Exige o sabor em ≥ 2 pedidos |
| `dia_preferido`, `turno_preferido` | Dia da semana / turno com ≥ 50% dos pedidos, se `pedidos_total ≥ 4` |
| `bairro` | Bairro do último endereço de entrega |
| `segmento` | Ver 10.2 |

### 10.2 Segmentos (exclusivos, avaliados nesta ordem; VIP é uma marca à parte)
| Segmento (nome na UI) | Regra padrão (configurável) |
|---|---|
| **VIP** | Entre os 10% maiores `gasto_180d` da pizzaria **e** ≥ 5 pedidos nos 180 dias. É uma marca que se soma aos demais segmentos |
| **Perdido** | `dias_sem_pedir > 180` |
| **Inativo** | `dias_sem_pedir` entre 60 e 180 |
| **Sumindo** | Tem `intervalo_habitual` e `dias_sem_pedir ≥ max(2 × intervalo, intervalo + 7)`, **ou** não tem intervalo e `dias_sem_pedir` entre 25 e 59 |
| **Novo** | `pedidos_total = 1` e `dias_sem_pedir < 25` |
| **Frequente** | ≥ 4 pedidos nos últimos 90 dias |
| **Recorrente** | Os demais clientes com ≥ 2 pedidos |

### 10.3 Gatilhos da R1
| # | Gatilho (texto do cartão) | Condição | Por que importa | Prioridade |
|---|---|---|---|---|
| G1 | "**{n} clientes passaram de 25 dias sem pedir**" | `dias_sem_pedir` entre 25 e 59, `pedidos_total ≥ 2` | Exemplo central do briefing ("perto de 30 dias"). Vai até 59 para **não haver buraco até o G4**: na v0.2 (25 a 30), quem passava da janela ficava invisível até 60 dias (37 clientes na base demo) | Alta |
| G2 | "**{n} clientes frequentes saíram do ritmo**" | Tem `intervalo_habitual ≤ 21` e `dias_sem_pedir ≥ max(2 × intervalo, intervalo + 7)` e `< 60` | Perder um cliente frequente custa caro; o sinal vem antes do "30 dias" | Alta |
| G3 | "**{n} clientes pediram uma vez e não voltaram**" | `pedidos_total = 1` e `dias_sem_pedir` entre 10 e 59 (sem buraco até o G4) | A segunda compra é a que mais define se o cliente fica | Média |
| G4 | "**{n} clientes não pedem há mais de 60 dias**" | `dias_sem_pedir` entre 60 e 180; no máximo 1 tentativa por ciclo de inatividade | Reconquista; conversão menor, por isso vem depois | Média |
| G5 | "**{n} clientes fazem aniversário nos próximos dias**" | `data_nascimento` entre hoje e hoje + 3 dias; 1 vez por ano | Contato bem recebido, raramente visto como spam | Média |
| G6 [R2] | "**Hoje é o dia de pedir de {n} clientes**" | Hoje = `dia_preferido` e não pediu nesta semana e `dias_sem_pedir ≥ 1,5 × intervalo` | Lembrete na hora certa | Baixa |
| G7 [R2] | "**{n} clientes VIP merecem um agradecimento**" | VIP sem contato há 30 dias e sem gatilho de risco | Fidelização | Baixa |

**Cobertura sem buracos:** todo cliente com consentimento e 10 a 180 dias sem pedir cai em
exatamente um gatilho. Os testes de fronteira (24/25, 59/60, 180/181 dias; 9/10 para compra
única; `2 × intervalo` para G2) rodam a cada execução do gerador demo.

**VIP** não é um gatilho próprio na R1: um cliente VIP sobe para o **topo** da lista de qualquer gatilho em que aparecer.

### 10.4 Elegibilidade (só depois disso o cliente entra numa oportunidade)
Um cliente **só** é elegível se **todas** as condições forem verdadeiras:
1. Tem celular válido.
2. Tem **consentimento de marketing ativo** e **não pediu opt-out** (RN-50 a RN-53).
3. Não recebeu contato promocional nos últimos **7 dias** e recebeu menos de **4** nos últimos 30 (D9).
4. Não tem pedido em andamento.
5. Não tem outra oportunidade aberta (um cliente aparece em **um** cartão por vez: o de maior prioridade).
6. Não descartou este mesmo gatilho nos últimos 14 dias.

Clientes que cumprem a condição de um gatilho mas **não têm consentimento** são contados à
parte: "Mais 8 clientes estão nessa situação, mas não autorizaram mensagens." Assim o dono
entende por que vale pedir o consentimento.

### 10.5 Ordem, expiração e encerramento
- **Ordem dos cartões:** prioridade do gatilho e depois a soma do valor médio dos clientes do cartão.
- **Ordem dentro do cartão:** VIP primeiro e depois `gasto_180d` decrescente.
- **Expiração:** a oportunidade fica aberta por **3 dias**. Depois disso some sem penalidade e
  pode voltar se a condição continuar valendo.
- **Encerramento automático:** se o cliente fizer um pedido, a oportunidade fecha como
  "**Voltou sozinho**". Esse resultado não conta como conversão de campanha.
- **Limite diário:** no máximo **30 clientes por cartão** por dia (configurável). Mais que isso
  e o dono não dá conta; a lista é a mais valiosa, não a completa.
- **Melhor horário:** o cartão sugere enviar **antes do pico** (padrão: até 1 h antes da
  abertura do turno da noite), e não durante o rush.

### 10.6 Explicação em linguagem simples (exemplos de saída)
| Dado técnico | Frase na tela |
|---|---|
| `dias_sem_pedir=29; intervalo=14; fav=[Calabresa]` | "Maria José não pede há 29 dias. Antes pedia a cada duas semanas, quase sempre **Calabresa com Mussarela**." |
| `pedidos_total=1; dias=18` | "João pediu uma vez, há 18 dias, e não voltou. A segunda compra é a mais importante." |
| `VIP; intervalo=7; dias=19` | "**Cliente VIP:** Ana pedia toda semana e está há 19 dias sem pedir." |

### 10.7 Mensagens (modelos)
- Modelos por gatilho com variáveis: `{primeiro_nome}`, `{pizzaria}`, `{sabor_favorito}`,
  `{dia_preferido}`, `{link_pedido}`.
- **Regra de fato (RN-46):** se uma variável não tiver valor, o sistema usa a variação do
  modelo sem aquela frase. Nunca inventa nem deixa um campo vazio.
- Toda mensagem leva o **link de pedido da pizzaria**, para trazer a compra ao canal próprio
  (é o que permite medir a conversão).
- Modelo G1, exemplo (o briefing pede o tom):
  > Oi, {primeiro_nome}! Faz um tempinho que você não pede com a gente 😊 Vimos que
  > {sabor_favorito} está entre as suas favoritas. Que tal matar a vontade hoje? É só pedir por
  > aqui: {link_pedido} 🍕
- [R4] Reescrita por IA: um modelo de linguagem gera variações **a partir apenas dos campos
  fornecidos**, e a saída passa por uma validação que rejeita sabores, preços ou promoções que
  não estejam nos dados de entrada.

---

## 11. Regras de negócio

### 11.1 Dinheiro, tempo e números
| ID | Regra |
|---|---|
| RN-01 | Todo valor monetário é guardado em **centavos inteiros** (`*_cents bigint`). Nada de ponto flutuante |
| RN-02 | Datas e horas são guardadas com fuso (`timestamptz`), sempre interpretadas em `America/Sao_Paulo`. **Data de negócio = dia do turno** (decisão do dono, 11/11/2026): pedido das 00h15 dentro do turno de sexta que vai até 00h30 conta como **sexta** no caixa, nos relatórios e no CRM. Fora de turno que atravessa a meia-noite, vale a data do calendário (23h50 é do próprio dia, nunca do dia seguinte em UTC) |
| RN-03 | **Preço da pizza com mais de um sabor:** padrão = **preço do sabor mais caro** naquele tamanho; opção da loja = **média** dos sabores, arredondada para cima no centavo. Adicionais somam por cima |
| RN-04 | **O servidor recalcula o pedido inteiro** (preços, frete, mínimo, horário, disponibilidade). O valor enviado pelo navegador é ignorado. Divergência → o cliente vê "O preço de X mudou, confira" |
| RN-05 | **Idempotência do pedido:** cada tentativa de envio leva uma chave única gerada no aparelho; a mesma chave nunca cria dois pedidos |
| RN-06 | **Número do pedido:** sequencial por pizzaria, gerado com trava no banco (sem duplicar sob concorrência) |
| RN-07 | O pedido guarda uma **cópia** do nome e do preço de cada item no momento da compra. Mudar o cardápio não altera pedido antigo |

### 11.2 Cardápio, horário e frete
| ID | Regra |
|---|---|
| RN-08 | O link só aceita pedido dentro do horário e com pedidos online não pausados |
| RN-09 | Frete = taxa do bairro. Retirada = R$ 0. Bairro não cadastrado = não entrega |
| RN-10 | O pedido mínimo, se existir, vale sobre o subtotal dos itens (sem frete) |
| RN-11 | Item desativado durante a montagem do carrinho é barrado no envio com aviso específico |

### 11.3 Clientes e identidade
| ID | Regra |
|---|---|
| RN-12 | **Privacidade no link:** digitar um celular **não** mostra os dados de quem tem aquele número. O preenchimento automático só acontece no **mesmo aparelho** onde o cliente já pediu (token guardado no navegador). Em aparelho novo, o cliente redigita o endereço, que fica ligado ao mesmo cadastro pelo celular |
| RN-13 | Celular normalizado para E.164 (+55 DDD número). É a chave única do cliente **por pizzaria**. Um mesmo número em pizzarias diferentes são clientes diferentes, sem nenhum compartilhamento de dados |
| RN-14 | O nome mais recente informado atualiza o cadastro só se o anterior estiver vazio. Mudança de nome pelo link não sobrescreve o nome corrigido pela equipe |
| RN-15 | Pedido sem celular (balcão) é "não identificado": entra no caixa e nas vendas, mas não no CRM |
| RN-16 | Clientes importados por CSV entram **sem consentimento de marketing**, a menos que a planilha traga a coluna de consentimento e a pizzaria declare que o coletou (aceite registrado em nome do usuário que importou) |

### 11.4 Pedido e operação
| ID | Regra |
|---|---|
| RN-30 | Só pedidos **Concluídos** contam para o histórico e as métricas do cliente. Cancelado não conta |
| RN-31 | Cancelamento exige motivo (lista + texto livre). Se havia pagamento lançado, o cancelamento gera o **estorno no caixa** (no caixa aberto atual, identificado como estorno de pedido de outro turno quando for o caso) |
| RN-32 | Pedido concluído não volta de status e não é apagado; correção = ajuste registrado com motivo |
| RN-33 | Alteração de itens só é permitida até **Em preparo**; depois disso, cancela e refaz |

### 11.5 Caixa
| ID | Regra |
|---|---|
| RN-20 | Um caixa aberto por ponto de venda (vários pontos por loja na R2). Registrar pagamento exige caixa aberto; se não houver, o sistema oferece abrir |
| RN-21 | **Dinheiro esperado na gaveta** = troco inicial + entradas em dinheiro (líquidas de troco) + suprimentos − sangrias − estornos em dinheiro. É **uma única função**, usada no fechamento, no resumo e em qualquer indicador. Cartão, Pix e vale **nunca** entram nessa conta |
| RN-22 | No fechamento, a contagem é obrigatória. **"Não contado" é guardado como vazio (nulo), nunca como zero.** Zero é uma resposta; vazio é ausência de resposta |
| RN-23 | Lançamentos de caixa (pagamento, sangria, suprimento, estorno) são **imutáveis**: não se editam nem se apagam. Erro se corrige com lançamento inverso |
| RN-24 | Fechar caixa é uma ação única e travada: dois aparelhos não conseguem fechar o mesmo caixa duas vezes |

### 11.6 Campanhas e atribuição
| ID | Regra |
|---|---|
| RN-40 | Um contato é registrado quando o atendente toca em "Enviar" no WhatsApp. É possível desfazer em até 10 min ("não enviei") |
| RN-41 | **Conversão atribuída:** pedido concluído do mesmo cliente em até **7 dias** depois do contato. Se houve vários contatos, o crédito vai para o mais recente |
| RN-42 | "Voltou sozinho" (pedido sem contato antes) é mostrado separado e nunca somado ao resultado das campanhas |
| RN-43 | O conteúdo da mensagem enviada **não** é guardado: só o modelo usado, o gatilho e a data. É o suficiente para medir o resultado e minimiza dados pessoais |
| RN-46 | Mensagem sem dado não é inventada: variável vazia → variação sem aquela frase (ver 10.7) |

### 11.7 Consentimento e LGPD
| ID | Regra |
|---|---|
| RN-50 | Consentimento de marketing é **opt-in**, por canal (WhatsApp), com data/hora, origem (link, balcão, importação), versão do texto mostrado e quem registrou |
| RN-51 | Opt-out vale **imediatamente** e para sempre, até um novo opt-in feito pelo próprio cliente |
| RN-52 | Mensagens **sobre o pedido** (status, confirmação) não dependem de consentimento de marketing (execução do contrato). Mensagens **promocionais** dependem |
| RN-53 | Toda mensagem promocional inclui uma saída simples: "Não quer mais receber? É só responder SAIR." A equipe registra o opt-out no painel (com `wa.me` o sistema não lê a resposta) |
| RN-54 | O cliente pode pedir cópia ou exclusão dos dados. Exclusão = **anonimização** (nome, telefone e endereço removidos), mantendo pedido e caixa para fins fiscais e contábeis |
| RN-55 | Dados de uma pizzaria **nunca** são visíveis para outra (isolamento garantido no banco) |
| RN-56 | **Papéis na LGPD:** a pizzaria é a **controladora** dos dados dos clientes dela; a Contera é **operadora**. O contrato de assinatura inclui o acordo de tratamento de dados, e o sistema fornece um modelo de política de privacidade que informa o uso do histórico de compras para ofertas personalizadas |

---

## 12. Arquitetura

### 12.1 Visão geral
```mermaid
flowchart LR
  subgraph Cliente final
    L[Link de pedidos<br/>/:slug]
    S[Página de status<br/>/:slug/pedido/:token]
  end
  subgraph Equipe
    P[Painel PWA<br/>/app/*]
  end
  subgraph Supabase
    API[PostgREST + RPC]
    EF[Edge Functions<br/>place-order, import-customers]
    DB[(Postgres + RLS)]
    RT[Realtime<br/>pedidos]
    CRON[pg_cron<br/>motor CRM 03-06h BRT]
    AUTH[Auth]
  end
  VIACEP[ViaCEP]
  WA[WhatsApp do atendente<br/>wa.me]
  MP[Mercado Pago<br/>Pix online e assinatura]

  L -->|cardápio público, RPC só leitura| API
  L -->|envia pedido| EF
  L -.->|CEP| VIACEP
  S -->|status por token| API
  P -->|login| AUTH
  P -->|CRUD com RLS| API
  RT -->|novo pedido| P
  EF --> DB
  API --> DB
  CRON --> DB
  P -->|abre conversa| WA
  EF -->|Pix, webhook idempotente| MP
```

### 12.2 Stack
| Camada | Escolha | Motivo |
|---|---|---|
| Front-end | **React + TypeScript + Vite + Tailwind + shadcn/ui** | Padrão Contera; compatível com Lovable e Claude Code |
| Estado/dados | TanStack Query, React Hook Form + Zod | Validação igual no front e no servidor (mesmo esquema Zod) |
| Back-end | **Supabase**: Postgres, Auth, RLS, RPC, Edge Functions (Deno), Realtime, Storage, pg_cron | Um único provedor; RLS isola as pizzarias no banco |
| Pagamento online [R1] | Mercado Pago (Pix no link e assinatura da plataforma), com webhook assinado e idempotente | Padrão Contera; o Pix domina pagamentos no Brasil |
| Mensagens | `wa.me` (R1) → WhatsApp Business Cloud API (R4) | Ver D7 |
| Hospedagem do front | Vercel ou Cloudflare Pages | CDN; o cardápio público precisa ser rápido |
| PWA | Manifest + service worker com **atualização forçada** a cada deploy | Evita o problema "publiquei e o app instalado continua velho" |

**Uma aplicação, duas áreas.** Mesmo repositório e mesmo build, com rotas carregadas sob
demanda: o **cardápio público** (`/:slug`, sem login, pacote leve) e o **painel** (`/app/*`,
autenticado). A pré-visualização do link no WhatsApp (título, logo) é servida por uma Edge
Function que monta as meta tags por pizzaria, porque uma SPA não faz isso sozinha.

### 12.3 Decisões de arquitetura
| ID | Decisão | Alternativa descartada |
|---|---|---|
| AD-01 | **Multi-pizzaria por coluna** `tenant_id` em toda tabela de negócio + RLS por `tenant_id` do usuário | Um banco por pizzaria: caro de operar e de evoluir |
| AD-02 | Criar pedido via **Edge Function `place-order`** (ou RPC `SECURITY DEFINER` com validação interna), que recalcula tudo numa transação | Inserção direta pelo navegador: permitiria manipular preço |
| AD-03 | Cardápio público por **RPC somente leitura** (`get_public_menu(slug)`) que devolve só itens ativos; o usuário anônimo não acessa tabelas | Liberar `SELECT` anônimo nas tabelas: vaza mais do que deve |
| AD-04 | **Métricas do cliente materializadas** em `customer_stats`, atualizadas por gatilho ao concluir pedido + recálculo completo toda madrugada | Calcular ao abrir a tela: lento e com regras duplicadas |
| AD-05 | **Motor de oportunidades em SQL** (função agendada no pg_cron, escalonada por loja entre 03:00 e 06:00 BRT; AD-12) com regras parametrizadas na tabela `opportunity_rules` | Serviço externo/ML: desnecessário para regras explicáveis; a explicabilidade é requisito (P6) |
| AD-06 | Tabelas de movimento (`cash_movements`, `order_status_history`, `contact_log`, `audit_log`) **sem permissão de UPDATE/DELETE**; correção por lançamento inverso | Edição livre: destrói a confiança no caixa e no resultado das campanhas |
| AD-07 | Realtime **somente** na tabela de pedidos, filtrado pela pizzaria | Realtime em tudo: custo e ruído |
| AD-08 | Proteção do endpoint público: limite de requisições por IP e por celular; captcha (Cloudflare Turnstile) ativado se houver abuso | Sem proteção: pedidos falsos derrubam a confiança da cozinha |

### 12.4 Segurança e acesso
| Papel | Pode |
|---|---|
| **Dono** | Tudo da pizzaria, incluindo configurações, usuários, cancelar pedido já despachado, ver resultado de campanhas, exportar e anonimizar clientes |
| **Atendente** | Pedidos, caixa, clientes (ver e editar contato), executar oportunidades. **Não** altera cardápio/preços/configurações nem exporta dados |
| **Gerente** (R1) | Como o Dono, exceto usuários, plano/assinatura e exportação de dados |
| **Contador** (R2, com M13/M12) | Somente leitura de financeiro e fiscal + exportações contábeis. Papel-chave do canal de contadores |
| **Cozinha, Entregador, Garçom** (R2/R3) | Só a tela do seu trabalho (KDS, entregas, mesas) |
| **Suporte Contera** | Painel master; acesso a uma pizzaria só por "entrar como" com motivo, MFA e registro em auditoria |

- **Login:** e-mail + senha; **verificação em duas etapas (MFA) obrigatória para o Dono**,
  opcional para Atendente. Atendente pode usar um aparelho fixo do balcão com sessão longa.
  Usuário com acesso a mais de uma pizzaria (contador, rede) troca a pizzaria ativa, o que emite um novo token (AD-09).
- **Auditoria:** cancelamentos, estornos, mudança de preço, fechamento de caixa,
  exportação/anonimização e mudanças de permissão ficam em `audit_log`.
- Nenhuma chave secreta no front; segredos só nas Edge Functions.

---

### 12.5 Escalabilidade (requisito: 100+ pizzarias e 200 a 300+ usuários desde o início)
**Leitura honesta da carga:** 100 pizzarias e 300 usuários é um volume **modesto** para Postgres.
O risco não é o volume, é o **desenho**: RLS mal escrito, cardápio público batendo no banco a
cada acesso, jobs de todas as lojas rodando ao mesmo tempo e integrações síncronas.
**Meta de projeto: 10 vezes o pedido**, ou seja 1.000 pizzarias, 5.000 usuários e 150 mil
pedidos/dia, **sem reescrita**.

| Carga estimada com 100 lojas | Valor aproximado |
|---|---|
| Pedidos por noite (toda a plataforma; até 100 por loja) | 8 a 10 mil |
| Pico de criação de pedidos | 2 a 3 pedidos/s |
| Acessos ao cardápio público por noite | ~100 mil (servidos pelo CDN, não pelo banco) |
| Conexões em tempo real | 300 a 500 (equipes; o cliente final consulta por intervalo) |

| ID | Decisão de escala |
|---|---|
| AD-09 | **Pizzaria no token de login** (claim `tenant_id` via *custom access token hook* do Supabase). A RLS compara a coluna com o claim, sem consulta extra por linha. Índices sempre começando por `tenant_id`. O claim é validado contra `memberships` na emissão; trocar de pizzaria emite novo token |
| AD-10 | **Cardápio público em cache no CDN** (JSON versionado, invalidado ao salvar o cardápio). Só o envio do pedido chega ao banco |
| AD-11 | **Fila de jobs** no Postgres (status, tentativas, espera exponencial, fila de falhas) processada por workers. Tudo que fala com terceiros (fiscal, iFood, 99Food, Mercado Pago, bancos) é **assíncrono e idempotente**, nunca dentro do clique do usuário |
| AD-12 | **Motor do CRM escalonado:** cada loja roda em um horário entre 03:00 e 06:00 (Brasília), com cálculo incremental. Nenhum job varre todas as lojas de uma vez |
| AD-13 | **Integrações por adaptadores** (`MarketplaceAdapter`, `FiscalProvider`, `PaymentProvider`, `BankFeedProvider`): trocar de fornecedor sem mexer no núcleo |
| AD-14 | **Direitos por módulo** (seção 12.6) checados na interface, no servidor e nos jobs |
| AD-15 | Tempo real com um canal por loja; a página de status do cliente final usa consulta periódica. Conexões crescem com o número de equipes, não com o público |
| AD-16 | Crescimento de dados: índices `(tenant_id, data)`; particionamento mensal de pedidos, itens e auditoria quando passarem de ~50 milhões de linhas; arquivamento após 24 meses |
| AD-17 | Ambientes de desenvolvimento, homologação e produção; migrações versionadas no CI; padrão expandir → migrar → contrair (deploy sem parada); liberação gradual por loja (feature flags) |
| AD-18 | Observabilidade por loja: erros de front e servidor, latência, fila de jobs, saúde de cada integração; meta de 99,9% de disponibilidade no pico; página de status pública |
| AD-19 | Proteção contra "vizinho barulhento": limites por loja (requisições, jobs, exportações); relatórios pesados vão para uma réplica de leitura quando necessário |

**Caminho de crescimento:** Supabase Pro com mais capacidade de máquina → réplica de leitura
para relatórios → workers dedicados. Tudo em Postgres padrão, sem aprisionamento ao fornecedor.
**Antes do lançamento:** teste de carga com 10 vezes o volume previsto.

### 12.6 Direitos por módulo (planos e módulos sem mexer no código)
- Tabelas: `plans`, `modules`, `plan_modules`, `subscriptions` (pizzaria, plano, status, ciclo),
  `tenant_modules` (pizzaria, módulo, origem: plano/avulso/cortesia, status, validade) e
  limites (usuários, lojas).
- **Três camadas de checagem:** (1) interface: módulo desligado some do menu e aparece
  como "Conheça este módulo", uma oferta discreta; (2) servidor/banco: função
  `has_module(tenant, código)` exigida nas RPCs, Edge Functions e políticas das tabelas do
  módulo; (3) jobs não processam módulo desligado.
- **Desligar um módulo nunca apaga dados:** eles ficam somente leitura por 90 dias, e religar devolve tudo.
- **Inadimplência sem derrubar o expediente:** aviso 5 dias e 1 dia antes e no dia do
  vencimento; após 10 dias, os módulos avulsos e as configurações ficam bloqueados; após 20
  dias, o sistema fica só para consulta e pagamento. **O corte nunca acontece durante o horário de
  funcionamento** e nunca derruba uma sessão de caixa aberta: sempre há a saída "regularizar agora".
- **Operação crítica protegida:** pedidos, caixa e **fiscal** (mesmo sendo módulo avulso) não
  entram no bloqueio dos 10 dias. Bloquear a NFC-e impede a pizzaria de vender legalmente;
  esses módulos só param na etapa final (20 dias), com aviso de 48 h e fora do expediente.

### 12.7 Integrações externas
| Integração | Como | Observação |
|---|---|---|
| **iFood** | API oficial de parceiros do iFood (pedidos, status, depois cardápio) | Exige cadastro e homologação da Contera como integradora. O cliente do iFood geralmente chega **sem telefone real**: é marcado como "cliente de marketplace" e não entra nas campanhas |
| **99Food** | API de parceiros da 99 | **Disponibilidade e condições a confirmar** antes de vender o módulo |
| Fiscal | Emissor via API de parceiro (avaliar, por exemplo, Focus NFe, PlugNotas, NFe.io) | O certificado A1 do cliente fica cifrado; a emissão é assíncrona, com contingência |
| Pagamentos | Mercado Pago: Pix online no link e assinatura da plataforma | Webhook com assinatura verificada e idempotente |
| Conciliação | Open Finance via agregador (avaliar, por exemplo, Pluggy, Belvo) ou importação OFX; cartões via arquivos e APIs das credenciadoras | — |
| WhatsApp | `wa.me` (R1) → API oficial Cloud (R4) | — |
| Impressão | Navegador (R1) → agente local ESC/POS (R2) | — |
| CEP | ViaCEP, com BrasilAPI de reserva | — |

---

## 13. Modelo de dados (entidades principais)

> Convenções: toda tabela de negócio tem `id uuid`, `tenant_id uuid` (com RLS),
> `created_at timestamptz`. Valores em `*_cents bigint`. Detalhamento em DDL na Fase 0.

| Entidade | Campos-chave | Observações |
|---|---|---|
| `tenants` | name, slug (único), logo_url, accent_color, whatsapp, address, timezone, settings jsonb | Uma pizzaria |
| `memberships` | tenant_id, user_id, role (`owner`/`attendant`) | Liga usuários do Auth às pizzarias |
| `business_hours` | weekday, opens_at, closes_at | Mais de um turno por dia |
| `delivery_zones` | neighborhood, fee_cents, extra_minutes, active | Frete por bairro (D2) |
| `payment_methods` | kind (`cash`/`pix`/`debit`/`credit`/`voucher`), active | — |
| `categories` | name, sort_order, active | — |
| `pizza_sizes` | name, slices, max_flavors, sort_order | — |
| `flavors` | name, description, image_url, active | Sabores de pizza |
| `flavor_prices` | flavor_id, size_id, price_cents | Preço por tamanho |
| `products` | category_id, name, price_cents, active | Bebidas, porções |
| `addon_groups` / `addons` | min, max / name, price por tamanho | Bordas e extras |
| `customers` | phone_e164 (único por tenant), name, birth_date, anonymized_at | — |
| `customer_addresses` | customer_id, cep, street, number, complement, neighborhood, reference | — |
| `marketing_consents` | customer_id, channel, status (`granted`/`revoked`), source, text_version, recorded_by, recorded_at | Histórico: só inserção (RN-50) |
| `orders` | number, business_date (data de negócio, RN-02), customer_id?, channel (`link`/`counter`/`phone`/`marketplace`), type (`delivery`/`pickup`/`dine_in`), status, subtotal/fee/discount/total_cents, address snapshot, payment_method, change_for_cents, idempotency_key (único), public_token, campaign_contact_id? | — |
| `order_items` | order_id, kind (`pizza`/`product`), name_snapshot, size_snapshot, unit_price_cents, qty, notes | — |
| `order_item_flavors` | order_item_id, flavor_id, name_snapshot, fraction (0,5 / 0,33...) | Alimenta "sabor favorito" |
| `order_item_addons` | order_item_id, addon_id, name_snapshot, price_cents | — |
| `order_status_history` | order_id, from_status, to_status, by_user, at, reason | Só inserção |
| `cash_sessions` | opened_by/at, opening_cents, closed_by/at, counted_cents (nulo até contar), expected_cents, status | RN-20 a RN-24 |
| `cash_movements` | session_id, order_id?, kind (`payment`/`withdrawal`/`supply`/`refund`), method, amount_cents, reason | Só inserção (RN-23) |
| `customer_stats` | customer_id, métricas da seção 10.1, segment, is_vip, computed_at | Materializada (AD-04) |
| `opportunity_rules` | trigger_code (G1…), params jsonb, priority, active | Configuração dos gatilhos |
| `opportunities` | customer_id, trigger_code, reason_text, context jsonb, status (`open`/`contacted`/`dismissed`/`expired`/`returned_alone`/`converted`), created_for_date, expires_at | — |
| `message_templates` | trigger_code, variant, body, active | Modelos editáveis |
| `contact_log` | opportunity_id?, customer_id, template_id, channel, by_user, at, undone_at? | Sem conteúdo da mensagem (RN-43) |
| `audit_log` | actor, action, entity, entity_id, diff jsonb, at | Só inserção |

**Plataforma (R0/R1):** `plans`, `modules`, `plan_modules`, `subscriptions`, `subscription_invoices`,
`tenant_modules`, `jobs`, `integration_accounts` (credenciais cifradas por pizzaria),
`support_tickets`, `fiscal_documents`. **Módulos R2–R4:** `drivers`, `deliveries`,
`loyalty_ledger`, `coupons`, `bank_accounts`, `bank_transactions`, `payables`, `receivables`,
`card_receivables`, `marketplace_orders`, `ingredients`, `recipes` (ficha técnica),
`stock_movements`, `suppliers`, `purchase_orders`, `tables`, `table_sessions`, `stores`.
Todas seguem as convenções acima (tenant, RLS, centavos, movimentos só com inserção).

---

## 14. Requisitos não funcionais

| ID | Requisito | Meta |
|---|---|---|
| RNF-01 | Desempenho do cardápio público | LCP ≤ 2,5 s em 4G, pacote JS inicial ≤ 200 KB gzip |
| RNF-02 | Latência do pedido novo no painel | ≤ 5 s (p95) |
| RNF-03 | Disponibilidade nos horários de pico (18h–23h) | 99,9% no mês (mesma meta do AD-18) |
| RNF-04 | Volume de referência | Lançamento: 100+ pizzarias e 300+ usuários. Meta de projeto sem reescrita: 1.000 pizzarias, 5.000 usuários, 150 mil pedidos/dia (seção 12.5) |
| RNF-05 | Motor de oportunidades | ≤ 10 s por loja dentro da janela 03:00–06:00; falha gera alerta, repete pela fila e não apaga as oportunidades do dia anterior |
| RNF-06 | Isolamento | Teste automatizado provando que o usuário da pizzaria A não lê nem escreve dados da B, em toda tabela |
| RNF-07 | Acessibilidade | Contraste AA, alvos de toque ≥ 44 px, operável por teclado no painel |
| RNF-08 | Navegadores | Chrome/Safari móveis dos últimos 2 anos; painel em Chrome desktop |
| RNF-09 | Backup | Backup diário gerenciado do Supabase + exportação lógica semanal; restauração testada antes do piloto |
| RNF-10 | Observabilidade | Erros de front e de Edge Functions registrados; alerta se nenhum pedido online entrar por 2 h em horário de funcionamento com pedidos no dia anterior |
| RNF-11 | Qualidade | Gabarito do gerador demo (`--verificar`) reproduzido pela implementação real; testes automatizados de: cálculo de preço (RN-03/04), idempotência (RN-05), transições de status, dinheiro esperado (RN-21), segmentos e gatilhos (seção 10), RLS (RNF-06) |

---

## 15. Roadmap e plano de entrega

### 15.1 Premissas
- Equipe: **2 desenvolvedores full-stack** + 1 pessoa de produto/design em meio período, com
  apoio de IA. Com 1 desenvolvedor, os prazos praticamente dobram.
- As estimativas são ordem de grandeza e serão refinadas ao fim da R0.
- **Um ERP completo e premium se constrói em releases.** Cada release fica vendável sozinha; a
  seguinte amplia sem quebrar a anterior.

### 15.2 Releases
| Release | Período | Módulos | Resultado |
|---|---|---|---|
| **R0. Fundação** | semanas 1 a 3 | Repositório, ambientes, banco com RLS por claim (AD-09), tabelas de módulos (12.6), design system premium, CI com testes, **pizzaria demo carregada** | Duas pizzarias isoladas comprovadas por teste; a demo abre no painel |
| **R1. Núcleo comercial** | meses 1 a 5 | M01 a M08 + **M12 Fiscal** | **Primeira venda**: uma pizzaria troca o sistema atual pelo Fornalia (pedidos, caixa, nota fiscal e CRM) |
| **R2. Gestão** | meses 6 a 8 | M09, M10, M11, M13, M14, impressão automática | Profissional e Premium completos para delivery; iFood/99Food |
| **R3. Controle** | meses 9 a 11 | M15, M16, M17, M18, M22 | Custo, margem, salão e operação sem internet |
| **R4. Escala e IA** | meses 12 a 15 | M19, M20, M21, M23, M24, M25 | Redes, automação oficial de WhatsApp, inteligência artificial |

**Por que o Fiscal entrou na R1:** sem NFC-e, a pizzaria não consegue usar o Fornalia como
sistema principal. Ela manteria outro sistema para emitir nota e não migraria.

### 15.3 Fases da R1
| Fase | Entrega | Pronto quando... |
|---|---|---|
| F1. Cardápio (M02) | Configuração completa | Uma pessoa cadastra um cardápio inteiro em ≤ 1 h |
| F2. Link de pedidos + Pix (M03) | Cardápio público, construtor, frete, status, Pix online | Pedido pelo celular com preço recalculado no servidor; Pix confirmado por webhook idempotente |
| F3. Operação (M04) | Fila em tempo real, alerta, status, balcão, comanda | Simulação de rush: 30 pedidos em 20 min sem perda nem duplicidade |
| F4. PDV e caixa (M05) | Abrir, receber, sangria, fechamento cego | Fechamento bate em todos os cenários de teste, inclusive estorno |
| F5. Fiscal (M12) | NFC-e em homologação e produção, contingência | Notas autorizadas no ambiente de homologação da SEFAZ para todos os cenários de pagamento |
| F6. Clientes (M06) | Histórico, perfil em frases, importação, consentimento | Métricas corretas sobre a base demo |
| F7. Motor do CRM | Seção 10, job escalonado | O motor em SQL reproduz **exatamente** `demo/gabarito_2026-11-08.txt` sobre a base demo (mesmas contagens e mesmos clientes por cartão) |
| F8. Campanhas + Resumo (M07, M08) | Cartões, envio `wa.me`, atribuição | Do cartão ao WhatsApp em ≤ 3 toques; conversão atribuída corretamente |
| F9. Plataforma (M01) | Cadastro self-service, assinatura Mercado Pago, módulos, painel master, chamados | Uma pizzaria se cadastra, testa 14 dias, assina e tem módulos ligados/desligados sem suporte |
| F10. Endurecimento | Teste de carga 10×, revisão de segurança, backup e restauração testados | Critérios do RNF atendidos com números |

### 15.4 Piloto e beta
1. **Piloto interno:** a pizzaria fictícia [Forno da Vila (DEMO)](./PILOTO-DEMO.md) é usada
   em todas as fases e em toda demonstração.
2. **Beta fechado** ao fim da F8: 3 a 10 pizzarias reais com desconto (plano de negócio, seção 8).
3. Critérios de sucesso do beta: ≥ 90% dos pedidos registrados no sistema; ≥ 90% dos pedidos
   do link com cliente identificado; o dono envia campanhas em ≥ 3 de cada 4 semanas;
   pedidos atribuídos ao CRM medidos e publicados como caso de sucesso.

### 15.5 Partida a frio do CRM em clientes reais
Importação de clientes (RF-55), operação no ar antes do CRM e estado vazio honesto ("em
cerca de 3 semanas de pedidos as primeiras oportunidades aparecem aqui").

---

## 16. Riscos e mitigações

| Risco | Impacto | Mitigação |
|---|---|---|
| Pouco histórico no início, então o CRM parece vazio | Dono desiste antes de ver valor | Seção 15.2; operação antes do CRM; importação CSV |
| Clientes sem consentimento, então ninguém é elegível | CRM sem ação | Caixa de opt-in bem escrita no link; frase para o balcão pedir; mostrar ao dono quantos clientes estão "bloqueados" (10.4) |
| Envio 1 a 1 por `wa.me` cansa com listas grandes | Dono para de usar | Limite diário de 30 por cartão (10.5), modo sequência; API oficial na R4 quando houver demanda comprovada |
| Excesso de mensagens leva a bloqueio do número ou incomoda o cliente | Dano à marca da pizzaria | Limites D9, opt-out fácil, nada de disparo automático antes da R4 (e, lá, só com opt-in formal) |
| Pedidos de marketplace ficam fora do CRM | Visão parcial do cliente | Estratégia: toda campanha leva o link próprio e migra o cliente para o canal direto |
| Número compartilhado (família) ou cliente com 2 números | Métricas distorcidas | Aceitável na R1; mesclagem na R2 |
| Pico de pedidos com internet instável no balcão | Pedido perdido | Idempotência (RN-05), alerta repetido, comanda impressa; modo offline fica para depois |
| ERP completo atrasa a primeira venda | Caixa da empresa sem receita por muito tempo | Releases vendáveis (seção 15); R1 já substitui o sistema atual da pizzaria |
| Complexidade fiscal (regras por estado, reforma tributária) | Nota rejeitada impede a venda | Emissor fiscal parceiro (AD-13), homologação por estado, contingência |
| Dependência de APIs de terceiros (iFood, 99Food, bancos) | Módulo para de funcionar sem aviso | Adaptadores, fila com repetição, monitor de saúde por integração, contrato de parceiro |
| Interface ficar complexa com tantos módulos | Perde o diferencial "simples de usar" | Menu mostra só os módulos ligados; princípios da seção 2.3; teste de usabilidade a cada release |
| Concorrência com sistemas de pedido já estabelecidos | Difícil vender só "cardápio digital" | Posicionar pelo CRM com resultado medido (RN-41), não pelo cardápio |

---

## 17. Próximos passos
1. **Você** aprova o nome, os preços e os planos ([`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md)) e o roadmap da seção 15.
2. R0: esquema do banco (DDL), RLS por claim, tabelas de módulos, carregador da pizzaria demo e testes de isolamento.
3. R1 fase a fase, cada uma com o critério de "pronto" da tabela 15.3.

---

## Apêndice A. Glossário da interface (técnico → tela)
| Termo técnico | Na tela |
|---|---|
| Churn / inativo | "Sumiu" / "Não pede há X dias" |
| Ticket médio | "Valor médio do pedido" |
| Segmento | "Grupo de clientes" |
| Recência / frequência | "Último pedido" / "Pede a cada X dias" |
| Conversão | "Voltou a pedir depois da mensagem" |
| Opt-in / opt-out | "Aceita receber mensagens" / "Não quer receber mensagens" |
| Lead time | "Tempo para ficar pronto" |

## Apêndice B. Rastreabilidade: briefing → PRD
| Briefing | Onde está no PRD |
|---|---|
| §1–2 Visão e princípio central | 1, 2 |
| §3 Público e necessidades | 3 |
| §4 Fluxo de pedidos | 7.1–7.3, M2, M3, seção 9 |
| §5 CRM inteligente | 10.1–10.2, 10.6, M4 |
| §6 Campanhas automáticas | 10.3–10.7, M6, 11.6 |
| §7 Interface | 6 |
| §8 Ciclo de crescimento | 1, 7.5 |
| §9–10 O que não ser / diretrizes | 2.3, 2.4 |
| §11 Módulos | 5 (catálogo completo), 8 |
| §12 Questões em aberto | 4.1, 4.2 |
| §13 Critério de sucesso | 6.2, 15.3 |
