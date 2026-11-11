import { useLocation } from "react-router-dom";
import { Cabecalho, CtaPrincipal, EspacoMidia, Ideia, Rodape, Sobretitulo, Titulo } from "@/components/Base";
import { BalaoWhatsApp, Celular, TelaOportunidades } from "@/components/TelaOportunidades";
import { Calculadora } from "@/components/Calculadora";
import { FAQS } from "@/config/faq";
import { EMPRESA, LANCAMENTO, MARCA, linkWhatsApp } from "@/config/marca";
import { MODULOS, PLANOS, reais } from "@/config/planos";
import { usePagina } from "@/config/paginas";
import { ListaDeGuias } from "./Guias";

/**
 * Página inicial do site da plataforma. Estrutura herdada do site da Minha Maleta (mesma lógica de venda:
 * pergunta que o dono não sabe responder → calculadora com os números dele → antes × depois → funções →
 * como funciona → comparativo → preço → perguntas), com o conteúdo da pizzaria (docs/PRD.md e docs/PLANO-DE-NEGOCIO.md).
 *
 * Regras desta página:
 *  - só promete o que está no PRD; o que não entra na 1ª versão aparece como "próximas etapas";
 *  - nenhum depoimento, cliente ou número inventado: os números são os da pizzaria fictícia de demonstração, ditos assim;
 *  - "?espacos" no endereço mostra onde entram fotos, vídeo e depoimentos que ainda vão chegar.
 */

const FATOS: [string, string][] = [
  [`${LANCAMENTO.diasDeTeste} dias grátis`, "com uma pizzaria de exemplo já carregada"],
  ["Link próprio", "pedido sem comissão para o marketplace"],
  ["Celular e balcão", "no navegador, sem instalar nada"],
  ["Gente de verdade", `no atendimento, em ${EMPRESA.cidade.split("/")[0]}`],
];

/** O que entra na 1ª versão (PRD, release R1). */
const FUNCOES: { titulo: string; texto: string }[] = [
  {
    titulo: "Seu link de pedidos",
    texto: `Cardápio digital com a sua marca, pizza meio a meio montada pelo cliente, frete por bairro e Pix online. O endereço é seu (${MARCA.linkDePedidos}/sua-pizzaria) e o cliente também.`,
  },
  {
    titulo: "Todo pedido num painel só",
    texto: "Link, balcão e telefone caem na mesma fila, com alerta sonoro e status do forno à entrega. O cliente acompanha o pedido por um link e para de ligar perguntando.",
  },
  {
    titulo: "Caixa que bate",
    texto: "Abertura com troco, sangria, pagamentos mistos e fechamento cego: o operador conta sem ver o valor esperado, e a diferença aparece na hora.",
  },
  {
    titulo: "Quem sumiu, todo dia",
    texto: "Toda madrugada o sistema lê o histórico e separa em cartões: quem saiu do ritmo, quem passou de 25 dias, quem pediu uma vez e não voltou, quem faz aniversário.",
  },
  {
    titulo: "Mensagem pronta em 3 toques",
    texto: "Cada cliente vem com a mensagem escrita: o nome, a pizza favorita, o seu link. Você confere e envia no seu WhatsApp. E o sistema mostra quem voltou a pedir depois.",
  },
  {
    titulo: "Nota fiscal",
    texto: "NFC-e e NF-e emitidas do próprio caixa, com contingência. Vem no Premium e é módulo nos outros planos.",
  },
];

/** O que vem depois (PRD, releases R2 a R4). */
const PROXIMAS_ETAPAS: [string, string][] = [
  ["2ª etapa", "Tela da cozinha · entregadores e rotas · cupons e fidelidade · financeiro com conciliação · iFood e 99Food · impressão automática"],
  ["3ª etapa", "Estoque, ficha técnica e custo por pizza · compras · salão e mesas · funciona sem internet"],
  ["4ª etapa", "Várias lojas e franquias · WhatsApp oficial e robô de pedidos · previsão de demanda com IA"],
];

const COMPARATIVO: [string, "sim" | "parcial" | "nao", "sim" | "parcial" | "nao", "sim" | "parcial" | "nao"][] = [
  ["Ficar com o contato e o histórico do cliente", "parcial", "nao", "sim"],
  ["Pedido sem comissão", "sim", "nao", "sim"],
  ["Pedidos de todos os canais num lugar só", "nao", "nao", "sim"],
  ["Saber quem parou de pedir", "nao", "nao", "sim"],
  ["Mensagem pronta e medir quem voltou", "nao", "parcial", "sim"],
  ["Caixa com fechamento conferido", "nao", "nao", "sim"],
];

