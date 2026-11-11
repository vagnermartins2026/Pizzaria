# Marca e domínio da plataforma

| Campo | Valor |
|---|---|
| Data | 2026-11-11 |
| Status | **Pizzalia aprovado pelo dono em 11/11/2026.** Falta INPI e registrar os domínios |
| Onde mudar | `site/src/config/marca.ts` (fonte única do site) |

## 1. O que mudou desde o plano de negócio
O plano ([`PLANO-DE-NEGOCIO.md`](./PLANO-DE-NEGOCIO.md), seção 2) recomendava **Fornalia**. Na
checagem de 11/11/2026 o nome ficou sem o endereço principal:

| Domínio | Situação em 11/11/2026 |
|---|---|
| `fornalia.com.br` | **Registrado por terceiro**, com DNS ativo |
| `fornalia.com` | **Registrado por terceiro** desde 2022 |
| `fornalia.app` | Livre |

Para o dono de pizzaria brasileiro, o `.com.br` é o endereço que ele digita e em que confia.
Sem ele, a recomendação passa a ser outro nome.

## 2. Escolhido: **Pizzalia**, by Contera
- Mantém a ideia da Fornalia (sonoridade italiana, de festa e de abundância) e já diz "pizza"
  na primeira sílaba: ninguém precisa explicar do que se trata.
- É curto, fácil de falar no balcão e de digitar no WhatsApp.
- **Site e sistema:** `www.pizzalia.com.br` (site) e `app.pizzalia.com.br` (sistema).
- **Link de pedidos de cada pizzaria:** `pizzalia.app/nome-da-pizzaria` (domínio curto, separado
  do site, como o PRD já previa para a Fornalia).
- "by Contera" continua como selo do fabricante. A marca que o cliente final vê é a da pizzaria.

## 3. Alternativas checadas

| Nome | .com.br | .com | .app | Leitura |
|---|---|---|---|---|
| **Pizzalia** (aprovado) | **livre** | registrado | **livre** | Mais próximo da Fornalia, diz o segmento |
| Pizzou | livre | registrado | livre | Divertido, "pizzou" soa como verbo; mais cara de app de consumidor que de sistema de gestão |
| Giroforno | livre | livre | não confirmado | "Giro" de clientes e o forno que gira; esperto, mas pede explicação |
| Fornaly | livre | livre | livre | Todos os domínios livres, mas a grafia confunde ("Fornali? Fornaly?") |
| Redonda | livre | registrado | registrado | Simpático, porém genérico demais para registrar a marca no INPI |
| Fornalia (original) | **registrado** | registrado | livre | Só funcionaria com um endereço tipo `usefornalia.com.br` |

Também foram consultados e estão **registrados**: `fornada.com.br`, `fatia.com.br`,
`fornocheio.com.br`, `fornocerto.com.br`, `fornix.com.br`, `mezzo.com.br`, `fornalha.com.br`
e `pizzaflow.com.br`.

**Como foi checado:** consulta pública RDAP no Registro.br (.com.br), na Verisign (.com) e no
registro do Google (.app). "Livre" quer dizer que não havia registro naquele momento. Isso
pode mudar a qualquer hora: só vale depois de registrar.

## 4. Antes de adotar (checklist do dono)
- [ ] Pesquisar "Pizzalia" no INPI (classes 9 e 42, software e SaaS) e ver se não há marca parecida
  de sistema. Pizzarias com nome parecido (classe 43, restaurante) não impedem, mas confira.
- [ ] Registrar `pizzalia.com.br` no Registro.br e `pizzalia.app`.
- [ ] Garantir o @ no Instagram (não deu para checar automaticamente).
- [x] Trocar "Fornalia" por "Pizzalia" no PRD, no plano de negócio e no motor do CRM (11/11/2026).
- [ ] Apontar o DNS: `www` para a hospedagem do site e `app` para o sistema.

Se a escolha for outro nome, mude `site/src/config/marca.ts`, o `site/index.html` e o
`site/public/robots.txt`: o resto do site acompanha (o sitemap é gerado no build).
