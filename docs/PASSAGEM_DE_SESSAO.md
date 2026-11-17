# Passagem de sessão — Pizzalia

## ▶️ RETOMADA (17/11/2026, 21h UTC) — comece por aqui

**Estado:** sistema no ar em https://pizzalia.lovable.app (build `mwl5hb6w`, main do `vagnermartins2026/pizzalia` = `9f25970c`, PR #16).
Banco `tsidqofldtkkgexbmtor` com 193 migrations. Nesta sessão entraram e foram conferidos no ar: H (Pix no link, PR #13), I (módulos no
backup, PR #14), E (atalhos, PR #15) e J 1ª parte (cardápio cedo, PR #16) — itens 22–25 do `docs/BACKLOG.md`. Nada em execução.

**O que ainda dá para fazer sem o dono:** só o J2 (opcional, grande). O resto do backlog depende do dono (seção 🙋).

**Avisos para a próxima sessão:**
- O controle de permissões automático barra ações que vêm só da mensagem de retomada: anexar repositórios (add_repo), aplicar migration no
  banco real e gerar login de teste. Peça ao dono, na conversa, "pode anexar" e "pode aplicar no banco e publicar" logo no início.
- O Postgres local vem sem senha: `su postgres -c "psql -qc \"ALTER USER postgres PASSWORD 'postgres'\""` antes da bateria.
- Merge: copie o SHA completo de `git rev-parse HEAD` (nesta sessão, um SHA digitado de memória deu 409 de novo).
- Sabotagens: rode só as suítes do módulo (`MF_SQL_TEST_SABOTAGE=... npx vitest run <arquivo>`); a suíte inteira por sabotagem leva horas.

## Ferramentas e fatos que economizam tempo
- SQL no banco real: `POST https://api.supabase.com/v1/projects/tsidqofldtkkgexbmtor/database/query` com `{"query": ...}` — a chave entra sozinha pelo proxy (`Authorization: Bearer x`). Nunca imprimir segredo.
- Loja demo "Forno da Vila (DEMO)": `1e45234c-bd80-52ab-b4e0-983c9d2eee6b`; link público `/pedir/forno-da-vila-demo`.
- Teste de tela no ar: link mágico (`generate_link` admin → `/auth/v1/verify` com `email_otp`) e gravar a sessão em `localStorage["sb-tsidqofldtkkgexbmtor-auth-token"]`; bloquear fontes do Google no Playwright (senão o print trava).
- Prova vale só com "falha no código antigo, passa no novo" (sabotagem). Merge só com SHA completo (já errei duas vezes com SHA errado → 409).
- Regra de ouro: erro achado aqui que possa existir na MayFlower → conferir no `mayflowermoda-adca489c` e avisar a sessão ativa dela (`send_message`).
- Tudo em português; subagentes Opus, nunca Fable; 1 ou 2 ajudantes por vez.
- Carga da demo: `db/seed/montar_carga_base.py` + prova `db/seed/testar_carga_base.sh` (ver `db/seed/LEIAME.md`).
