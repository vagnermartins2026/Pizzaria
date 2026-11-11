# Cadastro do sistema: o que o `/cadastro` precisa fazer

| Campo | Valor |
|---|---|
| Data | 2026-11-11 |
| Para quem | A sessão que constrói o sistema (base MayFlower remixada, `db/crm/LEIAME.md`) |
| Liga com | O site (`site/LEIAME.md`, "Contrato do cadastro") e o PRD (M01, seções 12.4 e 12.6, fase F9) |
| Situação | **Especificação pronta.** A construção depende da base do sistema (backlog do dono, D13) |

## 1. O caminho da pizzaria
```
site (www.pizzalia.com.br)  ──clique──▶  app.pizzalia.com.br/cadastro?plano=…&origem=site&utm_…&indicacao=…
        │                                        │
        │                                        ├─ 1. cria a conta do dono (e-mail, senha, WhatsApp)
        │                                        ├─ 2. cria a pizzaria (nome, cidade) e guarda a origem
        │                                        ├─ 3. abre o teste de 14 dias + a pizzaria demo separada
        │                                        ├─ 4. pede a verificação em duas etapas (MFA) do dono
        │                                        └─ 5. no fim do teste: assinatura (Mercado Pago)
        └─ lista de espera (enquanto o cadastro não existe)
```

## 2. O que chega do site
| Parâmetro | Valores | O que fazer |
|---|---|---|
| `plano` | `essencial`, `profissional`, `premium` | Deixar marcado na tela. Desconhecido ou ausente: deixar escolher. **O preço nunca vem da URL** |
| `origem` | `site` | Gravar na pizzaria criada |
| `utm_source`, `utm_medium`, `utm_campaign`, `utm_content` | texto (até 80 caracteres) | Gravar na pizzaria criada. É o que mede o custo por canal |
| `indicacao` | código do parceiro | Gravar e ligar ao parceiro (canal de contadores, plano de negócio, seção 8) |

Regras: ignorar qualquer outro parâmetro; limpar texto (sem HTML); a origem é gravada **uma vez**, na criação,
e nunca muda depois.

## 3. Regras de negócio (já decididas no PRD e no plano)
| # | Regra | Fonte |
|---|---|---|
| C1 | Teste grátis de **14 dias** com o **Profissional** (no que estiver liberado), sem cobrança | Plano de negócio, seção 5 |
| C2 | A **pizzaria demo** (Forno da Vila) é carregada como exemplo **separada** da conta real: outro `tenant_id`, `is_demo = true`, envio de campanha desligado | PILOTO-DEMO, regras 1 a 4 |
| C3 | O plano escolhido no site fica como **plano pretendido**: é ele que aparece na hora de assinar | Site, contrato do cadastro |
| C4 | **MFA obrigatória para o Dono** antes de ver dados de clientes | PRD 12.4 |
| C5 | Aceite dos **Termos de Uso** e da **Política de Privacidade** com versão, data e hora gravadas | LGPD; `docs/legal/` |
| C6 | Assinatura pelo **Mercado Pago** (cartão recorrente e Pix), webhook com assinatura verificada e **idempotente** | PRD 12.3 (AD-11) e 12.7 |
| C7 | Planos e módulos pelas tabelas de direitos (`plans`, `modules`, `subscriptions`, `tenant_modules`), checadas na tela, no servidor e nos jobs | PRD 12.6 |
| C8 | Sem fidelidade no mensal; anual com 2 meses grátis; reajuste anual pelo IPCA | Plano de negócio, seção 5 |
| C9 | Inadimplência nunca derruba o expediente nem um caixa aberto; pedidos, caixa e fiscal só param na etapa final | PRD 12.6 |

## 4. Critérios de aceitação (testáveis)
1. Abrir `…/cadastro?plano=premium&origem=site&utm_source=google&indicacao=ABC` → a tela abre com o Premium
   marcado; depois do cadastro, a pizzaria nova tem `origem=site`, `utm_source=google`, `indicacao=ABC`.
2. `…/cadastro?plano=qualquer-coisa` → nenhum plano marcado, sem erro.
3. Cadastro completo → existe 1 usuário dono, 1 pizzaria real e 1 pizzaria demo separada; o dono só vê a demo
   pelo seletor "Ver exemplo", e nenhum dado demo aparece na pizzaria real.
4. O teste termina exatamente 14 dias depois do cadastro (data de Brasília) e mostra o aviso 5 dias e 1 dia antes.
5. Webhook do Mercado Pago entregue 2 vezes → 1 único pagamento registrado.
6. Duas pizzarias criadas em sequência → nenhuma lê dado da outra (teste de RLS com dois usuários).
7. Sem aceite dos Termos → não cria a conta.
8. Dono sem MFA → não chega na lista de clientes.

## 5. Prompt pronto para a sessão do sistema
Copie e cole na sessão que está construindo o sistema da pizzaria:

```text
Implemente o cadastro de assinantes do sistema da Pizzalia (rota /cadastro), seguindo
docs/CADASTRO-DO-SISTEMA.md do repositório vagnermartins2026/Pizzaria (branch claude/sweet-faraday-9fvbeh).

Objetivo: a pizzaria que clica no site (pizzalia.com.br) cria a própria conta sozinha, entra no teste de
14 dias com a pizzaria demo separada e, no fim, assina pelo Mercado Pago.

Faça:
1. Leia o documento inteiro, o PRD (seções 12.4, 12.6, M01 e fase F9) e o docs/PILOTO-DEMO.md.
2. Aceite os parâmetros plano, origem, utm_source, utm_medium, utm_campaign, utm_content e indicacao
   exatamente como na seção 2; grave a origem na criação da pizzaria, uma vez só.
3. Cumpra as regras C1 a C9 da seção 3.
4. Escreva testes para os 8 critérios de aceitação da seção 4 e mostre todos passando.

Restrições: migration só aditiva e idempotente; nenhuma policy aberta; o preço nunca vem da URL;
nada de dado demo misturado com dado real; webhook idempotente; não mexa no que já funciona.
Entregue: o que foi feito, os testes (com números) e o que ficou pendente.
```
