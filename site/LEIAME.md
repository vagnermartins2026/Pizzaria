# Site oficial da plataforma (rascunho v0.1)

Site de venda do sistema para pizzarias: é por aqui que a pizzaria conhece, se inscreve e, depois
da abertura, cria a conta e assina. Nome e domínio recomendados em
[`../docs/MARCA-E-DOMINIO.md`](../docs/MARCA-E-DOMINIO.md) (**Pizzalia**, `pizzalia.com.br`).

A estrutura segue o site da Minha Maleta (mesma lógica de venda e mesmas regras de honestidade),
com o conteúdo do [PRD](../docs/PRD.md) e do [plano de negócio](../docs/PLANO-DE-NEGOCIO.md).

## Rodar
```bash
cd site
npm install
npm run dev       # http://localhost:5173
npm run build     # gera dist/ (site estático)
```
Endereço com `?espacos` (ex.: `http://localhost:5173/?espacos`) mostra onde entram fotos,
vídeo e depoimentos que ainda vão chegar.

## Onde mudar cada coisa
| O quê | Arquivo |
|---|---|
| Nome, domínio, endereço do sistema, contato, fase de lançamento | `src/config/marca.ts` |
| Planos, preços e módulos | `src/config/planos.ts` (mesmos valores de `docs/PLANO-DE-NEGOCIO.md`) |
| Perguntas frequentes | `src/config/faq.ts` |
| Cores | `tailwind.config.js` |
| Título, descrição e imagem de compartilhamento | `index.html` |

## Páginas
| Rota | O que é |
|---|---|
| `/` | Página inicial: topo, calculadora, antes × depois, funções, como funciona, comparativo, confiança, fundadoras, planos, perguntas |
| `/fundadores` | Inscrição das 10 pizzarias fundadoras. Sem banco: monta a mensagem e abre o WhatsApp comercial |
| `/termos`, `/privacidade` | **Rascunhos**: falta revisão jurídica, razão social e CNPJ |

## Como o site vira uma coisa só com o sistema
1. **Hoje (fase `pre-lancamento`):** os botões levam a `/fundadores`. Nada é gravado.
2. **Quando o cadastro do sistema existir** (PRD, M01 e fase F9 da R1): mude
   `LANCAMENTO.fase` para `"aberto"` em `src/config/marca.ts`. Todos os botões passam a ir para
   `https://app.pizzalia.com.br/cadastro`, onde a pizzaria cria a conta, entra nos 14 dias de
   teste com a pizzaria demo e depois assina.
3. **Unificar no mesmo projeto (opcional):** o site usa o mesmo stack da Minha Maleta (React,
   Vite e Tailwind). Se o sistema for construído assim, as páginas de `src/pages` e
   `src/components` podem ir para dentro do app, na rota `/`, como a Minha Maleta faz com a
   `Landing.tsx`. Até lá, site e sistema ficam em subdomínios separados (`www` e `app`).

## Publicar
É um site estático (`dist/`). Em Cloudflare Pages ou Netlify: comando `npm run build`, pasta
`dist`, raiz `site`. O arquivo `public/_redirects` faz toda rota abrir o `index.html`.

## Pendências antes de publicar
- [ ] Aprovar o nome e registrar o domínio (`docs/MARCA-E-DOMINIO.md`).
- [ ] Confirmar o WhatsApp e o e-mail comerciais (copiados da Minha Maleta).
- [ ] Definir a empresa que assina (razão social e CNPJ) e revisar Termos e Privacidade.
- [ ] Validar os preços com a pesquisa de concorrentes (plano de negócio, seção 4).
- [ ] Logo de verdade (hoje é um ícone provisório em `public/favicon.svg`) e imagem de
  compartilhamento (`og:image`).
- [ ] Trocar a tela ilustrativa do topo por prints ou vídeo do painel real quando ele existir.
- [ ] Depoimentos reais e autorizados das fundadoras (a seção só aparece quando houver).
