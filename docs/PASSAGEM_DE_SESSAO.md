# Passagem de sessão

## RETOMADA (11/11/2026)

**Ramo de trabalho:** `claude/sweet-faraday-9fvbeh` (todo o trabalho do site e da marca está nele; a `main` ainda não tem o site).

### No ar
- **Prévia do site:** https://pizzalia.pages.dev (projeto `pizzalia` na Cloudflare Pages, ligado ao GitHub; publica sozinha a
  cada push no ramo; fora do Google por `VITE_PREVIA=1`). Detalhes: [`PUBLICAR-SITE.md`](./PUBLICAR-SITE.md), seção 1.
- **GitHub Actions** `site.yml`: roda o build com os testes a cada mudança em `site/`.

### Pronto e não aplicado
| O quê | Onde | Falta |
|---|---|---|
| Domínio próprio | `PUBLICAR-SITE.md`, seção 2 | Dono registrar `pizzalia.com.br` e `pizzalia.app` (D1) |
| Logo definitiva | `docs/marca/` (3 opções) | Dono escolher (D7) |
| Preços revisados | `PESQUISA-DE-PRECOS.md` | Dono decidir (D5) |
| Termos e Privacidade do sistema | `docs/legal/` | Decisões L1 a L6 e revisão jurídica (D8) |
| Cadastro do sistema | `CADASTRO-DO-SISTEMA.md` (com prompt) | Sessão do sistema construir (D13) |

### Decisões do dono (com a recomendação)
Todas em [`BACKLOG-DO-DONO.md`](./BACKLOG-DO-DONO.md), no formato de decisão, com resposta rápida. A mais urgente é a
**D1: registrar os domínios**.

### Já decidido pelo dono
Nome **Pizzalia** (11/11) · **sem oferta de fundadoras**, site com lista de espera (11/11) · seguir com as ações recomendadas (11/11).

### O que o Claude faz assim que cada decisão chegar
| Resposta | Ação do Claude |
|---|---|
| D1 registrei | Adicionar o domínio na Cloudflare (Pages → Custom domains), passar o passo do DNS, apagar `VITE_SITE`/`VITE_PREVIA` depois que o DNS estiver apontado, conferir HTTPS, sitemap e prévia de link |
| D4 empresa | Preencher `EMPRESA` em `site/src/config/marca.ts` e os `[COLCHETES]` de `docs/legal/` |
| D5 preços | Mudar `site/src/config/planos.ts`, `site/public/llms.txt` e o plano de negócio no mesmo commit (o teste exige) |
| D6 contatos | Mudar `EMPRESA` em `site/src/config/marca.ts` se mudar |
| D7 logo | Trocar `site/public/favicon.svg` pela opção escolhida e rodar `node site/scripts/gerar_imagens.cjs Pizzalia` |
| D8 decisões legais | Preencher os documentos, levar ao site junto com o cadastro do sistema |
| D9 medição | Se B ou C: instalar, ajustar a Privacidade e, se houver cookies, o aviso |

### Como trabalhar no site
`cd site && npm install && npm run build` (testes, build, pré-renderização). Regras e mapa dos arquivos: [`site/LEIAME.md`](../site/LEIAME.md).
Prova do motor do CRM: `PGHOST=/var/run/postgresql PGUSER=<usuário> bash db/crm/testar_motor.sh` (precisa de PostgreSQL local;
deu 466 oportunidades idênticas ao gabarito em 11/11/2026).

### Cuidados
- Não colocar desconto, vagas ou "fundador" no site: há teste que impede (decisão do dono).
- Preço mudou? Mude nos três lugares no mesmo commit (`planos.ts`, `llms.txt`, plano de negócio), ou o build para.
- Publicar na Cloudflare por upload direto não funciona nesta sessão (o proxy troca a chave do upload); use o projeto ligado ao GitHub.
- O site do INPI recusa conexão daqui; a consulta de marca é do dono (D2).
