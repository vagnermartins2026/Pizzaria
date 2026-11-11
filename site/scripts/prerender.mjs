/**
 * Pré-renderização (SEO): depois do `vite build`, grava um HTML pronto para cada página de
 * src/config/paginas.ts, com título, descrição, canonical e o conteúdo da página. O Google e as
 * prévias de link (WhatsApp, Instagram) leem tudo sem rodar JavaScript.
 *
 * Também gera dist/sitemap.xml a partir da mesma lista (o public/sitemap.xml é só o de `npm run dev`).
 */
import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const raiz = join(dirname(fileURLToPath(import.meta.url)), "..");
const dist = join(raiz, "dist");
const ssr = join(raiz, "dist-ssr");
const { desenhar, PAGINAS, metaDe, urlAbsoluta } = await import(pathToFileURL(join(ssr, "servidor.js")).href);

const modelo = readFileSync(join(dist, "index.html"), "utf8");
// Prévia (pages.dev): nenhuma página é indexada; o site oficial é o do domínio próprio.
const previa = process.env.VITE_PREVIA === "1";
const esc = (s) => s.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");

function paginaHtml(caminho) {
  const m = metaDe(caminho);
  const url = urlAbsoluta(caminho);
  let html = modelo
    .replace(/<title>.*?<\/title>/s, `<title>${esc(m.titulo)}</title>`)
    .replace(/(<meta name="description" content=")[^"]*"/, `$1${esc(m.descricao)}"`)
    .replace(/(<meta property="og:title" content=")[^"]*"/, `$1${esc(m.titulo)}"`)
    .replace(/(<meta property="og:description" content=")[^"]*"/, `$1${esc(m.descricao)}"`)
    .replace(/(<meta property="og:url" content=")[^"]*"/, `$1${url}"`)
    .replace(/(<meta property="og:image" content=")[^"]*"/, `$1${urlAbsoluta("/og-image.png")}"`)
    .replace("</head>", `    <link rel="canonical" href="${url}" />\n    <meta name="robots" content="${previa || m.indexar === false ? "noindex" : "index, follow"}" />\n  </head>`)
    .replace('<div id="root"></div>', `<div id="root">${desenhar(caminho)}</div>`);
  return html;
}

for (const { caminho } of PAGINAS) {
  const arquivo = caminho === "/" ? join(dist, "index.html") : join(dist, caminho, "index.html");
  mkdirSync(dirname(arquivo), { recursive: true });
  writeFileSync(arquivo, paginaHtml(caminho));
}
writeFileSync(join(dist, "404.html"), paginaHtml("/404"));

const indexaveis = PAGINAS.filter((p) => p.indexar !== false);
writeFileSync(
  join(dist, "sitemap.xml"),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${indexaveis
    .map((p) => `  <url><loc>${urlAbsoluta(p.caminho)}</loc></url>`)
    .join("\n")}\n</urlset>\n`,
);
rmSync(ssr, { recursive: true, force: true });
console.log(`pré-renderizadas ${PAGINAS.length} páginas + 404.html + sitemap.xml`);
