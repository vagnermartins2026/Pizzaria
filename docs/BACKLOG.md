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
| 15 | Regra de ouro: 7 avisos à MayFlower (2 erros reais confirmados e corrigidos lá: backup por e-mail e página pública travada) | mensagens às sessões |
| 16 | M03 · Pedido pelo link publicado (/pedir/forno-da-vila-demo): preço recalculado no servidor, sem duplicar | PR #7; pedido de teste R$ 75,90 |
| 17 | Correção: página pública travava em "Carregando" (1ª resposta do login limpava o cache) | PR #8; conferido no ar |
| 20 | M04 · Fila de pedidos no ar: tempo real, balcão/telefone, comanda, pedido → venda (pedido nº 2 virou a venda 6143, R$ 79,90, no caixa aberto) | PR #12; rush 30/30 |
| 21 | Pedido completo pela tela do link no celular (R$ 79,90) e planos do fiscal corrigidos | PR #11 |
| 19 | M12 · Nota fiscal NFC-e no ar e desligada (sem a chave do emissor responde "emissor não configurado"); tela Notas fiscais e aba Fiscal | PR #10; 1.032 testes de banco |
| 18 | M07 · CRM publicado: 254 clientes para chamar hoje, link de pedidos nas mensagens, 492 autorizações | PR #9; gabarito 466/218 idêntico |

## 🔧 Falta e eu faço sozinho (ordem recomendada)
| # | Item | Onde | Esforço |
|---|---|---|---|
| A | ✅ feito (item 16) · M03 · Pedido pelo link | sistema | — |
| B | ✅ feito (item 20) · M04 · Fila de pedidos | sistema | — |
| G | ✅ feito (itens 19 e 21) · M12 · NFC-e | sistema | — |
| H | Pix online no link (Mercado Pago) — depois do M04 | sistema | médio |
| I | Cardápio, pedidos, CRM e notas dentro do backup da loja | servidor | médio |
| J | Página pública do link mais leve no celular (hoje ~9 s em 4G lento; base do app e 7 famílias de fonte herdadas) | tela | médio |
| C | ✅ feito (item 18) · M07 · CRM | sistema | — |
| E | Cardápio na busca rápida (Ctrl+K) e na barra do celular | tela | pequeno |
| F | Ligar o domínio ao site e ao sistema (depois do D1) | Cloudflare/Lovable | pequeno |

## 🙋 Depende do dono
| # | Item | Por quê | Recomendação |
|---|---|---|---|
| D1 | Registrar pizzalia.com.br e pizzalia.app | o nome pode ser registrado por outra pessoa | registrar hoje |
| 2FA | Ativar o código no seu login | sem isso o roteiro não libera o painel Contera | 5 minutos, passo a passo enviado |
| MP | Conta e chaves do Mercado Pago | cobrar a mensalidade e o Pix online | quando for vender (a conciliação está pausada até lá) |
| R2 | Cópia do backup fora do Supabase (Cloudflare R2) | segurança se o Supabase falhar | AUTORIZADO em 13/11 ("PODE CRIAR O R2"), mas TRAVADO: a chave da Cloudflare desta sessão não tem permissão de R2 nem de criar chaves (Authentication error / Unauthorized). Falta o dono ampliar a permissão (opção A) ou criar o bucket e a chave no painel (opção B) |
| MP-pausa | A conciliação do Mercado Pago está PAUSADA (cron mp-reconcile-30min) até existirem as chaves | evitava um alarme crítico a cada 30 min | religar junto com o MP: `cron.alter_job(..., active := true)` |
| Fiscal | Emissor parceiro (NFC-e) e certificado A1 | nota fiscal é do plano Premium | decidir o parceiro antes de vender o Premium |
| Resend | Chave de e-mail | e-mails do sistema (cadastro, relatórios, cópia semanal) | junto com o domínio |
| Cadastro | Abrir o cadastro sozinho (chaves do "não sou robô") | lançamento | no lançamento |
| D2 | INPI | proteger a marca | pesquisar em busca.inpi.gov.br |
| D3 | @pizzalia no Instagram | marca | criar |
| D8 | Encarregado de dados e revisão jurídica | LGPD e contratos | escolher e mandar ao jurídico |

## ❓ Decisões de negócio deixadas pelos módulos (todas já com o padrão recomendado em uso; o dono só confirma ou muda)
| # | Decisão | Padrão em uso |
|---|---|---|
| N1 | Preço da pizza de vários sabores | o sabor mais caro (a loja pode escolher a média) |
| N2 | Pizzaria sem horário cadastrado no link | aceita pedido quando o link está ligado e sem pausa |
| N3 | Aniversariante sem nenhum pedido entra no CRM? | não entra (igual à especificação) |
| N4 | Texto da autorização de marketing (versão "v1") | o da especificação |
| N5 | Cardápio com mensalidade atrasada | só consulta, como as outras telas de gestão |
| N6 | NFC-e com a loja suspensa | continua emitindo (obrigação legal) |
| N7 | Como cobrar o módulo fiscal avulso (R$ 79) | hoje só liga o módulo; cobrança separada não existe |

