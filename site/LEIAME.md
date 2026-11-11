# Site oficial da plataforma (rascunho v0.2)

Site de venda do sistema para pizzarias: é por aqui que a pizzaria conhece o sistema, se inscreve e,
depois da abertura, cria a conta e assina. Nome e domínio recomendados em
[`../docs/MARCA-E-DOMINIO.md`](../docs/MARCA-E-DOMINIO.md) (**Pizzalia**, `pizzalia.com.br`).
O que depende do dono está em [`../docs/BACKLOG-DO-DONO.md`](../docs/BACKLOG-DO-DONO.md); o plano e o
andamento, em [`../docs/PLANO-DO-SITE.md`](../docs/PLANO-DO-SITE.md).

A estrutura segue o site da Minha Maleta (mesma lógica de venda e mesmas regras de honestidade),
com o conteúdo do [PRD](../docs/PRD.md) e do [plano de negócio](../docs/PLANO-DE-NEGOCIO.md).

## Rodar
```bash
cd site
npm install
npm run dev       # http://localhost:5173 (desenha no navegador, sem pré-renderização)
npm test          # 21 testes
npm run build     # testes + build + pré-renderização → dist/ (site estático pronto para publicar)
```
Endereço com `?espacos` (ex.: `http://localhost:5173/?espacos`) mostra onde entram fotos,
vídeo e depoimentos que ainda vão chegar.

## Onde mudar cada coisa
| O quê | Arquivo |
|---|---|
| Nome, domínio, endereço do sistema, contato, fase de lançamento | `src/config/marca.ts` |
| Planos, preços e módulos | `src/config/planos.ts` (o teste confere com `docs/PLANO-DE-NEGOCIO.md` e com `public/llms.txt`) |
| Perguntas frequentes | `src/config/faq.ts` |
| Guias | `src/config/guias.ts` (o teste confere as contas) |
| Título e descrição de cada página | `src/config/paginas.ts` |
| Cores | `tailwind.config.js` |
| Imagem de compartilhamento e ícones | `node scripts/gerar_imagens.cjs Pizzalia` (gera `public/og-image.png` e os ícones) |

## Páginas
| Rota | O que é |
|---|---|
| `/` | Página inicial: topo, calculadora, antes × depois, funções, como funciona, comparativo, confiança, planos, perguntas, guias |
| `/lista-de-espera` | Lista de espera, sem desconto nem vaga limitada (decisão do dono, 11/11/2026). Sem banco: monta a mensagem (com plano e origem) e abre o WhatsApp comercial |
| `/guias` e `/guias/:slug` | 3 guias com contas em reais: cliente que some, link próprio × marketplace, custo da pizza (CMV) |
| `/termos`, `/privacidade` | **Rascunhos**: falta revisão jurídica, razão social e CNPJ |

## Como funciona o build
1. `tsc` confere os tipos e `vitest` roda os testes: o build **para** se um preço divergir do plano de
   negócio, se uma conta de guia não fechar ou se houver link interno quebrado.
2. `vite build` gera o JavaScript e o CSS.
3. `vite build --ssr` + `scripts/prerender.mjs` gravam um HTML pronto para cada página
   (título, descrição, canonical, dados estruturados e o conteúdo). O Google e as prévias de link
   leem sem JavaScript; no navegador o React só "hidrata" a página. Também gera `404.html` e `sitemap.xml`.

## Contrato do cadastro (site → sistema)
Enquanto `LANCAMENTO.fase = "pre-lancamento"`, os botões levam a `/lista-de-espera?plano=…`.
Com `"aberto"`, todos os botões levam a:

```
https://app.pizzalia.com.br/cadastro?plano=<essencial|profissional|premium>&origem=site
    [&utm_source=…&utm_medium=…&utm_campaign=…&utm_content=…][&indicacao=<código>]
```
| Parâmetro | O sistema deve |
|---|---|
| `plano` | Pré-selecionar o plano. Valor desconhecido ou ausente: deixar a pizzaria escolher. **Nunca** usar a URL para preço: o preço vem do servidor |
| `origem` | Gravar na conta nova (`site`) |
| `utm_*` | Gravar na conta nova: é o que mede qual anúncio trouxe cada assinante (custo de aquisição por canal) |
| `indicacao` | Gravar e ligar ao parceiro (canal de contadores, plano de negócio seção 8) |

A origem é capturada na primeira visita da sessão (`src/config/origem.ts`) e vale para qualquer página
em que a pessoa clique depois. Depois do cadastro: teste de 14 dias com a pizzaria demo e assinatura
(PRD, M01 e fase F9 da R1).

**Unificar no mesmo projeto (opcional):** o site usa o mesmo stack da Minha Maleta (React, Vite e
Tailwind). Se o sistema for construído assim, `src/pages` e `src/components` podem ir para dentro do
app, como a Minha Maleta faz com a `Landing.tsx`. Até lá, site e sistema ficam em subdomínios separados
(`www` e `app`).

## Publicar
É um site estático. Na Cloudflare Pages: diretório raiz `site`, comando `npm run build`, saída `dist`,
Node 20. A Cloudflare serve `lista-de-espera.html` em `/lista-de-espera` (sem barra no fim, igual ao canonical) e o `404.html` para endereço
inexistente. O GitHub Actions (`.github/workflows/site.yml`) roda o mesmo build a cada mudança no site.
