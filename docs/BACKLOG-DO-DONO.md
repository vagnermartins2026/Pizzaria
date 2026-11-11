# Backlog do dono: o que só você pode fazer

Atualizado em 11/11/2026. Cada item diz **o que é**, **por que importa**, a **recomendação**, as **alternativas**, o
**passo a passo** e **como conferir**. No fim de cada um há uma **resposta rápida**: é só copiar na conversa.
O que o Claude faz sozinho está em [`PLANO-DO-SITE.md`](./PLANO-DO-SITE.md).

## Resposta rápida de tudo (copie, ajuste e mande)
```
D1 registrei · D2 sem marca parecida · D3 criei @pizzalia · D4 empresa: <razão social e CNPJ>
D5 preços: 1 mantém · 2 mantém · 3A · 4 sim · D6 contatos confirmados · D7 logo A
D8 L1 sim · L2 sugestão · L3 90 dias · L4 Campinas · L5 <nome e e-mail> · D9 nenhuma · D10 pode gerar
```

---

### D1 · ⚠️ Registrar os domínios `pizzalia.com.br` e `pizzalia.app` (URGENTE)
- **O que é e por que importa:** comprar o endereço do site. Os dois estavam livres na última checagem (11/11/2026),
  mas qualquer pessoa pode registrar antes, como aconteceu com o `fornalia.com.br`. Envolve pagamento no seu login.
- **Recomendação:** registrar os dois hoje.
- **Alternativas:**

  | Opção | Prós | Contras | Impacto |
  |---|---|---|---|
  | **Os dois** (recomendada) | Site e link de pedidos protegidos | Dois pagamentos por ano | Nenhum risco |
  | Só o `.com.br` | Mais barato | O link de pedidos das pizzarias (`pizzalia.app/…`) fica sem dono | Trocar o formato do link depois |
- **Passo a passo:**
  1. Entre em **registro.br** → "Entrar" com o seu CPF/CNPJ (ou crie a conta).
  2. Na caixa de busca digite `pizzalia.com.br` → **Registrar** → titular: a empresa que vai assinar o produto (D4) → pague (boleto ou Pix).
  3. Para o `.app`: na **Cloudflare** (dash.cloudflare.com, a mesma conta da prévia) → **Domain Registration** → **Register Domains** → `pizzalia.app` → pagar com cartão.
- **Como conferir:** em registro.br → "Meus domínios" aparece `pizzalia.com.br`; na Cloudflare, `pizzalia.app` aparece em "Domain Registration".
- **Depois:** me avise "D1 registrei". Eu ligo o domínio ao site na Cloudflare e te passo o único passo do Registro.br (trocar os servidores DNS, [`PUBLICAR-SITE.md`](./PUBLICAR-SITE.md), seção 2).
- **Resposta rápida:** `D1 registrei`

### D2 · Pesquisar "Pizzalia" no INPI
- **O que é e por que importa:** ver se alguém já tem a marca registrada para software. Evita ter que trocar de nome depois
  de investir em logo e anúncio. O Claude tentou em 11/11/2026, mas o site do INPI recusa conexão de fora do Brasil.
- **Recomendação:** pesquisar agora (10 minutos) e, se estiver livre, pedir o registro (pode ser com um despachante de marcas).
- **Passo a passo:**
  1. Entre em **busca.inpi.gov.br/pePI** → "Continuar" (sem login).
  2. **Marca** → **Pesquisa básica** → digite `pizzalia` → marque **Radical** → **Pesquisar**.
  3. Repita marcando **Exata**.
  4. Na lista, olhe a coluna **Classe**: preocupe-se com **9** (programa de computador) e **42** (software como serviço). Classe 43 (restaurante) não impede, mas anote.
- **Como conferir:** se não aparecer nada nas classes 9 e 42, está livre para pedir.
- **Resposta rápida:** `D2 sem marca parecida` ou `D2 achei: <o que apareceu>`

### D3 · Criar o @ no Instagram
- **O que é e por que importa:** guardar o nome nas redes antes de alguém pegar. É por lá que o dono de pizzaria vai conhecer a marca.
- **Recomendação:** `@pizzalia`; se estiver ocupado, `@pizzalia.app` ou `@sistemapizzalia`.
- **Passo a passo:** Instagram → seu perfil → trocar de conta → **Adicionar conta** → **Criar nova conta** → nome de usuário `pizzalia`.
- **Como conferir:** abrir instagram.com/pizzalia.
- **Resposta rápida:** `D3 criei @<nome>`

### D4 · Qual empresa assina o produto (razão social e CNPJ)
- **O que é e por que importa:** a lei (Decreto 7.962/2013) exige, em quem vende pela internet, razão social e CNPJ no site,
  nos Termos e na Privacidade. Hoje esses campos estão em branco.
- **Recomendação:** usar a mesma empresa da Minha Maleta, se for a da Contera. Só você sabe qual é a certa.
- **Alternativas:** (A) a mesma da Minha Maleta · (B) outra empresa do grupo · (C) uma empresa nova só para a Pizzalia (mais custo, mais separação).
- **Depois:** eu preencho `site/src/config/marca.ts` e os documentos legais, e publico.
- **Resposta rápida:** `D4 empresa: <razão social>, CNPJ <número>`