const Selo = ({ v, destaque }: { v: "sim" | "parcial" | "nao"; destaque: boolean }) => (
  <span className="inline-flex flex-col items-center">
    <span aria-hidden className={`text-lg ${v === "sim" ? (destaque ? "text-manjericao" : "text-texto") : "text-texto/50"}`}>
      {{ sim: "✓", parcial: "~", nao: "—" }[v]}
    </span>
    <span className="sr-only">{{ sim: "Sim", parcial: "Parcial", nao: "Não" }[v]}</span>
  </span>
);

/** Dados estruturados da página inicial: vão no HTML (o pré-renderizador grava) para o Google ler sem JavaScript. */
const JSON_LD = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "SoftwareApplication",
      name: MARCA.nome,
      applicationCategory: "BusinessApplication",
      operatingSystem: "Web",
      description: MARCA.descricaoCurta,
      offers: PLANOS.map((p) => ({ "@type": "Offer", name: `Plano ${p.nome}`, price: (p.centavos / 100).toFixed(2), priceCurrency: "BRL" })),
    },
    {
      "@type": "Organization",
      name: MARCA.nome,
      url: `${MARCA.site}/`,
      logo: `${MARCA.site}/icon-512.png`,
      email: EMPRESA.email,
      address: { "@type": "PostalAddress", addressLocality: EMPRESA.cidade.split("/")[0], addressRegion: EMPRESA.cidade.split("/")[1], addressCountry: "BR" },
    },
    {
      "@type": "FAQPage",
      mainEntity: FAQS.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
    },
  ],
};

