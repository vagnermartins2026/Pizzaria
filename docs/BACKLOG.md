# Backlog da Pizzalia (atualizado em 17/11/2026)

Sistema publicado: https://pizzalia.lovable.app (versão `mwm8pm9r`, commit `085b8ec0` da main do `vagnermartins2026/pizzalia`).
Retomada da próxima sessão: `docs/PASSAGEM_DE_SESSAO.md`.
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
| 22 | H · Pix online no link no ar e desligado: sem as chaves do Mercado Pago da loja, o "Pix agora" não aparece e o pedido com Pix é recusado com aviso claro; pedido de teste nº 3 (R$ 67,90) criado, clique duplo sem duplicar, página do pedido no celular sem erro, depois cancelado | PR #13; banco 1060/1060, tela 3247/3247, 30/30 sabotagens; migration 192 aplicada; funções pedido-link (v4) e pedido-link-aviso (v1) |
| 23 | I · Cardápio, pedidos, fila, CRM, fiscal e cobranças do Pix dentro do backup da loja (3.14.0). Corrigido: pizzaria com 1 pedido concluído não conseguia restaurar nenhum backup; evitado: pedido pago por Pix derrubaria a restauração | PR #14; banco 1068/1068, tela 3247/3247, 11/11 sabotagens; migration 193 aplicada; daily-backup v12; backup real da demo com sucesso (20 sabores, 3 pedidos, 522 autorizações) |
| 24 | E · Barra do celular com Início, Pedidos e Cardápio (Vendas e Estoque de reserva) e busca rápida (Ctrl+K) que acha sabores e itens e oferece "Novo pedido (balcão ou telefone)" | PR #15; tela 3254/3254; 7 testes falham no antigo; conferido no código publicado (o login de teste no ar foi barrado pelo controle de permissões da sessão) |
| 25 | J (1ª parte) · Link de pedidos pede o cardápio no primeiro instante: no 4G lento o pedido do cardápio saía aos 5,8 s e agora sai em 1,2–1,5 s; cardápio na tela em 5,0–5,7 s (antes 6,3–7,0 s no mesmo teste) | PR #16; tela 3260/3260; medido no ar, sem erro na página |
| 26 | J2 · Link de pedidos baixa só o que usa: no build, de 61 arquivos/895 kB para 42/481 kB; no ar, 4G lento: cardápio na tela em 3,3–3,9 s (eram 6,3–7,0 s antes do J). Corrigido na conferência cega: navegar do sistema para /pedir sem recarregar derrubaria a tela | PR #17; tela 3268/3268; pedido nº 4 feito pela tela do celular no ar (depois cancelado); tela de entrar sem erro |
| 27 | Regra de ouro ao contrário (achado da MayFlower): registro na Saúde e tratador de falhas já na partida, fora do link de pedidos (numa aba antiga depois de publicar, o registro se perdia) | PR #18; tela 3268/3268; teste falha sem a correção; no ar `mwm8pm9r` (/pedir sem a Saúde, /login com ela, sem erros) |
| 18 | M07 · CRM publicado: 254 clientes para chamar hoje, link de pedidos nas mensagens, 492 autorizações | PR #9; gabarito 466/218 idêntico |

## 🔧 Falta e eu faço sozinho (ordem recomendada)
| # | Item | Onde | Esforço |
|---|---|---|---|
| A | ✅ feito (item 16) · M03 · Pedido pelo link | sistema | — |
| B | ✅ feito (item 20) · M04 · Fila de pedidos | sistema | — |
| G | ✅ feito (itens 19 e 21) · M12 · NFC-e | sistema | — |
| H | ✅ feito (item 22) · Pix online no link | sistema | — |
| I | ✅ feito (item 23) · Módulos novos dentro do backup | servidor | — |
| J2 | ✅ feito (item 26) · Página pública mais leve | tela | — |
| C | ✅ feito (item 18) · M07 · CRM | sistema | — |
| E | ✅ feito (item 24) · Cardápio e fila nos atalhos | tela | — |
| F | Ligar o domínio ao site e ao sistema (depois do D1) | Cloudflare/Lovable | pequeno |

| K | Regra de ouro (sem urgência): o filtro de `roda-sabotagens.sh` da MayFlower lê "aprovado" como "prova" (corrigido aqui no PR #13); lá nenhum teste é afetado hoje, por isso não houve aviso | — | — |

| K2 | ✅ Técnica do J2 levada aos outros sistemas (pedido do dono, 18/11) — ver a tabela "Página pública leve nos outros sistemas" abaixo | — | — |

## 🌐 Página pública leve nos outros sistemas (18/11/2026)
| Sistema | Página da cliente | Antes (no ar) | Depois | Situação |
|---|---|---|---|---|
| Minha Maleta | /guias, /termos, /parceiras, /privacidade, guias | 704–710 kB | 226–378 kB | ✅ NO AR (PR #184, `ae5473b`); auditoria no ar ok; registro em `docs/qa/99_POS_DEPLOY.md` da Maleta |
| MayFlower | portal de pontos (/meus-pontos) | 770 kB | 513 kB | ✅ NO AR pela sessão da MayFlower (PR #78 de lá, `0fab2f58`); a conferência cega dela achou a falta do registro na Saúde na partida, corrigido lá e aplicado aqui (item 27) e na Gloss |
| Gloss Club | agendamento online e portal de pontos | 1.086–1.114 kB | 631–655 kB | 🟡 na `main` (`7a98344`, com o registro na Saúde já na partida), NÃO publicado: o salão estava funcionando; publicação agendada para 18/11 20h41 com o salão parado |
| Cantina da Ná | portal de pontos | 831 kB | — | ⏸️ não aplicar por decisão do dono (18/11); anotado nas pendências da Cantina (`projeto/CONTINUIDADE.md`) |
| Loja online MayFlower (em breve) | site | 453 kB | — | já enxuto, nada a fazer |
| Red Adega, Fourteen, Cafuné, Contábil Hub | — | — | — | sem página pública para cliente (só telas com login) |
| CRM e BI, Financeiro V4, Portal do Franqueado, Central de Chamados, Espetinhos (demo) | — | — | — | não medidos; pelo tipo, só telas com login |

## 🙋 Depende do dono
| # | Item | Por quê | Recomendação |
|---|---|---|---|
| D1 | Registrar pizzalia.com.br e pizzalia.app | o nome pode ser registrado por outra pessoa | registrar hoje |
| 2FA | Ativar o código no seu login | sem isso o roteiro não libera o painel Contera | 5 minutos, passo a passo enviado |
| MP | Conta e chaves do Mercado Pago | cobrar a mensalidade e o Pix online (para ligar o Pix de uma pizzaria: as chaves dela nos segredos do servidor, `PEDIDO_LINK_<ID DA LOJA>_MP_ACCESS_TOKEN` e `_MP_WEBHOOK_SECRET`, e o aviso do Mercado Pago apontando para a função `pedido-link-aviso`) | quando for vender (a conciliação está pausada até lá) |
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