### D5 · Preços
- **O que é e por que importa:** o site mostra os preços do plano de negócio como "previstos". A pesquisa de 11/11/2026
  ([`PESQUISA-DE-PRECOS.md`](./PESQUISA-DE-PRECOS.md)) mostrou que o Premium (R$ 549) é o mais caro do mercado para um plano que ainda não existe inteiro.
- **Recomendação:**
  1. Essencial: **manter R$ 149**.
  2. Profissional: **manter R$ 299** (R$ 249 na abertura).
  3. Premium: **(A) tirar o preço do site até ficar completo** ("em pré-venda, sob consulta").
  4. Implantação no mensal: **baixar de R$ 390 para R$ 190**; o anual continua com implantação grátis.
- **Alternativas para o Premium:** (A) sob consulta · (B) manter R$ 549 · (C) baixar para R$ 449. Prós e contras na pesquisa, seção 3.
- **Resposta rápida:** `D5 preços: 1 mantém · 2 mantém · 3A · 4 sim`

### D6 · Confirmar o WhatsApp e o e-mail comerciais
- **O que é e por que importa:** o site usa `(19) 98214-7840` e `comercial@contera.com` (os da Minha Maleta). O repositório é
  **público** e a prévia já está no ar com eles. É por esse número que chegam as inscrições da lista de espera.
- **Recomendação:** manter, se esse número atende os dois produtos.
- **Resposta rápida:** `D6 contatos confirmados` ou `D6 WhatsApp <número>, e-mail <e-mail>`

### D7 · Escolher a logo
- **O que é e por que importa:** o ícone de hoje é provisório. A logo aparece no site, no sistema e no Instagram.
- **Recomendação:** **A (fatia)**, que fica legível até em 24 px, o tamanho do ícone no celular. A B conta melhor a história, mas tem mais detalhe.
- **Alternativas:** veja [`marca/opcoes-de-logo.png`](./marca/opcoes-de-logo.png) (A fatia · B a fatia que volta · C letra P).
- **Depois:** eu troco no site e gero de novo os ícones e a imagem de compartilhamento.
- **Resposta rápida:** `D7 logo A` (ou B, ou C)

### D8 · Documentos legais do sistema: 6 decisões + revisão jurídica
- **O que é e por que importa:** os Termos de assinatura e a Política de Privacidade do sistema estão em rascunho
  ([`legal/`](./legal/LEIAME.md)). Precisam estar prontos antes de abrir o cadastro e a cobrança.
- **Recomendação:** L1 garantia de 7 dias · L2 devolver o proporcional no anual · L3 90 dias para exportar · L4 foro em Campinas/SP · L5 indicar o encarregado de dados · L6 eu confirmo a região dos servidores quando o banco for criado.
- **Passo a passo:** responder as decisões e mandar os dois arquivos de `docs/legal/` para o jurídico.
- **Resposta rápida:** `D8 L1 sim · L2 sugestão · L3 90 dias · L4 Campinas · L5 <nome e e-mail>`

### D9 · Medir visitas do site
- **O que é e por que importa:** saber quantas pessoas entram e de onde vêm. Ferramenta com cookies exige aviso de cookies e muda a Privacidade.
- **Recomendação:** **nenhuma por enquanto**. A origem de cada inscrição já chega na mensagem do WhatsApp (anúncio ou indicação). Revisitar quando houver anúncio pago.
- **Alternativas:** (A) nenhuma · (B) Google Analytics (grátis, exige aviso de cookies) · (C) uma ferramenta sem cookies, como Plausible ou Cloudflare Web Analytics.
- **Resposta rápida:** `D9 nenhuma` (ou B, ou C)

### D10 · Fotos do site
- **O que é e por que importa:** o site tem espaços para fotos (pizzaria, dono, balcão), visíveis com `?espacos` no endereço. Foto real convence mais.
- **Recomendação:** fotos reais quando houver a primeira pizzaria cliente. Até lá, o site funciona sem elas.
- **Observação:** nesta sessão não há ferramenta que gere imagem. Se quiser imagens de IA, use o Higgsfield ou o ChatGPT e me mande.
- **Resposta rápida:** `D10 sem fotos por enquanto` ou mande as fotos

### Depois (não precisa responder agora)
| # | O quê | Quando |
|---|---|---|
| D11 | Apontar o DNS no Registro.br (1 passo, com o meu guia) | Depois do D1 |
| D12 | Depoimentos dos primeiros clientes, com autorização por escrito | Depois que os primeiros clientes usarem |
| D13 | Sistema com cadastro e assinatura funcionando. O que ele precisa fazer: [`CADASTRO-DO-SISTEMA.md`](./CADASTRO-DO-SISTEMA.md) (com prompt pronto) | Outra frente (sessão do sistema) |

## Já resolvido
| O quê | Quando |
|---|---|
| Nome aprovado: **Pizzalia** | 11/11/2026 |
| Sem oferta de fundadoras: o site virou lista de espera | 11/11/2026 |
| Prévia publicada em https://pizzalia.pages.dev | 11/11/2026 |
| Fornalia trocado por Pizzalia nos documentos | 11/11/2026 |
