# Publicar o site (passo a passo)

Para quando os itens D1 a D6 do [backlog do dono](./BACKLOG-DO-DONO.md) estiverem resolvidos.
Com a autorização (item 9), o Claude faz a parte da Cloudflare; a parte do Registro.br é do dono,
porque exige o login dele.

## 1. Prévia na Cloudflare Pages (sem domínio): ✅ feita em 11/11/2026
**No ar em https://pizzalia.pages.dev.** Projeto `pizzalia` na sua conta Cloudflare, ligado ao repositório
`Pizzaria`. Configuração atual:

| Campo | Valor |
|---|---|
| Branch de produção | `claude/sweet-faraday-9fvbeh` (trocar para `main` quando o site for para a `main`) |
| Diretório raiz / build / saída | `site` / `npm run build` / `dist` |
| Variáveis | `NODE_VERSION=20`, `VITE_SITE=https://pizzalia.pages.dev`, `VITE_PREVIA=1` (prévia fora do Google) |

Quando o domínio próprio estiver apontado (seção 2), **apagar** `VITE_SITE` e `VITE_PREVIA` em
Pages → pizzalia → Settings → Variables: o site passa a usar `https://www.pizzalia.com.br` e a ser indexado.

Como foi criado (para refazer do zero, se precisar):
1. Cloudflare → **Workers & Pages** → **Create** → **Pages** → **Connect to Git** → repositório `Pizzaria`.
2. Configuração do build:
   | Campo | Valor |
   |---|---|
   | Production branch | `main` (ou a branch do site enquanto for rascunho) |
   | Root directory | `site` |
   | Build command | `npm run build` |
   | Build output directory | `dist` |
   | Variável de ambiente | `NODE_VERSION` = `20` |
3. Salvar. Em 1 a 2 minutos o site abre em `https://<nome-do-projeto>.pages.dev`.
4. Cada push na branch publica de novo sozinho. Se um teste falhar, o build para e a versão anterior continua no ar.

## 2. Domínio próprio (depois de registrar `pizzalia.com.br`)
1. Cloudflare → **Add a domain** → `pizzalia.com.br` → plano Free. A Cloudflare mostra **2 servidores DNS**
   (algo como `xxx.ns.cloudflare.com`).
2. **Registro.br** → entrar → domínio `pizzalia.com.br` → **DNS** → **Alterar servidores DNS** → colar os 2
   servidores da Cloudflare → salvar. A troca leva de minutos a algumas horas.
3. Cloudflare → projeto do site em **Pages** → **Custom domains** → adicionar `www.pizzalia.com.br` e
   `pizzalia.com.br`. A Cloudflare cria os registros e o certificado HTTPS.
4. Fazer `pizzalia.com.br` (sem www) redirecionar para `https://www.pizzalia.com.br` (**Rules** → **Redirect Rules**),
   porque o endereço oficial do site é com `www` (`site/src/config/marca.ts`).
5. Reservar `app.pizzalia.com.br` para o sistema: o registro é criado quando o sistema for publicado.

## 3. Conferir depois de publicar
- [ ] `https://www.pizzalia.com.br` abre com cadeado (HTTPS).
- [ ] `https://www.pizzalia.com.br/lista-de-espera` abre direto (sem passar pela página inicial).
- [ ] Um endereço inexistente mostra a página "saiu do forno antes da hora".
- [ ] Colar o link no WhatsApp mostra a imagem de prévia (`og-image.png`).
- [ ] Google Search Console: adicionar o domínio e enviar `https://www.pizzalia.com.br/sitemap.xml`.
- [ ] O botão "Enviar pelo WhatsApp" da lista de espera abre a conversa com o número comercial certo.
