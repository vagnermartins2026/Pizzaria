# Backlog da Pizzalia (atualizado em 13/11/2026)

Sistema publicado: https://pizzalia.lovable.app (versão `mwfbd91y`, commit `5f62c2e` da main do `vagnermartins2026/pizzalia`).
Site de vendas (prévia): https://pizzalia.pages.dev. Banco: Supabase `tsidqofldtkkgexbmtor` (grátis).

## ✅ Feito e verificado
| # | Entrega | Prova |
|---|---|---|
| 1 | PRD, plano de negócio, preços e nome Pizzalia | docs/PRD.md, docs/PLANO-DE-NEGOCIO.md |
| 2 | Pizzaria fictícia Forno da Vila (geradores com gabarito) | demo/ (gabaritos conferidos) |
| 3 | Remix da MayFlower + migração TanStack adaptada | PR #1 (3.101 testes de tela, 963 de banco) |
| 4 | Banco novo: 187 migrations aplicadas e anotadas | ensaio desfeito + aplicação; 85 tabelas com RLS |
| 5 | 18 funções do servidor publicadas e testadas | chamadas sem login: recusam corretamente |
| 6 | Correção: a tela travava depois do login (ponte TanStack) | PR #2; teste 30 → 1 navegação; conferido no ar |
| 7 | Marca Pizzalia: nome, logo da fatia, cor vermelha, tela de entrar | PR #3 e #6 |
| 8 | Correção: cópia semanal do backup por e-mail nunca saía | PR #4; também era erro na MayFlower (confirmado lá) |
| 9 | Cardápio de pizza (M02): banco, tela, testes | PR #5; 15 sabotagens no banco e 4 na tela pegas |
| 10 | Loja demo completa: vendas, clientes, estoque, caixa, financeiro, compras, clube, metas, cupons, despesas fixas, cardápio | prova local + login real em cada tela |
| 11 | Planos Essencial/Profissional/Premium (desligados até o lançamento) | banco |
| 12 | Login de teste (Dono) e login do dono (administrador da demo) | login conferido |
| 13 | Backup diário funcionando (cópia no Supabase) | backup disparado: sucesso |
| 14 | Sistema publicado e conferido no ar | login + 7 telas sem erro |
| 15 | Regra de ouro: 6 avisos à MayFlower (1 erro real confirmado e corrigido lá) | mensagens às sessões |

## 🔧 Falta e eu faço sozinho (ordem recomendada)
| # | Item | Onde | Esforço |
|---|---|---|---|
| A | M03 · Pedido pelo link: cardápio digital público, montar a pizza (meio a meio, borda), entrega por bairro, pagamento na entrega | sistema | grande |
| B | M04 · Fila de pedidos em tempo real + comanda pelo navegador | sistema | médio |
| C | M07 · CRM: oportunidades do dia e mensagens por WhatsApp (o motor já está provado em SQL) | sistema | médio |
| D | Cardápio dentro do backup da loja | servidor | pequeno |
| E | Cardápio na busca rápida (Ctrl+K) e na barra do celular | tela | pequeno |
| F | Ligar o domínio ao site e ao sistema (depois do D1) | Cloudflare/Lovable | pequeno |

## 🙋 Depende do dono
| # | Item | Por quê | Recomendação |
|---|---|---|---|
| D1 | Registrar pizzalia.com.br e pizzalia.app | o nome pode ser registrado por outra pessoa | registrar hoje |
| 2FA | Ativar o código no seu login | sem isso o roteiro não libera o painel Contera | 5 minutos, passo a passo enviado |
| MP | Conta e chaves do Mercado Pago | cobrar a mensalidade e o Pix online | quando for vender (a conciliação está pausada até lá) |
| R2 | Cópia do backup fora do Supabase (Cloudflare R2) | segurança se o Supabase falhar | posso tentar criar pela conta Cloudflare conectada |
| Fiscal | Emissor parceiro (NFC-e) e certificado A1 | nota fiscal é do plano Premium | decidir o parceiro antes de vender o Premium |
| Resend | Chave de e-mail | e-mails do sistema (cadastro, relatórios, cópia semanal) | junto com o domínio |
| Cadastro | Abrir o cadastro sozinho (chaves do "não sou robô") | lançamento | no lançamento |
| D2 | INPI | proteger a marca | pesquisar em busca.inpi.gov.br |
| D3 | @pizzalia no Instagram | marca | criar |
| D8 | Encarregado de dados e revisão jurídica | LGPD e contratos | escolher e mandar ao jurídico |
