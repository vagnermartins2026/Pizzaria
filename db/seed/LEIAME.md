# Carregador da pizzaria demo + usuário de teste (Pizzalia)

Objetivo: o dono entrar com um **usuário de teste (papel Dono)** e ver a pizzaria fictícia **Forno da Vila (DEMO)**
funcionando com dados em todos os módulos.

## O que já está pronto e provado
| Peça | Arquivo | Prova (11/11/2026) |
|---|---|---|
| Dados do CRM, cardápio e pedidos | `demo/gerar_dados_demo.py` | gabaritos de oportunidades e mensagens |
| Dados de gestão (18 tabelas) | `demo/gerar_gestao_demo.py` | `demo/gabarito_gestao_2026-11-08.txt` (DRE mês a mês) e travas: estoque nunca negativo, nada no futuro, saldo bancário fecha |
| Carregador dos módulos próprios (cardápio, pedidos, entrega, link, CRM) | `01_carregar_pizzalia_demo.sql` | `testar_seed.sh`: 5.631 pedidos, 10.403 itens, totais idênticos, 2ª carga não duplica, CRM sobre os pedidos carregados idêntico ao gabarito |
| Usuário de teste | `demo/criar_usuario_teste.ts` | senha forte testada; criação real só no remix (precisa do Supabase) |

## O que entra no dia do remix (depende da base)
1. **Adaptador da base** (`02_adaptador_<base>.sql`): `current_store_id()`, `pizzalia_papel()`, as visões do CRM
   lendo o cadastro de clientes da base e a função `pizzalia_vincular_usuario_demo(p_user, p_store, p_papel)`.
2. **Módulos da base** a partir das tabelas de apoio `demo_gestao_*` (já carregadas como texto):

| Dados demo | Destino na base (MayFlower, nomes de hoje) | Observação |
|---|---|---|
| clientes, consentimentos | `customers` | consentimento de marketing: conferir campo/tabela |
| fornecedores | `suppliers` | |
| insumos, estoque (entradas, saídas, inventário), saldos | `products`, `stock_movements`, `inventory_counts` / `inventory_count_items`, `stock_adjustments` | insumo = produto de uso interno |
| compras e itens | `purchases`, `purchase_items` | |
| contas a pagar (fixas, compras, entregadores, DAS) | `accounts_payable`, `fixed_expenses`, `financial_categories` | |
| contas a receber (cartão e vale, com taxa) | `accounts_receivable`, `card_machines` | |
| caixa (sessões, dinheiro, sangrias) | `cash_registers`, `cash_movements` | contado nunca nulo |
| extrato bancário (com 2 lançamentos para conciliar) | — no MayFlower; conciliação vem do RED Adega (Premium) | |
| entregadores e entregas | — módulo novo M10 | |
| mesas e comandas | — módulo novo M17 | |
| ficha técnica | — módulo novo M15 | CMV por pizza |
| notas fiscais de exemplo | — módulo novo M12 | "EXEMPLO — NÃO EMITIDA", série 900 |

3. Rodar `01_carregar_pizzalia_demo.sql`, o carregador dos módulos da base e `criar_usuario_teste.ts`.
4. Conferir pelo site: entrar com o usuário de teste e abrir cada módulo.

## Feito em 13/11/2026 (base = remix da MayFlower, Supabase `tsidqofldtkkgexbmtor`)
| Passo | Como | Prova |
|---|---|---|
| Login de teste (papel Dono) | API de administração do Auth, com o id FIXO da loja demo (na base, id da loja = id da dona); e-mail `dono.demo@pizzalia.invalid` | login pelo site: entra no Início da "Forno da Vila (DEMO)" |
| Planos e loja | `montar_carga_base.py` → `00_planos_e_loja.sql`: 3 planos × mensal/anual (desligados), loja pelos MESMOS passos do cadastro da base, assinatura Premium até 31/12/2027 | loja ativa, Dona, 4 módulos ligados |
| Dados nas telas da base | `montar_carga_base.py` (CSVs → vendas, itens, pagamentos, clientes, produtos, caixa, contas, compras, estoque) | `testar_carga_base.sh` (banco local como remix novo): contagens = resumo, 2ª carga não duplica, venda = itens = pagamentos, caixa fecha, nada no futuro, a dona vê tudo e outra pessoa 0; sabotagem (some 1 item) reprovada |

Números da carga de 13/11: 6.142 vendas (5.973 concluídas), 17.134 itens, 900 clientes, 129 produtos, 181 caixas, 444 contas a pagar,
2.670 a receber, 259 compras, 8.326 movimentos de estoque; DRE pelo site: set. lucro R$ 31.134, out. R$ 24.601 (CMV ~25%); nov. parcial.
`demo/criar_usuario_teste.ts` ficou sem uso (o vínculo é o gatilho da base, não a RPC `pizzalia_vincular_usuario_demo`).
Ainda não entraram: os módulos próprios (cardápio de pizza, pedidos pelo link, CRM) — sem tela na base ainda.

## Remoção da demo
Sempre pelo `store_id` da loja demo (`1e45234c-bd80-52ab-b4e0-983c9d2eee6b`), nunca por filtro genérico; o login de
teste é apagado pelo painel do Supabase.
