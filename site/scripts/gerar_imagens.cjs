/**
 * Gera as imagens do site a partir de HTML (marca provisória):
 *   public/og-image.png (1200×630, prévia de link no WhatsApp/Instagram/Google)
 *   public/icon-512.png, public/icon-192.png, public/apple-touch-icon.png (180×180)
 * Rodar de novo quando a marca mudar: `node scripts/gerar_imagens.cjs` (precisa do Playwright instalado).
 * O nome vem por argumento para não depender do build: `node scripts/gerar_imagens.cjs Pizzalia`.
 */
const { chromium } = require("playwright");
const { readFileSync } = require("node:fs");
const { join } = require("node:path");

const nome = process.argv[2] || "Pizzalia";
const pub = join(__dirname, "..", "public");
const icone = readFileSync(join(pub, "favicon.svg"), "utf8");
const fontes = `<link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600;12..96,700&family=Inter:wght@400;500&display=swap" rel="stylesheet">`;

const og = `<!doctype html><html><head><meta charset="utf-8">${fontes}<style>
  *{margin:0;box-sizing:border-box} body{width:1200px;height:630px;background:#FFF8EF;font-family:Inter,sans-serif;color:#5A4A42;display:flex;padding:72px 80px;position:relative;overflow:hidden}
  .marca{display:flex;align-items:center;gap:14px;font-family:'Bricolage Grotesque';font-weight:700;font-size:40px;color:#2A1D17;letter-spacing:-.03em}
  .marca svg{width:52px;height:52px}
  h1{font-family:'Bricolage Grotesque';font-weight:700;font-size:70px;line-height:1.02;letter-spacing:-.04em;color:#2A1D17;margin-top:54px;max-width:760px}
  h1 em{font-style:normal;color:#C2361C}
  p{font-size:27px;margin-top:28px;max-width:700px;line-height:1.35}
  .cartao{position:absolute;right:70px;bottom:80px;width:330px;background:#fff;border-radius:28px;padding:28px;box-shadow:0 30px 60px -30px rgba(42,29,23,.45),0 0 0 1px #F0E2CF}
  .cartao b{display:block;font-family:'Bricolage Grotesque';font-size:64px;color:#C2361C;letter-spacing:-.03em;line-height:1}
  .cartao span{display:block;margin-top:8px;font-size:21px}
  .cartao i{display:inline-block;margin-top:18px;background:#1FA855;color:#fff;font-style:normal;font-size:17px;font-weight:500;padding:9px 16px;border-radius:99px}
  .fio{position:absolute;left:0;bottom:0;height:14px;width:100%;background:#C2361C}
</style></head><body><div>
  <div class="marca">${icone}${nome}</div>
  <h1>Quantos clientes <em>pararam de pedir</em> na sua pizzaria?</h1>
  <p>Pedidos, caixa e um CRM que mostra quem sumiu, com a mensagem pronta no WhatsApp.</p>
</div>
<div class="cartao"><b>218</b><span>clientes para chamar hoje, na pizzaria de demonstração</span><i>Abrir WhatsApp</i></div>
<div class="fio"></div></body></html>`;

const quadrado = (lado, margem) => `<!doctype html><html><head><meta charset="utf-8"><style>
  *{margin:0} body{width:${lado}px;height:${lado}px;background:#FFF8EF;display:flex;align-items:center;justify-content:center}
  svg{width:${lado - 2 * margem}px;height:${lado - 2 * margem}px}
</style></head><body>${icone}</body></html>`;

(async () => {
  const b = await chromium.launch();
  const tirar = async (html, w, h, arquivo) => {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
    await p.setContent(html, { waitUntil: "networkidle" });
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: join(pub, arquivo) });
    await p.close();
  };
  await tirar(og, 1200, 630, "og-image.png");
  await tirar(quadrado(512, 56), 512, 512, "icon-512.png");
  await tirar(quadrado(192, 20), 192, 192, "icon-192.png");
  await tirar(quadrado(180, 18), 180, 180, "apple-touch-icon.png");
  await b.close();
  console.log("imagens geradas em public/");
})();
