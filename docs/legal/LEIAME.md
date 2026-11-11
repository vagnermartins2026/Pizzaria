# Documentos legais do sistema (RASCUNHO para revisão jurídica)

| Arquivo | O que é |
|---|---|
| [`TERMOS-DE-USO-DO-SISTEMA.md`](./TERMOS-DE-USO-DO-SISTEMA.md) | Contrato de assinatura entre a pizzaria e a Pizzalia |
| [`POLITICA-DE-PRIVACIDADE-DO-SISTEMA.md`](./POLITICA-DE-PRIVACIDADE-DO-SISTEMA.md) | Como os dados são tratados (LGPD), separando o dono da pizzaria e os clientes dele |

**Não são texto final.** Foram escritos a partir do PRD e do plano de negócio para adiantar o trabalho do
jurídico. Os trechos entre colchetes, como `[RAZÃO SOCIAL]`, faltam preencher. Os marcados com **⚖️ DECIDIR**
são escolhas do dono (lista abaixo, também no backlog, D8).

O site publica hoje só os termos curtos do pré-lançamento (`site/src/pages/Legais.tsx`). Estes entram no site
e no cadastro do sistema **antes** de abrir a cobrança.

## Decisões em aberto
| # | Decisão | Sugestão do rascunho |
|---|---|---|
| L1 | Garantia de devolução no primeiro pagamento? (a Minha Maleta tem 7 dias) | 7 dias, igual à Minha Maleta |
| L2 | Cancelamento do plano anual: devolve o proporcional? | Devolve o proporcional dos meses inteiros não usados, menos o desconto do anual |
| L3 | Por quanto tempo os dados ficam disponíveis para exportar depois do cancelamento | 90 dias (o mesmo prazo do PRD para módulo desligado) |
| L4 | Foro (cidade do processo, se houver) | Campinas/SP |
| L5 | Quem é o encarregado de dados (DPO) e o e-mail dele | A definir |
| L6 | Onde ficam os servidores (afeta a cláusula de transferência internacional) | Confirmar a região do banco ao criar o projeto |
