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
[2. Pronto para publicar]  ✅ feito, falta só o que é do dono (itens 1 a 7 e 9 do backlog)
[3. Prévia no ar]  ✅ https://pizzalia.pages.dev
[4. No domínio próprio]  ⏳ espera nome, domínio e DNS (backlog 1, 3, 13)
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
| 10 | Aprovar nome | Dono | ✅ Pizzalia, 11/11/2026 |
| 10b | INPI, registrar domínios, @ do Instagram | Dono | ⏳ backlog 2 a 4 |
| 11 | Contato, empresa e preços | Dono | ⏳ backlog 5 a 7 |
| 12 | Publicar a prévia na Cloudflare | Claude | ✅ https://pizzalia.pages.dev, ligada ao GitHub |
| 13 | Apontar DNS de `www` e `app` | Dono, com passo a passo do Claude | ⏳ backlog 13 |
| 14 | Logo, fotos, revisão jurídica, medição de visitas | Dono | ⏳ backlog 10 a 12, 14 |
| 15 | Trocar "Fornalia" por "Pizzalia" nos documentos | Claude | ✅ |
| 16 | Virar a chave para "aberto" quando o cadastro do sistema existir | Claude | ⏳ backlog 16 |
| 17 | Trocar a tela ilustrativa por prints ou vídeo do painel real | Claude | ⏳ quando o painel existir |
| 18 | Depoimentos reais dos primeiros clientes | Dono | ⏳ depois da abertura |

## Regras que o site segue (e os testes protegem)
- Só promete o que está no PRD; o que não está na 1ª versão aparece como "próximas etapas".
- Nenhum número, cliente ou depoimento inventado. Os números são da pizzaria fictícia de demonstração, ditos assim.
- Preços iguais aos do plano de negócio, marcados como "previstos".
- Nenhuma taxa de empresa citada como fato (a comissão do marketplace é a do contrato do dono).
- O formulário não guarda dados; mensagens de marketing só com consentimento (LGPD).
