# Plano do site oficial: do rascunho ao ar

| Campo | Valor |
|---|---|
| Atualizado em | 2026-11-11 |
| Objetivo | Site oficial da plataforma, onde a pizzaria conhece, se inscreve e (na abertura) assina; meta de 100+ assinantes |
| Onde está | [`site/`](../site/LEIAME.md) |
| O que depende do dono | [`BACKLOG-DO-DONO.md`](./BACKLOG-DO-DONO.md) |

## Onde estamos
```
[1. Rascunho]  ✅ feito
[2. Pronto para publicar]  ✅ feito, falta só o domínio (backlog D1)
[3. Prévia no ar]  ✅ https://pizzalia.pages.dev
[4. No domínio próprio]  ⏳ espera nome, domínio e DNS (backlog D1 e D11)
[5. Pré-lançamento: lista de espera recebendo pizzarias]  ⏳ depende da etapa 4
[6. Abertura: botões levam ao cadastro do sistema]  ⏳ depende do sistema (M01/F9 do PRD)
```

## Etapas
| # | Etapa | Quem | Situação |
|---|---|---|---|
| 1 | Nome e domínios checados; recomendação Pizzalia | Claude | ✅ [`MARCA-E-DOMINIO.md`](./MARCA-E-DOMINIO.md) |
| 2 | Página inicial, lista de espera, Termos e Privacidade (rascunho) | Claude | ✅ |
| 2b | Oferta de fundadoras retirada do site (decisão do dono, 11/11/2026); teste impede que volte por engano | Claude | ✅ |
| 3 | Botões levam plano e origem (UTM, indicação) ao cadastro: contrato documentado | Claude | ✅ |
| 4 | 3 guias de conteúdo (SEO) com contas testadas | Claude | ✅ |
| 5 | Páginas pré-renderizadas (Google lê sem JavaScript), sitemap, 404 | Claude | ✅ |
| 6 | Imagem de compartilhamento, ícones, manifest, llms.txt | Claude | ✅ |
| 7 | 18 testes automáticos dentro do build | Claude | ✅ |
| 8 | Acessibilidade (axe, WCAG AA) sem violações em 8 páginas × celular e computador | Claude | ✅ |
| 9 | Build automático no GitHub (Actions), aprovado na 1ª execução | Claude | ✅ |
| 9b | Passo a passo de publicação e DNS | Claude | ✅ [`PUBLICAR-SITE.md`](./PUBLICAR-SITE.md) |
| 9c | Pesquisa de preços de 5 concorrentes, com recomendação | Claude | ✅ [`PESQUISA-DE-PRECOS.md`](./PESQUISA-DE-PRECOS.md) |
| 9d | 3 opções de logo para escolher | Claude | ✅ [`marca/`](./marca/LEIAME.md) |
| 9e | Especificação do cadastro do sistema, com prompt pronto | Claude | ✅ [`CADASTRO-DO-SISTEMA.md`](./CADASTRO-DO-SISTEMA.md) |
| 9f | Rascunho dos Termos e da Privacidade do sistema | Claude | ✅ [`legal/`](./legal/LEIAME.md) |
| 10 | Aprovar nome | Dono | ✅ Pizzalia, 11/11/2026 |
| 10b | INPI, registrar domínios, @ do Instagram | Dono | ⏳ backlog D1 a D3 |
| 11 | Empresa, preços e contatos | Dono → Claude | ✅ decididos e aplicados (11/11/2026) |
| 12 | Publicar a prévia na Cloudflare | Claude | ✅ https://pizzalia.pages.dev, ligada ao GitHub |
| 13 | Apontar DNS de `www` e `app` | Dono, com passo a passo do Claude | ⏳ backlog D11 |
| 14 | Logo, medição de visitas, fotos | Dono → Claude | ✅ logo A aplicada; sem medição e sem fotos por enquanto |
| 14b | Documentos legais: encarregado de dados e revisão jurídica | Dono | ⏳ backlog D8 (L1 a L4 aplicados) |
| 15 | Trocar "Fornalia" por "Pizzalia" nos documentos | Claude | ✅ |
| 16 | Virar a chave para "aberto" quando o cadastro do sistema existir | Claude | ⏳ backlog D13 (especificação pronta: [`CADASTRO-DO-SISTEMA.md`](./CADASTRO-DO-SISTEMA.md)) |
| 17 | Trocar a tela ilustrativa por prints ou vídeo do painel real | Claude | ⏳ quando o painel existir |
| 18 | Depoimentos reais dos primeiros clientes | Dono | ⏳ depois da abertura |

## Regras que o site segue (e os testes protegem)
- Só promete o que está no PRD; o que não está na 1ª versão aparece como "próximas etapas".
- Nenhum número, cliente ou depoimento inventado. Os números são da pizzaria fictícia de demonstração, ditos assim.
- Preços iguais aos do plano de negócio, marcados como "previstos".
- Nenhuma taxa de empresa citada como fato (a comissão do marketplace é a do contrato do dono).
- O formulário não guarda dados; mensagens de marketing só com consentimento (LGPD).
