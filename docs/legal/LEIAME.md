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
| # | Decisão | Situação |
|---|---|---|
| L1 | Garantia de devolução no primeiro pagamento | ✅ 7 dias (dono, 11/11/2026) |
| L2 | Cancelamento do plano anual | ✅ Devolve o proporcional dos meses inteiros não usados, menos o benefício do anual (dono, 11/11/2026) |
| L3 | Prazo para exportar os dados depois do cancelamento | ✅ 90 dias (dono, 11/11/2026) |
| L4 | Foro | ✅ Campinas/SP (dono, 11/11/2026) |
| L5 | Encarregado de dados (DPO) e o e-mail dele | ⏳ Dono indicar a pessoa (backlog D8) |
| L6 | Onde ficam os servidores (cláusula de transferência internacional) | ⏳ Claude confirma quando o banco do sistema for criado |

Empresa: VHM LABS LTDA, CNPJ 64.393.377/0001-30 (decisão D4, 11/11/2026). Falta a **revisão jurídica** dos dois textos.
