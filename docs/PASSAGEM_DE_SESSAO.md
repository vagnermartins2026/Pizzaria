# Passagem de sessão — Pizzalia

## ▶️ RETOMADA (17/11/2026, 12h55 UTC) — comece por aqui

**Estado:** sistema no ar em https://pizzalia.lovable.app (build `mwfm8jo4`, main do `vagnermartins2026/pizzalia` = `e5d1b930`,
PR #12). Banco Supabase `tsidqofldtkkgexbmtor` com 191 migrations. Tudo o que está no ar foi conferido: veja `docs/BACKLOG.md`
(itens 1–21).

**17/11/2026 (sessão seguinte):** retomada travada no início — o pedido para anexar o `vagnermartins2026/pizzalia` à sessão (add_repo) foi recusado pelo controle de permissões automático, e sem ele não dá para clonar o sistema. Nada foi mudado em H nem em I. Para destravar: o dono autoriza o add_repo na sessão (ou inicia a sessão já com o `pizzalia` anexado).

**Em execução (parado no meio e salvo no GitHub, NÃO juntado):**
| Item | Ramo no `pizzalia` | Último commit | Onde parou |
|---|---|---|---|
| H · Pix online no link | `claude/pix-link` | `fce7bca7` | bateria do banco 1060/1060; falta a suíte de tela inteira |
| I · Módulos novos no backup | `claude/backup-modulos` | `c697fab9` | rodada final da bateria do banco (placar não lido) |
Os dois ajudantes pararam pelo limite de 5 horas da assinatura (não foi erro do código).

**Próximo passo, nesta ordem, para cada ramo (H primeiro, depois I):**
1. Clonar o `pizzalia`, criar uma pasta por ramo (`git worktree add ../pizzalia-pix claude/pix-link`) e instalar (`npm install --no-audit --no-fund`).
2. Ligar o Postgres local (`service postgresql start`; usuário/senha `postgres`) e rodar a bateria de banco
   (`MF_SQL_TEST_HOST=localhost MF_SQL_TEST_PORT=5432 MF_SQL_TEST_USER=postgres PGPASSWORD=postgres npx vitest run src/__tests__/sql`) e a de tela (`npx vitest run`).
3. Juntar a main no ramo; conflito de contagem/catálogo = somar os dois lados; renumerar sabotagem se colidir (faixas: Pix s2380–s2409, Backup s2410–s2439).
4. Ensaio no banco real: migration dentro de `BEGIN … ROLLBACK` pela API de administração.
5. PR → merge com o SHA completo (`git rev-parse HEAD` → `expectedHeadSha`); mensagem em português.
6. Aplicar: `python3 /home/user/Pizzaria/scripts/ops/aplica.py supabase/migrations` (rodar dentro do clone do `pizzalia`).
7. Funções mudadas: `python3 /home/user/Pizzaria/scripts/ops/publica.py <slugs>` (Pix: `pedido-link pedido-link-aviso`; conferir `config.toml`).
8. Esperar o Lovable sincronizar (`get_project` → `latest_commit_sha`) e publicar (`deploy_project`); conferir `version.json`.
9. Conferir no ar (Playwright no celular, sessão por link mágico) e atualizar `docs/BACKLOG.md` deste repositório.
- Pix: sem as chaves do Mercado Pago da loja, o Pix fica desligado — conferir que a tela não oferece Pix e não quebra o pedido.

**Depois de H e I (eu faço sozinho):** E (cardápio no Ctrl+K e na barra do celular) · J (página `/pedir` mais leve, hoje ~9 s em 4G lento).

**Depende do dono (backlog `docs/BACKLOG.md`, seção 🙋):** R2 (falta ampliar a chave da Cloudflare ou criar bucket e chave no painel) ·
D1 domínios · 2FA no login dele (depois rodar `scripts/master/criar-admin-geral.sql` do `pizzalia`) · Mercado Pago (religar o cron
`mp-reconcile-30min`) · emissor fiscal + certificado A1 · Resend · Turnstile · D2/D3/D8 · decisões N1–N7 (padrão em uso).

## Ferramentas e fatos que economizam tempo
- SQL no banco real: `POST https://api.supabase.com/v1/projects/tsidqofldtkkgexbmtor/database/query` com `{"query": ...}` — a chave entra sozinha pelo proxy (`Authorization: Bearer x`). Nunca imprimir segredo.
- Loja demo "Forno da Vila (DEMO)": `1e45234c-bd80-52ab-b4e0-983c9d2eee6b`; link público `/pedir/forno-da-vila-demo`.
- Teste de tela no ar: link mágico (`generate_link` admin → `/auth/v1/verify` com `email_otp`) e gravar a sessão em `localStorage["sb-tsidqofldtkkgexbmtor-auth-token"]`; bloquear fontes do Google no Playwright (senão o print trava).
- Prova vale só com "falha no código antigo, passa no novo" (sabotagem). Merge só com SHA completo (já errei duas vezes com SHA errado → 409).
- Regra de ouro: erro achado aqui que possa existir na MayFlower → conferir no `mayflowermoda-adca489c` e avisar a sessão ativa dela (`send_message`).
- Tudo em português; subagentes Opus, nunca Fable; 1 ou 2 ajudantes por vez.
- Carga da demo: `db/seed/montar_carga_base.py` + prova `db/seed/testar_carga_base.sh` (ver `db/seed/LEIAME.md`).
