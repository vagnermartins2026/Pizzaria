# Cardápio, pedido, entrega e horário em SQL (Fornalia)

Escrito antes da base remixada e independente dela (usa só `store_id`). Prefixos próprios (`cardapio_*`, `pedido*`,
`loja_*`) para não colidir com `products`, `loja_pedidos` e `sales` do MayFlower.

| Arquivo | O que é |
|---|---|
| `01_cardapio_pedido.sql` | Cardápio (tamanhos, sabores com preço por tamanho, adicionais com limite por grupo e preço por tamanho, itens), `cardapio_preco_item` (maior sabor ou média ↑), `pedido_criar` (recalcula tudo, idempotência, número por loja sem buraco, telefone E.164, cópia de nome/preço), máquina de estados no banco, imutabilidade, `cardapio_publico` |
| `02_entrega_horario.sql` | Horários (turno que passa da meia-noite, vários turnos por dia), `loja_status_link` (próxima abertura), bairros com nome normalizado, pausa, pedido mínimo só na entrega. Substitui `pedido_validar_operacao` |
| `03_testes_cardapio.sql` / `04_testes_entrega.sql` | Cenários e fronteiras; terminam em ROLLBACK |
| `carregar_demo.sql` | Carrega a pizzaria demo e confere os gabaritos de preço e de frete |
| `testar_pedidos.sh` | Prova completa num banco descartável (+ 40 pedidos simultâneos). `--sabotar` exige que a regra errada seja acusada |

**Resultado (11/11/2026, PostgreSQL 16):** 10.403 itens com preço idêntico ao gerador (7.294 pizzas); 4.246 entregas
com frete idêntico; todos os cenários OK; 40 chamadas simultâneas → números 1 a 30 sem buraco; sabotagens de preço e
de horário acusadas.

## Pendências para quando a base chegar
1. **RLS** em todas as tabelas `cardapio_*`, `loja_*`, `pedido*`: leitura por `store_id = (select public.current_store_id())`;
   escrita do cardápio só para dono/gerente; pedido só por `pedido_criar` (Edge Function do link com limite de
   requisições, ou PDV); nenhuma policy de DELETE.
2. **Papéis:** depois de "saiu para entrega", só o dono cancela (PRD §9) — depende do papel da base.
3. **Ligar ao caixa e ao cliente da base:** pagamento do pedido entra no caixa aberto; `customer_id` liga ao cadastro
   pelo telefone; o adaptador do CRM passa a ler `pedidos` concluídos.
4. **Decidido (11/11/2026): dia de negócio = dia do turno** (`loja_dia_negocio`). Pedido das 00:15 no turno de sexta conta como sexta.
