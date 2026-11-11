# Backlog do dono: o que só você pode fazer

Atualizado em 11/11/2026 (depois de "siga todas as opções recomendadas"). Cada item diz **o que é**, **por que importa**, a **recomendação**, as **alternativas**, o
**passo a passo** e **como conferir**. No fim de cada um há uma **resposta rápida**: é só copiar na conversa.
O que o Claude faz sozinho está em [`PLANO-DO-SITE.md`](./PLANO-DO-SITE.md).

## Resposta rápida do que falta (copie, ajuste e mande)
```
D1 registrei · D2 sem marca parecida · D3 criei @pizzalia · D8 L5 encarregado: <nome e e-mail> · jurídico revisou
```

---

### D1 · ⚠️ Registrar os domínios `pizzalia.com.br` e `pizzalia.app` (URGENTE)
- **O que é e por que importa:** comprar o endereço do site. Os dois estavam livres na última checagem (11/11/2026),
  mas qualquer pessoa pode registrar antes, como aconteceu com o `fornalia.com.br`. Envolve pagamento no seu login.
- **Recomendação:** registrar os dois hoje.
- **Alternativas:**

  | Opção | Prós | Contras | Impacto |
  |---|---|---|---|
  | **Os dois** (recomendada) | Site e link de pedidos protegidos | Dois pagamentos por ano | Nenhum risco |
  | Só o `.com.br` | Mais barato | O link de pedidos das pizzarias (`pizzalia.app/…`) fica sem dono | Trocar o formato do link depois |
- **Passo a passo:**
  1. Entre em **registro.br** → "Entrar" com o seu CPF/CNPJ (ou crie a conta).
  2. Na caixa de busca digite `pizzalia.com.br` → **Registrar** → titular: a empresa que vai assinar o produto (D4) → pague (boleto ou Pix).
  3. Para o `.app`: na **Cloudflare** (dash.cloudflare.com, a mesma conta da prévia) → **Domain Registration** → **Register Domains** → `pizzalia.app` → pagar com cartão.
- **Como conferir:** em registro.br → "Meus domínios" aparece `pizzalia.com.br`; na Cloudflare, `pizzalia.app` aparece em "Domain Registration".
- **Depois:** me avise "D1 registrei". Eu ligo o domínio ao site na Cloudflare e te passo o único passo do Registro.br (trocar os servidores DNS, [`PUBLICAR-SITE.md`](./PUBLICAR-SITE.md), seção 2).
- **Resposta rápida:** `D1 registrei`

### D2 · Pesquisar "Pizzalia" no INPI
- **O que é e por que importa:** ver se alguém já tem a marca registrada para software. Evita ter que trocar de nome depois
  de investir em logo e anúncio. O Claude tentou em 11/11/2026, mas o site do INPI recusa conexão de fora do Brasil.
- **Recomendação:** pesquisar agora (10 minutos) e, se estiver livre, pedir o registro (pode ser com um despachante de marcas).
- **Passo a passo:**
  1. Entre em **busca.inpi.gov.br/pePI** → "Continuar" (sem login).
  2. **Marca** → **Pesquisa básica** → digite `pizzalia` → marque **Radical** → **Pesquisar**.
  3. Repita marcando **Exata**.
  4. Na lista, olhe a coluna **Classe**: preocupe-se com **9** (programa de computador) e **42** (software como serviço). Classe 43 (restaurante) não impede, mas anote.
- **Como conferir:** se não aparecer nada nas classes 9 e 42, está livre para pedir.
- **Resposta rápida:** `D2 sem marca parecida` ou `D2 achei: <o que apareceu>`

### D3 · Criar o @ no Instagram
- **O que é e por que importa:** guardar o nome nas redes antes de alguém pegar. É por lá que o dono de pizzaria vai conhecer a marca.
- **Recomendação:** `@pizzalia`; se estiver ocupado, `@pizzalia.app` ou `@sistemapizzalia`.
- **Passo a passo:** Instagram → seu perfil → trocar de conta → **Adicionar conta** → **Criar nova conta** → nome de usuário `pizzalia`.
- **Como conferir:** abrir instagram.com/pizzalia.
- **Resposta rápida:** `D3 criei @<nome>`

### D8 · Documentos legais do sistema: falta o encarregado de dados e a revisão jurídica
- **O que é e por que importa:** os Termos de assinatura e a Política de Privacidade do sistema ([`legal/`](./legal/LEIAME.md))
  precisam estar prontos antes de abrir o cadastro e a cobrança. As decisões L1 a L4 já foram aplicadas (garantia de 7 dias,
  proporcional no anual, 90 dias para exportar, foro em Campinas) e a empresa já está preenchida.
- **Falta:** (L5) dizer quem é o **encarregado de dados** (a pessoa que responde a pedidos de titulares; a LGPD exige que
  o nome e o contato estejam publicados) e mandar os dois arquivos para o **jurídico** revisar.
- **Recomendação:** você ou alguém da Contera como encarregado, com um e-mail próprio (ex.: `privacidade@contera.com`).
- **Alternativas:** (A) uma pessoa da equipe · (B) um serviço terceirizado de DPO (mais caro, mais especializado).
- **Passo a passo:** responder com o nome e o e-mail; enviar `docs/legal/TERMOS-DE-USO-DO-SISTEMA.md` e
  `docs/legal/POLITICA-DE-PRIVACIDADE-DO-SISTEMA.md` ao jurídico.
- **Como conferir:** o jurídico devolve os textos aprovados; eu publico junto com o cadastro do sistema.
- **Resposta rápida:** `D8 L5 encarregado: <nome e e-mail>` e, depois, `jurídico revisou`

### Depois (não precisa responder agora)
| # | O quê | Quando |
|---|---|---|
| D11 | Apontar o DNS no Registro.br (1 passo, com o meu guia) | Depois do D1 |
| D12 | Depoimentos dos primeiros clientes, com autorização por escrito | Depois que os primeiros clientes usarem |
| D13 | Sistema com cadastro e assinatura funcionando. O que ele precisa fazer: [`CADASTRO-DO-SISTEMA.md`](./CADASTRO-DO-SISTEMA.md) (com prompt pronto) | Outra frente (sessão do sistema) |

## Já resolvido
| O quê | Quando |
|---|---|
| D4 Empresa: **VHM LABS LTDA**, CNPJ 64.393.377/0001-30 (a mesma da Minha Maleta), no rodapé, no site e nos documentos legais | 11/11/2026 |
| D5 Preços: Essencial R$ 149 e Profissional R$ 299 mantidos; **Premium "sob consulta"** no site; implantação no mensal de R$ 390 para **R$ 190** | 11/11/2026 |
| D6 WhatsApp (19) 98214-7840 e comercial@contera.com confirmados | 11/11/2026 |
| D7 Logo: **opção A (fatia)**, aplicada no site, nos ícones e na imagem de compartilhamento | 11/11/2026 |
| D8 L1 a L4: garantia de 7 dias, proporcional no anual, 90 dias para exportar, foro em Campinas/SP | 11/11/2026 |
| D9 Medição de visitas: nenhuma por enquanto | 11/11/2026 |
| D10 Fotos: sem fotos por enquanto (até a primeira pizzaria cliente) | 11/11/2026 |
| Nome aprovado: **Pizzalia** | 11/11/2026 |
| Sem oferta de fundadoras: o site virou lista de espera | 11/11/2026 |
| Prévia publicada em https://pizzalia.pages.dev | 11/11/2026 |
| Fornalia trocado por Pizzalia nos documentos | 11/11/2026 |
