# Política de Privacidade da Pizzalia (RASCUNHO v0.1, para revisão jurídica)

> Rascunho de 11/11/2026, baseado na LGPD (Lei 13.709/2018) e no PRD (seções 11.7 e 12.4). Não publicar antes da
> revisão jurídica e do preenchimento dos `[COLCHETES]`. Itens **⚖️ DECIDIR** estão em `docs/legal/LEIAME.md`.

**Quem somos.** `[RAZÃO SOCIAL]`, CNPJ `[CNPJ]` ("Pizzalia"). Encarregado de dados (DPO): **⚖️ DECIDIR (L5)**
`[NOME]`, `[E-MAIL]`.

## 1. Dois tipos de dados, dois papéis
| De quem são os dados | Exemplos | Papel da Pizzalia |
|---|---|---|
| **Do Assinante** (dono e equipe da pizzaria) | Nome, e-mail, WhatsApp, CNPJ, dados de pagamento da assinatura, registros de acesso | **Controladora**: decide como tratar |
| **Dos clientes da pizzaria** (quem pede pizza) | Nome, celular, endereço, pedidos, aniversário, autorização para mensagens | **Operadora**: trata em nome da pizzaria, que é a controladora |

## 2. Dados do Assinante: o que, para quê e com que base
| Dado | Para quê | Base legal (LGPD, art. 7º) |
|---|---|---|
| Nome, e-mail, WhatsApp, senha (guardada cifrada), dados da empresa | Criar e manter a conta, dar suporte | Execução de contrato |
| Dados de cobrança (processados pelo Mercado Pago) | Cobrar a assinatura | Execução de contrato |
| Notas fiscais da assinatura | Cumprir a lei fiscal | Obrigação legal |
| Registros de acesso (data, hora, IP) | Segurança e Marco Civil da Internet (guarda de 6 meses) | Obrigação legal |
| Origem do cadastro (anúncio, indicação) | Medir de onde vêm os assinantes e pagar a comissão de quem indicou | Legítimo interesse |
| Uso do sistema (telas e funções usadas) | Melhorar o produto | Legítimo interesse |

## 3. Dados dos clientes da pizzaria
3.1. A Pizzalia trata esses dados **só** para fazer o sistema funcionar para a pizzaria: receber pedidos, montar o
histórico, calcular as sugestões do CRM e emitir nota fiscal.
3.2. **Mensagens promocionais só com consentimento.** O cliente marca, no pedido, se aceita receber novidades (caixa
desmarcada). O sistema registra quando, onde e como; o cliente pode sair a qualquer momento e o sistema bloqueia novos
contatos.
3.3. A Pizzalia não vende, não aluga e não usa esses dados para outros fins, nem cruza clientes de uma pizzaria com os
de outra.
3.4. Pedidos do titular (acesso, correção, exclusão) que chegarem à Pizzalia são repassados à pizzaria, que é quem decide.

## 4. Com quem os dados são compartilhados
| Quem | Para quê |
|---|---|
| Hospedagem e banco de dados `[FORNECEDOR]` | Guardar os dados com segurança |
| Mercado Pago | Cobrar a assinatura e processar o Pix do link de pedidos |
| Emissor de nota fiscal `[PARCEIRO]` e SEFAZ | Emitir NFC-e e NF-e (módulo fiscal) |
| Envio de e-mail `[FORNECEDOR]` | Avisos da conta e da cobrança |
| Marketplaces (iFood, 99Food), só se a pizzaria ligar o módulo | Receber os pedidos de lá |
| Autoridades | Quando a lei ou um juiz mandar |

**⚖️ DECIDIR (L6):** se algum fornecedor guardar dados fora do Brasil, a transferência segue o art. 33 da LGPD
(cláusulas-padrão da ANPD). `[Região dos servidores: a confirmar]`.

## 5. Segurança
Cada pizzaria só enxerga os próprios dados (isolamento no banco), o dono usa verificação em duas etapas, o certificado
digital A1 fica guardado cifrado, as conexões são criptografadas (HTTPS), há cópia de segurança diária e as ações
sensíveis ficam registradas em auditoria. O acesso do suporte a uma pizzaria exige motivo, verificação em duas etapas e
fica registrado.

## 6. Por quanto tempo
| Dado | Prazo |
|---|---|
| Conta ativa | Enquanto durar a assinatura |
| Depois do cancelamento | **⚖️ DECIDIR (L3):** `[90]` dias para exportar; depois, exclusão |
| Notas fiscais e registros contábeis | O prazo da lei (em geral, 5 anos) |
| Registros de acesso | 6 meses (Marco Civil da Internet, art. 15) |

## 7. Direitos do titular (LGPD, art. 18)
Confirmar se tratamos seus dados, acessar, corrigir, pedir anonimização ou exclusão, portabilidade, saber com quem
compartilhamos e revogar o consentimento. Pedidos: `[E-MAIL DO ENCARREGADO]`. Resposta em até 15 dias.

## 8. Cookies
O sistema usa apenas cookies necessários para o login funcionar. O site não usa cookies de publicidade; se passar a
usar, haverá aviso e escolha antes.

## 9. Mudanças
Mudanças relevantes nesta política são avisadas no sistema e por e-mail antes de valer.

Versão `[v1.0]` · vigente desde `[DATA]`.
