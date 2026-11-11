# Motor do CRM em SQL (Pizzalia)

O núcleo do diferencial da Pizzalia (PRD §10 e §11.6), escrito **antes da base remixada** e independente dela.

| Arquivo | O que é |
|---|---|
| `01_motor_crm.sql` | Tabelas (`crm_regras`, `crm_customer_stats`, `crm_oportunidades`, `crm_contatos`), regras puras (`crm_gatilho`, `crm_dias_ate_aniversario`) e o motor `crm_calcular(loja, dia)`. Idempotente, só aditivo, sem policy de DELETE |
| `02_adaptador_demo.sql` | As 3 visões de contrato (`crm_fatos_pedido`, `crm_fatos_cliente`, `crm_fatos_em_andamento`) para a pizzaria demo |
| `03_testes_fronteira.sql` | 17 fronteiras de gatilho, 4 de aniversário e 8 cenários (consentimento, revogação, descanso de 6/7 dias, idempotência, conversão, voltou sozinho, cartão único, expiração). Termina em ROLLBACK |
| `04_campanhas.sql` | Modelos de mensagem (plataforma + loja), `crm_mensagem` (texto sem campo vazio + link wa.me), `crm_registrar_contato`, `crm_desfazer_contato` (10 min), `crm_descartar` |
| `05_resumo.sql` | `resumo_hoje`: pedidos × mesmo dia da semana passada, vendas, valor médio, resultado das mensagens e até 3 itens de atenção, em frases |
| `06_testes_campanhas.sql` | Mensagens, variantes, modelo da loja, frases do resumo, envio, toque duplo, "não enviei", prazo, descarte, outra loja, conversão |
| `testar_motor.sh` | Prova completa num banco descartável: compara o motor com `demo/gabarito_oportunidades_2026-11-08.csv`, cliente a cliente. `--sabotar` exige que a regra antiga seja acusada |

**Resultado (11/11/2026, PostgreSQL 16):** 466 oportunidades e 218 mensagens (texto e link) idênticas ao gabarito; testes e sabotagem OK.

## Quando a base (MayFlower remixado) chegar
1. Escrever `02_adaptador_mayflower.sql`: as mesmas 3 visões a partir das tabelas da base (vendas concluídas, pedidos
   online, clientes, consentimento) — o motor não muda.
2. Ligar a RLS: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` nas 4 tabelas `crm_*`, com leitura por
   `store_id = (select public.current_store_id())`; escrita de oportunidade e contato só por RPC; nenhuma policy de DELETE.
3. Agendar `crm_calcular` por loja entre 03:00 e 06:00 (Brasília), escalonado (AD-12), pela fila de jobs da base.
4. Rodar o gabarito de novo sobre a base com os dados demo carregados: precisa dar o mesmo resultado.