export default function Inicio() {
  usePagina("/");
  const espacos = new URLSearchParams(useLocation().search).has("espacos");
  const preLancamento = LANCAMENTO.fase === "pre-lancamento";

  return (
    <main className="min-h-dvh overflow-x-clip">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(JSON_LD) }} />
      <Cabecalho />

      {/* ───────── Topo ───────── */}
      <section className="relative overflow-hidden bg-gradient-to-b from-creme to-white">
        <div className="relative mx-auto grid max-w-6xl items-center gap-14 px-5 pb-20 pt-12 md:grid-cols-[1.15fr_0.85fr] md:gap-10 md:pb-28 md:pt-20">
          <div>
            <Sobretitulo>Sistema de gestão para pizzarias</Sobretitulo>
            <h1 className="text-[2.45rem] font-semibold leading-[1.03] tracking-[-0.035em] sm:text-[3.4rem] md:text-[3.9rem]">
              Quantos clientes <span className="text-tomate">pararam de pedir</span> na sua pizzaria este mês?
            </h1>
            <p className="mt-7 max-w-xl text-lg leading-relaxed sm:text-xl">
              A {MARCA.nome} junta os pedidos do link, do balcão e do telefone, fecha o caixa sem diferença e, todo dia,
              mostra quem sumiu, com a mensagem de WhatsApp pronta para trazer de volta.
            </p>
            <div className="mt-9 flex flex-col gap-4 sm:flex-row sm:items-center">
              <CtaPrincipal className="self-start" />
              <span className="text-sm">
                {preLancamento
                  ? `Em construção · avisamos quando abrir`
                  : `${LANCAMENTO.diasDeTeste} dias grátis`}
              </span>
            </div>
            <a href={linkWhatsApp()} target="_blank" rel="noopener noreferrer"
              className="mt-5 inline-flex min-h-11 items-center text-sm underline decoration-farinha underline-offset-4 hover:text-tomate-escuro">
              Tirar dúvida no WhatsApp · {EMPRESA.horarioAtendimento}
            </a>
          </div>
          <figure className="relative mx-auto w-full max-w-[320px] md:mr-0">
            <Celular>
              <TelaOportunidades />
            </Celular>
            <div className="absolute -left-6 bottom-6 sm:-left-20 md:-left-36">
              <BalaoWhatsApp />
            </div>
            <figcaption className="mt-4 text-center text-xs">Tela ilustrativa, com os números da pizzaria fictícia de demonstração.</figcaption>
          </figure>
        </div>
      </section>

      {/* Fatos, não adjetivos */}
      <section aria-label="Em resumo" className="border-y border-farinha">
        <dl className="mx-auto grid max-w-6xl grid-cols-2 gap-px bg-farinha md:grid-cols-4">
          {FATOS.map(([forte, fraco]) => (
            <div key={forte} className="bg-white px-5 py-6 md:px-8 md:py-8">
              <dt className="font-titulo text-xl font-semibold tracking-[-0.02em] text-carvao">{forte}</dt>
              <dd className="mt-1 text-sm">{fraco}</dd>
            </div>
          ))}
        </dl>
      </section>

      {/* ───────── Calculadora ───────── */}
      <section id="calculadora" className="scroll-mt-20">
        <div className="mx-auto grid max-w-6xl items-start gap-12 px-5 py-20 md:grid-cols-[0.9fr_1.1fr] md:gap-16 md:py-28">
          <div className="md:sticky md:top-28">
            <Sobretitulo>A conta do mês</Sobretitulo>
            <Titulo className="text-[2.2rem] sm:text-5xl">
              Cliente que some <Ideia>não avisa.</Ideia>
            </Titulo>
            <p className="mt-6 max-w-md text-lg leading-relaxed">
              Ele só para de pedir. E cada pedido que chega pelo marketplace deixa uma comissão e esconde o contato de quem
              comprou. Coloque os seus números e veja quanto isso pesa.
            </p>
            <p className="mt-5 max-w-md text-base leading-relaxed">
              Na pizzaria de demonstração, com 900 clientes e 29 pedidos por dia, o sistema encontrou <strong className="text-carvao">218 clientes
              para chamar num único dia</strong>. Bastam 2 pedidos recuperados por mês para pagar o CRM.
            </p>
          </div>
          <Calculadora />
        </div>
      </section>

      {/* ───────── Antes × depois ───────── */}
      <section className="bg-creme">
        <div className="mx-auto max-w-6xl px-5 py-20 md:py-28">
          <div className="max-w-3xl">
            <Titulo className="text-[2.2rem] sm:text-5xl">
              O caderno anota o pedido. <Ideia>Não lembra do cliente.</Ideia>
            </Titulo>
            <p className="mt-6 text-lg leading-relaxed">
              Pedido no WhatsApp, no telefone, no balcão e no tablet do marketplace, cada um num lugar. No fim da noite o caixa
              não bate e ninguém percebeu que aquela cliente que pedia toda sexta sumiu faz um mês.
            </p>
          </div>
          <div className="mt-12 grid gap-5 md:grid-cols-2">
            <div className="rounded-3xl bg-[#FBF6EE] p-7 shadow-[0_0_0_1px_rgba(42,29,23,.06)] md:p-9">
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em]">Hoje, sem sistema</p>
              <ul className="mt-6 space-y-3.5 text-[16px]">
                {[
                  "Pedido redigitado do WhatsApp para a comanda",
                  "O marketplace fica com a comissão e com o contato",
                  "Caixa fechado na calculadora, diferença no bolso",
                  "Ninguém sabe quem parou de pedir",
                  "Promoção mandada para todo mundo, do mesmo jeito",
                ].map((t) => (
                  <li key={t} className="flex gap-3"><span aria-hidden className="text-texto/60">✕</span>{t}</li>
                ))}
              </ul>
            </div>
            <div className="rounded-3xl bg-white p-7 shadow-[0_0_0_1.5px_#C2361C,0_30px_70px_-40px_rgba(194,54,28,.5)] md:p-9">
              <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-tomate-escuro">Com a {MARCA.nome}</p>
              <ul className="mt-6 space-y-3.5 text-[16px] text-carvao">
                {[
                  "Pedido do link cai pronto no painel e na cozinha",
                  "Link próprio: o cliente e o histórico ficam com você",
                  "Fechamento cego: a diferença aparece na hora",
                  "Todo dia, a lista de quem sumiu e por quê",
                  "Mensagem com o nome e a pizza favorita de cada um",
                ].map((t) => (
                  <li key={t} className="flex gap-3"><span aria-hidden className="text-manjericao">✓</span>{t}</li>
                ))}
              </ul>
            </div>
          </div>
          {espacos && (
            <div className="mt-12">
              <EspacoMidia tipo="FOTO" proporcao="16:9" descricao="Antes e depois: o balcão com papel de comanda e celular cheio de mensagens × o dono vendo as oportunidades no celular." />
            </div>
          )}
        </div>
      </section>

      {/* ───────── O que faz ───────── */}
      <section id="funcoes" className="scroll-mt-16">
        <div className="mx-auto max-w-6xl px-5 py-20 md:py-28">
          <Sobretitulo>O que tem dentro</Sobretitulo>
          <Titulo className="max-w-3xl text-[2.2rem] sm:text-5xl">
            Da massa ao caixa, <Ideia>num lugar só.</Ideia>
          </Titulo>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed">
            Tudo o que entra na primeira versão. A tela continua simples: o atendente vê pedidos, caixa e clientes; a gestão fica
            para o dono.
          </p>
          <ol className="mt-14 grid gap-px overflow-hidden rounded-3xl bg-farinha sm:grid-cols-2 lg:grid-cols-3">
            {FUNCOES.map((f, i) => (
              <li key={f.titulo} className="bg-white p-7 md:p-8">
                <span aria-hidden className="font-titulo text-xl font-semibold tabular-nums text-tomate">{String(i + 1).padStart(2, "0")}</span>
                <h3 className="mt-3 text-[1.45rem] font-semibold leading-tight tracking-[-0.025em]">{f.titulo}</h3>
                <p className="mt-3 text-[15.5px] leading-relaxed">{f.texto}</p>
              </li>
            ))}
          </ol>
          <div className="mt-10 rounded-3xl bg-creme p-7 md:p-9">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-tomate-escuro">Nas próximas etapas</p>
            <dl className="mt-5 space-y-4">
              {PROXIMAS_ETAPAS.map(([etapa, itens]) => (
                <div key={etapa} className="grid gap-1 sm:grid-cols-[120px_1fr]">
                  <dt className="font-medium text-carvao">{etapa}</dt>
                  <dd className="text-[15px]">{itens}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </section>

      {/* ───────── Como funciona ───────── */}
      <section id="como-funciona" className="scroll-mt-16 bg-carvao">
        <div className="mx-auto max-w-6xl px-5 py-20 md:py-28">
          <Sobretitulo className="text-brasa-clara">Três passos</Sobretitulo>
          <Titulo claro className="mb-14 text-[2.2rem] sm:text-5xl">Como funciona</Titulo>
          <ol className="grid gap-12 md:grid-cols-3 md:gap-8">
            {[
              ["Monte o cardápio", "Tamanhos, sabores, bordas, bebidas e frete por bairro. A meta é ter o cardápio inteiro pronto em até 1 hora."],
              ["Divulgue o seu link", "Na bio do Instagram, no status e no WhatsApp. Todo pedido entra com o cliente identificado e monta o histórico sozinho."],
              ["Chame quem sumiu", "Toda tarde, antes do pico, a lista do dia: quem chamar, por quê e a mensagem pronta. Depois, quem voltou."],
            ].map(([t, txt], i) => (
              <li key={t}>
                <div className="mb-6 flex items-center gap-4">
                  <span aria-hidden className="font-titulo text-4xl font-semibold tabular-nums text-brasa">{String(i + 1).padStart(2, "0")}</span>
                  <span aria-hidden className="h-px flex-1 bg-white/15" />
                </div>
                <h3 className="text-xl font-semibold !text-white">{t}</h3>
                <p className="mt-2 text-[15.5px] leading-relaxed text-[#E9DDD3]">{txt}</p>
              </li>
            ))}
          </ol>
          <p className="mt-14 rounded-2xl border border-white/10 px-5 py-4 font-titulo text-base tracking-wide text-brasa-clara sm:text-lg">
            Pedido → histórico → quem sumiu → mensagem → novo pedido. E a conta de quantos voltaram.
          </p>
        </div>
      </section>

      {/* ───────── Comparativo ───────── */}
      <section>
        <div className="mx-auto max-w-4xl px-5 py-20 md:py-28">
          <Titulo className="text-[2rem] sm:text-[2.7rem]">
            WhatsApp, marketplace ou {MARCA.nome}: <Ideia>compare.</Ideia>
          </Titulo>
          <p className="mt-5 text-lg leading-relaxed">Comparamos jeitos de vender, não marcas.</p>
          <div className="mt-10 overflow-hidden rounded-3xl bg-white shadow-[0_0_0_1px_#F0E2CF]">
            <table className="w-full text-left text-[14px] sm:text-[15px]">
              <caption className="sr-only">Comparação entre pedir pelo WhatsApp, pelo marketplace e pela {MARCA.nome}</caption>
              <thead>
                <tr>
                  <th scope="col" className="px-4 py-4 font-normal sm:px-6">O que a pizzaria precisa</th>
                  <th scope="col" className="w-[17%] px-1 py-4 text-center font-normal">WhatsApp e caderno</th>
                  <th scope="col" className="w-[17%] px-1 py-4 text-center font-normal">Marketplace</th>
                  <th scope="col" className="w-[19%] bg-creme px-1 py-4 text-center font-semibold text-tomate">{MARCA.nome}</th>
                </tr>
              </thead>
              <tbody>
                {COMPARATIVO.map(([item, ...cel]) => (
                  <tr key={item} className="border-t border-farinha">
                    <th scope="row" className="px-4 py-4 font-normal text-carvao sm:px-6">{item}</th>
                    {cel.map((c, i) => (
                      <td key={i} className={`px-1 py-4 text-center ${i === 2 ? "bg-creme" : ""}`}><Selo v={c} destaque={i === 2} /></td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="mt-4 text-xs">Parcial = dá para fazer, mas na mão ou pela metade.</p>
        </div>
      </section>

      {/* ───────── Confiança ───────── */}
      <section className="bg-creme">
        <div className="mx-auto grid max-w-6xl gap-10 px-5 py-20 md:grid-cols-2 md:gap-20 md:py-28">
          <div>
            <Sobretitulo>Sem spam, sem susto</Sobretitulo>
            <Titulo className="text-[2.2rem] sm:text-5xl">
              Nenhuma mensagem sai <Ideia>sem você aprovar.</Ideia>
            </Titulo>
          </div>
          <ul className="space-y-6 text-lg leading-relaxed md:pt-12">
            <li><strong className="text-carvao">Só quem autorizou.</strong> O cliente marca no pedido se quer receber novidades, e pode sair quando quiser. É o que a LGPD pede.</li>
            <li><strong className="text-carvao">No máximo uma por semana.</strong> O sistema segura o envio para ninguém se sentir perseguido e o seu número não ser bloqueado.</li>
            <li><strong className="text-carvao">Só fatos.</strong> A mensagem cita o que está no histórico, como a pizza favorita. Nunca inventa promoção que você não fez.</li>
            <li><strong className="text-carvao">Seus dados são seus.</strong> Cada pizzaria só vê os próprios dados, com acesso protegido em duas etapas.</li>
          </ul>
        </div>
      </section>

      {/* Depoimentos: só com depoimento real e autorizado, ou com "?espacos" */}
      {espacos && (
        <section>
          <div className="mx-auto max-w-6xl px-5 py-20">
            <Titulo className="mb-10 text-[2rem]">Pizzarias que já usam</Titulo>
            <div className="grid gap-5 sm:grid-cols-3">
              {[1, 2, 3].map((n) => (
                <EspacoMidia key={n} tipo="DEPOIMENTO" proporcao="4:3" descricao={`Depoimento ${n}: foto do dono (com autorização por escrito), nome da pizzaria, cidade e um número real, ex.: pedidos recuperados em 30 dias.`} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ───────── Planos ───────── */}
      <section id="planos" className="scroll-mt-16">
        <div className="mx-auto max-w-6xl px-5 py-20 md:py-28">
          <Sobretitulo>Planos</Sobretitulo>
          <Titulo className="max-w-3xl text-[2.2rem] sm:text-5xl">
            Comece pelo plano que cabe <Ideia>e ligue o resto depois.</Ideia>
          </Titulo>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed">
            Preço por loja, por mês. Sem fidelidade no mensal. No anual, 2 meses grátis e implantação sem custo.
          </p>
          <div className="mt-12 grid gap-5 lg:grid-cols-3">
            {PLANOS.map((p) => (
              <article key={p.id}
                className={`flex flex-col rounded-3xl p-7 sm:p-8 ${p.destaque ? "bg-carvao text-[#E9DDD3] shadow-[0_30px_70px_-35px_rgba(42,29,23,.7)]" : "bg-white shadow-[0_0_0_1px_#F0E2CF]"}`}>
                <div className="flex items-center justify-between gap-3">
                  <h3 className={`text-2xl font-semibold tracking-[-0.02em] ${p.destaque ? "!text-white" : ""}`}>{p.nome}</h3>
                  {p.destaque && <span className="rounded-full bg-brasa px-3 py-1 text-xs font-semibold text-carvao">Recomendado</span>}
                </div>
                <p className="mt-2 text-sm">{p.paraQuem}</p>
                <p className="mt-6 tabular-nums">
                  <span className={`font-titulo text-[2.6rem] font-semibold tracking-[-0.03em] ${p.destaque ? "text-brasa-clara" : "text-carvao"}`}>{reais(p.centavos)}</span>
                  <span className="text-sm">/mês</span>
                </p>
                <p className={`mt-3 rounded-xl px-3.5 py-2.5 text-[13px] leading-snug ${p.destaque ? "bg-white/10" : "bg-creme"}`}>{p.situacao}</p>
                <ul className="mt-6 flex-1 space-y-2.5 text-[15px]">
                  {p.itens.map((t) => (
                    <li key={t} className="flex gap-3"><span aria-hidden className={p.destaque ? "text-brasa" : "text-manjericao"}>✓</span>{t}</li>
                  ))}
                </ul>
                <CtaPrincipal claro={p.destaque} plano={p.id} className="mt-8 w-full">
                  {LANCAMENTO.fase === "aberto" ? `Testar o ${p.nome}` : `Quero o ${p.nome}`}
                </CtaPrincipal>
              </article>
            ))}
          </div>
          <div className="mt-10 rounded-3xl bg-creme p-7 md:p-9">
            <p className="text-[11px] font-semibold uppercase tracking-[0.22em] text-tomate-escuro">Módulos que ligam em qualquer plano</p>
            <ul className="mt-5 grid gap-x-10 gap-y-2.5 text-[15px] sm:grid-cols-2 lg:grid-cols-3">
              {MODULOS.map((m) => (
                <li key={m.nome} className="flex justify-between gap-3 border-b border-farinha pb-2.5">
                  <span>{m.nome}</span><span className="whitespace-nowrap tabular-nums text-carvao">{m.preco}</span>
                </li>
              ))}
            </ul>
          </div>
          <p className="mt-5 text-xs">Preços previstos para a abertura: podem mudar até lá.</p>
        </div>
      </section>

      {/* ───────── Perguntas ───────── */}
      <section id="perguntas" className="scroll-mt-16 bg-creme">
        <div className="mx-auto grid max-w-6xl gap-10 px-5 py-20 md:grid-cols-[0.8fr_1.2fr] md:gap-16 md:py-28">
          <div>
            <Titulo className="text-[2.2rem] sm:text-5xl">Perguntas</Titulo>
            <p className="mt-6">
              Ficou alguma dúvida?{" "}
              <a href={linkWhatsApp()} target="_blank" rel="noopener noreferrer" className="font-medium text-tomate-escuro underline underline-offset-4">
                Fale com a gente no WhatsApp
              </a>
              .
            </p>
          </div>
          <div className="border-t border-farinha">
            {FAQS.map((f) => (
              <details key={f.q} className="group border-b border-farinha">
                <summary className="flex min-h-11 cursor-pointer list-none items-center justify-between gap-4 py-5 text-base font-medium text-carvao [&::-webkit-details-marker]:hidden">
                  {f.q}
                  <span aria-hidden className="text-xl text-tomate transition-transform group-open:rotate-45">+</span>
                </summary>
                <p className="pb-5 pr-8 text-[15px] leading-relaxed">{f.a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* ───────── Guias: é por links assim que o Google acha as páginas novas ───────── */}
      <section aria-label="Guias para donos de pizzaria">
        <div className="mx-auto max-w-6xl px-5 py-16 md:py-20">
          <Sobretitulo>Guias para donos de pizzaria</Sobretitulo>
          <Titulo className="mb-8 text-[2rem] sm:text-4xl">
            Contas de verdade, <Ideia>em reais.</Ideia>
          </Titulo>
          <ListaDeGuias />
        </div>
      </section>

      {/* ───────── Fechamento ───────── */}
      <section className="bg-carvao">
        <div className="mx-auto max-w-4xl px-5 py-20 text-center md:py-24">
          <h2 className="text-[2rem] font-semibold leading-[1.06] tracking-[-0.03em] !text-white sm:text-[2.7rem] md:text-[3.1rem]">
            O forno já está quente. <span className="text-brasa-clara">Falta chamar quem sumiu.</span>
          </h2>
          <CtaPrincipal claro className="mt-10" />
        </div>
      </section>

      <Rodape />

      {/* Botão fixo no celular: é onde o dono está */}
      <div className="fixed inset-x-0 bottom-0 z-40 border-t border-farinha bg-white/95 p-3 pb-[calc(env(safe-area-inset-bottom)+0.75rem)] backdrop-blur-xl md:hidden">
        <CtaPrincipal className="w-full" />
      </div>
      <div className="h-20 md:hidden" aria-hidden />
    </main>
  );
}
