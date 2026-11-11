# Pizzaria piloto fictícia: Forno da Vila (DEMO)

Como ainda não há pizzaria real, a Contera será o próprio piloto, com uma pizzaria
**inteiramente fictícia** cadastrada no sistema. Ela serve para testar cada fase, demonstrar o
produto a clientes e alimentar o teste grátis.

## Como gerar
```bash
python demo/gerar_dados_demo.py                 # data de hoje
python demo/gerar_dados_demo.py --hoje 2026-11-08 --semente 42   # resultado reproduzível
```
O script gera os CSVs em `demo/saida/` (fora do git, porque são regeneráveis), **com os mesmos
nomes de tabelas e colunas do modelo de dados do PRD** (seção 13), e imprime uma **prévia do motor
de oportunidades** (PRD, seção 10) rodando sobre esses dados.

```bash
python demo/gerar_dados_demo.py --hoje 2026-11-08 --verificar   # confere com o gabarito
```
- **Gabarito:** `demo/gabarito_2026-11-08.txt` é a saída esperada (semente 42). Quando o motor
  real existir em SQL, ele precisa produzir exatamente o mesmo resultado. Regra mudou no PRD →
  muda no gerador → gabarito regenerado no mesmo commit.
- **Testes de fronteira:** a cada execução, o script confere os limites exatos de cada gatilho
  (24/25, 59/60, 180/181 dias etc.) e para com erro se alguma regra sair do especificado.

## O que é gerado
| Item | Conteúdo |
|---|---|
| Pizzaria | "Pizzaria Forno da Vila (DEMO)", Campinas/SP, slug `forno-da-vila-demo` |
| Tabelas geradas | `tenants`, `users`, `categories`, `pizza_sizes`, `flavors`, `flavor_prices`, `addon_groups`, `addons`, `products`, `delivery_zones`, `customers`, `customer_addresses`, `marketing_consents`, `orders`, `order_items`, `order_item_flavors`, `order_item_addons` |
| Equipe | Dono, Caixa, Atendente, Cozinha (e-mails `@demo.invalid`) |
| Cardápio | 4 tamanhos (Broto a Família, até 3 sabores), 20 sabores com preço por tamanho, 3 bordas, 5 bebidas |
| Entrega | 12 bairros de Campinas com taxa e tempo extra |
| Clientes | 900, em 7 perfis de comportamento (semanal, quinzenal, mensal, esporádico, compra única, "sumiu", novo), ~55% com autorização de marketing, ~40% com aniversário cadastrado |
| Pedidos | ~5.600 em 6 meses (~29/dia), pico entre 20h e 21h, mais pedidos de sexta a domingo, meio a meio, bordas, bebidas, 3% cancelados |

Resultado com `--hoje 2026-11-08` (gabarito): 45 clientes frequentes fora do ritmo, 47 que
passaram de 25 dias sem pedir, 25 que compraram uma vez e não voltaram, 100 inativos há mais de
60 dias e 1 aniversariante, ou seja **218 oportunidades**. Outros **248** ficariam de fora por
falta de autorização para mensagens, que é o risco nº 2 do PRD aparecendo nos números.

**O que a simulação já corrigiu antes de existir tela:** (1) o título do cartão mostrava só os 30
exibidos, e não o total; (2) o aniversário usava o texto da campanha de inativo; (3) a frase
"Vimos que a Frango com Catupiry…" soava errada; (4) **lacuna de regra:** clientes entre 31 e 59
dias sem pedir não caíam em nenhum gatilho: eram 50 clientes com autorização invisíveis na base demo (37 com 2 ou mais pedidos e 13 de compra única).

## Gestão da pizzaria demo (`demo/gerar_gestao_demo.py`)
Sobre os MESMOS pedidos (o gabarito do CRM não muda), gera 18 tabelas: fornecedores, insumos, ficha técnica, compras,
estoque (entradas, saídas, inventário com perdas), caixa (sessões, pagamentos em dinheiro, sangrias, fechamentos com
diferença em 24 de 179 dias), contas a pagar (fixas, compras, entregadores, DAS), contas a receber (cartão e vale com
taxa e prazo), extrato bancário (com 2 lançamentos para conciliar), entregadores e entregas, mesas e comandas do salão
e notas fiscais de EXEMPLO. A DRE de cada mês é o gabarito (`demo/gabarito_gestao_2026-11-08.txt`): CMV perto de 30%,
taxas de cartão perto de 1%, margem de 18% a 25% nos meses cheios.

O que as travas do gerador já pegaram: estoque que ficaria negativo num pico de fim de semana (a regra de compra
ganhou margem); cartão contado como dinheiro na gaveta; o 1º mês cobrando despesas fixas inteiras com 3 semanas de
venda.

Carregador e usuário de teste: `db/seed/LEIAME.md`.

## Regras de segurança dos dados de demonstração
1. Todo registro leva `is_demo = true` e a pizzaria demo tem um `tenant_id` próprio. **Nunca**
   misture dados demo com uma pizzaria real.
2. Telefones na faixa fictícia `+55 19 900xx-xxxx` e e-mails no domínio reservado `.invalid`.
   Mesmo assim, o envio de campanha a partir da pizzaria demo fica **desabilitado no sistema**.
3. Nenhum pedido com data futura (o script verifica). Para manter a demo "viva", o script é
   rodado de novo com a data do dia em vez de inserir pedidos no futuro.
4. Remoção da demo: apagar pelo `tenant_id` da pizzaria demo, nunca por filtro genérico.

## Próximo passo
Na Fase 0 (banco de dados), estes CSVs ganham um carregador (`supabase/seed`) que insere tudo na
pizzaria demo. A partir daí, cada tela nova é testada sobre esses dados.
