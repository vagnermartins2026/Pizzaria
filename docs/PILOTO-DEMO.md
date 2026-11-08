# Pizzaria piloto fictícia: Forno da Vila (DEMO)

Como ainda não há pizzaria real, a Contera será o próprio piloto, com uma pizzaria
**inteiramente fictícia** cadastrada no sistema. Ela serve para testar cada fase, demonstrar o
produto a clientes e alimentar o teste grátis.

## Como gerar
```bash
python demo/gerar_dados_demo.py                 # data de hoje
python demo/gerar_dados_demo.py --hoje 2026-11-08 --semente 42   # resultado reproduzível
```
O script gera os CSVs em `demo/saida/` (fora do git, porque são regeneráveis) e imprime uma
**prévia do motor de oportunidades** (PRD, seção 10) rodando sobre esses dados.

## O que é gerado
| Item | Conteúdo |
|---|---|
| Pizzaria | "Pizzaria Forno da Vila (DEMO)", Campinas/SP, slug `forno-da-vila-demo` |
| Equipe | Dono, Caixa, Atendente, Cozinha (e-mails `@demo.invalid`) |
| Cardápio | 4 tamanhos (Broto a Família, até 3 sabores), 20 sabores com preço por tamanho, 3 bordas, 5 bebidas |
| Entrega | 12 bairros de Campinas com taxa e tempo extra |
| Clientes | 900, em 7 perfis de comportamento (semanal, quinzenal, mensal, esporádico, compra única, "sumiu", novo), ~55% com autorização de marketing, ~40% com aniversário cadastrado |
| Pedidos | ~5.700 em 6 meses (~29/dia), pico entre 20h e 21h, mais pedidos de sexta a domingo, meio a meio, bordas, bebidas, 3% cancelados |

Resultado com `--hoje 2026-11-08`: o motor encontra 57 clientes frequentes fora do ritmo, 15
perto de 30 dias, 21 que compraram uma vez e não voltaram, 108 inativos há mais de 60 dias e
aniversariantes. Mostra também quantos ficaram de fora por falta de autorização: é o risco
nº 2 do PRD aparecendo nos números.

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
