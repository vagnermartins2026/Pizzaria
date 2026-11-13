# Status do sistema Pizzalia (13/11/2026)

Base: remix da MayFlower adaptado ao TanStack · repositório `vagnermartins2026/pizzalia` (main) · Supabase `tsidqofldtkkgexbmtor`
(conta "Contera 7º", plano grátis) · projeto do Lovable `b36cc75c-682a-4876-92b5-62b9a921a918` (ainda NÃO publicado).

## Feito e verificado
| Item | Prova |
|---|---|
| 186 migrations aplicadas e anotadas em `supabase_migrations` | ensaio em transação desfeita + aplicação 186/186; 77 tabelas com RLS |
| 18 funções do servidor publicadas (verify_jwt do config.toml) | cada uma chamada sem login: recusa ou pede dados, nenhuma quebra |
| Planos Essencial/Profissional/Premium (mensal e anual, desligados) | `db/seed/montar_carga_base.py` → `00_planos_e_loja.sql` |
| Loja demo "Forno da Vila (DEMO)" + login de teste (Dono) + dados em todas as telas | `db/seed/testar_carga_base.sh` (local) e login real pelo site |
| Correção do laço do `<Navigate>` da ponte TanStack (a tela travava depois do login) | PR #2 do pizzalia; teste `ponte-navigate-uma-vez` (30 → 1 navegação) |
| Marca Pizzalia no sistema: nome da plataforma, ícones (logo A, a fatia), cor #C2361C, título da aba | PR #3; 3.112 testes; 3 funções republicadas (v6) |

## Atenção: juntar na main = publicar no servidor
A integração do Supabase com o GitHub publica sozinha as 18 funções a cada junção na `main` (versões 3 a 5 apareceram sem
publicação manual; o verify_jwt do config.toml foi mantido). Pela mesma integração, migration nova na `main` provavelmente é
aplicada no banco na hora. Regra daqui em diante: migration só entra na `main` depois do teste local (harness), do ensaio no banco
real em transação desfeita e da conferência dos testes de isolamento.

## Decisões do dono em 13/11
- **1A:** o Claude cria o login do dono (administrador geral). Feito: login criado com senha provisória (troca obrigatória no 1º
  acesso), vínculo de administrador na loja demo (sem loja própria). Falta o dono ativar o segundo fator; depois o Claude roda
  `scripts/master/criar-admin-geral.sql` (o roteiro recusa quem não tem o segundo fator).
- **2A:** os módulos próprios da pizzaria (cardápio de pizza, pedido pelo link, CRM) entram JUNTO com a primeira tela de cada um,
  na próxima etapa. Ordem proposta (PRD §15, R1): M02 cardápio e configuração → M03 link de pedidos → M04 fila de pedidos → M07 CRM. M02 em construção
  desde 13/11 ("adiante tudo o que conseguir"), na branch `claude/cardapio-pizza`.
- **3A:** o lucro de novembro da demo fica como está (mês parcial: as contas fixas já pagas, só 13 dias de venda).

## Pendências do dono
D1 domínios (urgente) · ativar o segundo fator no login dele · D2 INPI · D3 Instagram · D8 jurídico · frase do Publish ·
depois do Publish: APP_URL nas funções · chaves do Mercado Pago (quando for cobrar).
