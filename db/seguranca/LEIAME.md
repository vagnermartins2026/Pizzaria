# Pacote de segurança (Fornalia)

Regras de acesso (RLS) e permissões para `db/crm` e `db/pedidos`, prontas para ligar no dia do remix.

**Pré-requisito (contrato da base):** `public.current_store_id()` (loja ativa do usuário) e `public.fornalia_papel()`
(`dono`, `gerente`, `atendente`, `cozinha`, `entregador`, `suporte`). Sem elas o pacote se recusa a rodar.

| Regra | Como |
|---|---|
| Cada loja só vê o que é seu | Leitura por `store_id = (select public.current_store_id())` em todas as tabelas (calculado uma vez por consulta) |
| Cardápio e configuração | Só dono/gerente incluem e alteram; ninguém apaga (desativa); turno de horário pode ser apagado |
| Pedido | Só nasce por RPC (`pedido_criar_balcao` na equipe; `pedido_criar` só servidor, para o link); a equipe muda status e liga o cliente; valores nunca |
| Depois de "saiu para entrega" | Só o dono cancela |
| Pausar pedidos / tempo estimado | Qualquer pessoa da equipe, só na própria loja (`loja_ajustar_operacao`) |
| Movimento (pedidos, histórico, oportunidades, contatos) | Nenhuma policy de DELETE; escrita só por RPC/servidor |
| Anônimo | Nenhum acesso direto (o link público passa pela Edge Function com service_role) |
| Motor do CRM | Só o servidor (`crm_calcular`) |

**Prova (11/11/2026):** `testar_seguranca.sh` simula o pior caso do Supabase (anon e authenticated com TODOS os
privilégios antes do pacote), aplica o pacote duas vezes (idempotente) e testa atendente, gerente, dono, anônimo e
cobertura (toda tabela com RLS, sem DELETE em movimento, visões `security_invoker`). Sabotagem (leitura de pedidos
aberta a todos) acusada: "vazamento: a loja A enxerga pedidos de B".

`db/testar_tudo.sh` roda as três provas (CRM, pedidos, segurança) de uma vez.
