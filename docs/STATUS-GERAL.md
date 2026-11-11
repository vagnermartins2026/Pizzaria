# Status geral da Pizzalia: o caminho até 100%

Atualizado em 11/11/2026. Pendências do dono: [`BACKLOG-DO-DONO.md`](./BACKLOG-DO-DONO.md). Retomada: [`PASSAGEM_DE_SESSAO.md`](./PASSAGEM_DE_SESSAO.md).

## As 3 frentes
| Frente | Situação | Trava |
|---|---|---|
| **1. Site de venda** | ✅ Pronto e no ar em https://pizzalia.pages.dev | Domínio próprio (D1) |
| **2. Marca e negócio** | ✅ Nome, preços, empresa, logo, termos (rascunho) | INPI (D2), Instagram (D3), encarregado de dados e jurídico (D8) |
| **3. Sistema (o produto)** | 🟡 Planejado; só o motor do CRM está construído e provado | Base do sistema (D14) |

## Frente 3: o que falta para o sistema ficar 100%
Fases do PRD (seção 15). Prazos do PRD com 2 desenvolvedores; com IA e a base remixada, o prazo real se mede na R0.

| Fase | O que entrega | Situação |
|---|---|---|
| **Planejamento** | PRD, plano de negócio, pizzaria demo com 5.600 pedidos, gabarito do CRM | ✅ Feito |
| **Motor do CRM** (coração do produto) | Cálculo diário de quem sumiu, provado contra o gabarito (466 oportunidades idênticas) | ✅ Feito (falta ligar na base) |
| **R0 · Fundação** | Base remixada, banco com isolamento por pizzaria, pizzaria demo carregada, testes automáticos | ⏳ Espera o D14 |
| **R1 · Primeira venda** | Cadastro e assinatura, cardápio, link de pedidos com Pix, painel de pedidos, PDV e caixa, clientes, CRM nas telas, nota fiscal | ⏳ Depois da R0 (PRD: meses 1 a 5) |
| **R2 · Gestão** | Cozinha (KDS), entregadores, cupons e fidelidade, financeiro com conciliação, iFood e 99Food | ⏳ PRD: meses 6 a 8 |
| **R3 · Controle** | Estoque e custo por pizza, compras, salão e mesas, funciona sem internet | ⏳ PRD: meses 9 a 11 |
| **R4 · Escala e IA** | Várias lojas, WhatsApp oficial, previsão de demanda, API | ⏳ PRD: meses 12 a 15 |

**Ponto de virada:** ao fim da **R1** a Pizzalia já pode ser vendida (a primeira pizzaria troca o sistema dela). É quando o site vira
a chave da lista de espera para o cadastro.

## O que o Claude faz sozinho em cada fase
| Quando | O Claude faz |
|---|---|
| Ao receber o D1 (domínio) | Liga o domínio ao site, tira a prévia do modo "fora do Google", confere HTTPS, sitemap e prévia de link |
| Ao receber o D14 (base) | Lê a base, liga o motor do CRM (`02_adaptador_*.sql`, RLS, rotina noturna), carrega a pizzaria demo, prova o gabarito de novo |
| Na R1 | Constrói as telas e regras do PRD fase a fase, com testes; cadastro e assinatura conforme `CADASTRO-DO-SISTEMA.md` |
| Na abertura | Muda o site para "aberto", publica Termos e Privacidade revisados, confere tudo no ar |
| Depende do dono, mesmo durante a construção | Credenciais do Mercado Pago, certificado e emissor fiscal, aprovação de cada publicação |
