# Backlog do dono: o que só você pode fazer

Tudo aqui depende de uma decisão ou de um acesso seu. O resto o Claude faz sozinho
(ver [`PLANO-DO-SITE.md`](./PLANO-DO-SITE.md)). Marque `[x]` quando fizer, ou responda na
conversa e o Claude atualiza.

Ordem = prioridade. Os itens 1 a 4 destravam a publicação do site.

| # | Ação | Por que importa | Como fazer | Tempo |
|---|---|---|---|---|
| 1 | [ ] **Aprovar o nome Pizzalia** (ou escolher outro da lista) | Tudo depende do nome: domínio, logo, documentos | Responder "aprovo Pizzalia" ou o nome escolhido. Lista em [`MARCA-E-DOMINIO.md`](./MARCA-E-DOMINIO.md) | 1 min |
| 2 | [ ] **Pesquisar o nome no INPI** | Evita ter que trocar de marca depois de lançar | busca.inpi.gov.br → Marcas → "Pizzalia", classes 9 e 42 | 10 min |
| 3 | [ ] **Registrar os domínios** `pizzalia.com.br` e `pizzalia.app` | Alguém pode registrar antes (o `fornalia.com.br` já foi) | registro.br (o `.com.br` sai cerca de R$ 40/ano); o `.app` em qualquer registrador, incluindo a Cloudflare | 15 min |
| 4 | [ ] **Criar o @ no Instagram** | Mesmo motivo do domínio; não deu para checar automaticamente | Criar `@pizzalia` ou a variação livre mais próxima | 5 min |
| 5 | [ ] **Confirmar o WhatsApp e o e-mail comerciais** | O site usa `(19) 98214-7840` e `comercial@contera.com`, copiados da Minha Maleta, e o repositório é **público** | Responder "confirmo" ou mandar os contatos certos | 1 min |
| 6 | [ ] **Dizer qual empresa assina o produto** (razão social e CNPJ) | Exigido no rodapé, nos Termos e na Privacidade (Decreto 7.962/2013) | Responder com a empresa (ex.: a mesma da Minha Maleta, VHM LABS LTDA?) | 1 min |
| 7 | [ ] **Validar os preços** (R$ 149 / 299 / 549 + módulos) | Os preços do site são os do plano de negócio, ainda sem pesquisa de concorrentes | Conferir 3 a 5 concorrentes e responder "mantém" ou os novos valores | 30 min |
| 8 | [ ] **Confirmar a oferta das fundadoras** (10 vagas, 50% por 6 meses) | É a promessa principal do site hoje | Responder "mantém" ou a nova condição | 1 min |
| 9 | [ ] **Autorizar a publicação de uma prévia** | Hoje o site só roda aqui; com a prévia você abre no celular | Responder "pode publicar a prévia": o Claude publica na sua Cloudflare (endereço `*.pages.dev`, sem domínio ainda) | 1 min |
| 10 | [ ] **Logo definitiva** | O ícone atual (fatia de pizza) é provisório | Mandar a logo, ou pedir propostas (skill de marketing, ou designer) | — |
| 11 | [ ] **Revisão jurídica** de Termos e Privacidade | Hoje são rascunhos de pré-lançamento | Mandar para o jurídico antes de abrir o cadastro e a cobrança | — |
| 12 | [ ] **Decidir se quer medir visitas** (Google Analytics, Meta Pixel ou nenhum) | Medição com cookies exige aviso de cookies e muda a Política de Privacidade | Responder qual ferramenta (ou "nenhuma por enquanto") | 1 min |
| 13 | [ ] **Apontar o DNS** depois de registrar | Faz `www.pizzalia.com.br` abrir o site | O Claude passa o passo a passo quando o item 3 estiver feito | 10 min |
| 14 | [ ] **Fotos reais** (pizzaria, dono, balcão) ou autorizar imagens geradas por IA | O site está pronto para receber; os espaços aparecem com `?espacos` no endereço | Mandar as fotos ou responder "pode gerar" | — |
| 15 | [ ] **Depoimentos** das fundadoras, com autorização por escrito | A seção de depoimentos só aparece quando houver depoimento real | Depois do beta | — |

## Depende de outra frente (não deste site)
| # | Ação | Observação |
|---|---|---|
| 16 | [ ] Sistema com cadastro e assinatura funcionando (PRD, M01, fase F9) | Quando existir, o Claude troca a fase do site para `"aberto"` e os botões passam a levar para `app.pizzalia.com.br/cadastro`. O contrato que o cadastro do sistema precisa aceitar está em [`site/LEIAME.md`](../site/LEIAME.md) |
| 17 | [ ] Trocar "Fornalia" por "Pizzalia" no PRD, no plano e no motor do CRM | Só depois do item 1 |
