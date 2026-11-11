# Função do link público de pedidos (`link-pedido`)

O "porteiro" entre o cliente final e o banco (PRD AD-02, AD-08, AD-10). O navegador nunca fala direto com as tabelas.

| Rota | O que faz |
|---|---|
| `GET /cardapio?loja=<slug>` | Cardápio público com cache de CDN (`s-maxage=300`, `stale-while-revalidate`) e ETag (304 quando nada mudou) |
| `GET /status?loja=<slug>` | Aberta / pausada / próxima abertura, com cache de 10 s |
| `POST /pedido` | Valida e limpa o pedido (o canal é sempre "link"; preço do navegador é descartado), aplica o limite de tentativas (IP 10 e celular 5 a cada 10 min; loja 300/min), confere o Turnstile se estiver ligado e cria o pedido pelo banco. Erros do banco viram mensagens claras (loja fechada com o dia e a hora em que abre, pedido mínimo com o valor que falta, preço que mudou com o novo total); detalhe técnico nunca vaza |
| `GET /acompanhar?token=<64 hex>` | Situação do pedido em frase ("Saiu para entrega"), previsão e histórico, sem nome, telefone nem endereço |

**Arquivos:** `nucleo.ts` (lógica pura) · `index.ts` (liga ao Supabase) · `nucleo_test.ts` (8 testes com banco de mentira) ·
`integracao_test.ts` (ponta a ponta contra o SQL real; roda pelo `db/testar_tudo.sh`). SQL de apoio: `db/pedidos/05_link_publico.sql`.

**Publicar (no dia do remix):** `verify_jwt = false` (o link é público; a proteção é feita aqui). Segredos por NOME:
`TURNSTILE_SECRET` (liga a verificação anti-robô), `LINK_ORIGENS` (sites permitidos), `LINK_BASE` (ex.: `https://pizzalia.app`).
`SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` já existem no Supabase.

**Prova (11/11/2026, Deno 2.9):** 9 de 9 testes, incluindo o de ponta a ponta. Sabotagem (deixar o navegador escolher o
canal do pedido) acusada pelo teste.
