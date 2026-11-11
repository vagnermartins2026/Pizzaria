import { Link, useParams } from "react-router-dom";
import { Cabecalho, CtaPrincipal, Ideia, Rodape, Sobretitulo } from "@/components/Base";
import { GUIAS } from "@/config/guias";
import { MARCA } from "@/config/marca";
import { urlAbsoluta, usePagina } from "@/config/paginas";
import NaoEncontrada from "./NaoEncontrada";

/** Cartões com os guias (usado em /guias e no fim da página inicial). */
export function ListaDeGuias({ exceto, nivel = 3 }: { exceto?: string; nivel?: 2 | 3 }) {
  const T = nivel === 2 ? "h2" : "h3";
  return (
    <ul className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {GUIAS.filter((g) => g.slug !== exceto).map((g) => (
        <li key={g.slug}>
          <Link to={`/guias/${g.slug}`} className="block h-full rounded-2xl bg-white p-6 shadow-[0_0_0_1px_#F0E2CF] transition-shadow hover:shadow-md">
            <T className="text-lg font-semibold leading-snug tracking-[-0.015em]">{g.h1}</T>
            <p className="mt-2 text-sm leading-relaxed">{g.resumo}</p>
            <span className="mt-3 inline-block text-sm font-medium text-tomate-escuro">Ler o guia →</span>
          </Link>
        </li>
      ))}
    </ul>
  );
}

export function Guias() {
  usePagina("/guias");
  return (
    <main className="min-h-dvh">
      <Cabecalho />
      <section className="bg-creme">
        <div className="mx-auto max-w-6xl px-5 py-16 md:py-24">
          <Sobretitulo>Guias para donos de pizzaria</Sobretitulo>
          <h1 className="max-w-3xl text-[2.3rem] font-semibold leading-[1.05] tracking-[-0.035em] sm:text-5xl">
            Contas de verdade, <Ideia>em reais.</Ideia>
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed">Para decidir com número, não com achismo. Os valores são de exemplo: troque pelos seus.</p>
          <div className="mt-12"><ListaDeGuias nivel={2} /></div>
        </div>
      </section>
      <Rodape />
    </main>
  );
}

export function Guia() {
  const { slug } = useParams();
  const guia = GUIAS.find((g) => g.slug === slug);
  usePagina(`/guias/${slug}`);
  if (!guia) return <NaoEncontrada />;
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: guia.h1,
    description: guia.descricao,
    inLanguage: "pt-BR",
    mainEntityOfPage: urlAbsoluta(`/guias/${guia.slug}`),
    publisher: { "@type": "Organization", name: MARCA.nome },
  };
  return (
    <main className="min-h-dvh">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
      <Cabecalho />
      <article className="mx-auto max-w-3xl px-5 py-14 md:py-20">
        <nav aria-label="Você está em" className="mb-8 text-sm">
          <Link to="/" className="underline-offset-4 hover:underline">Início</Link> ›{" "}
          <Link to="/guias" className="underline-offset-4 hover:underline">Guias</Link>
        </nav>
        <h1 className="text-[2.2rem] font-semibold leading-[1.08] tracking-[-0.03em] sm:text-5xl">{guia.h1}</h1>
        <p className="mt-6 rounded-2xl bg-creme p-5 text-lg leading-relaxed text-carvao"><strong>Resumo:</strong> {guia.resumo}</p>
        {guia.secoes.map((s) => (
          <section key={s.titulo} className="mt-12">
            <h2 className="text-2xl font-semibold tracking-[-0.02em]">{s.titulo}</h2>
            {s.paragrafos.map((p) => <p key={p.slice(0, 40)} className="mt-4 text-[17px] leading-relaxed">{p}</p>)}
            {s.tabela && (
              <div className="mt-6 overflow-hidden rounded-2xl shadow-[0_0_0_1px_#F0E2CF]">
                <table className="w-full text-left text-[15px] tabular-nums">
                  <thead className="bg-creme">
                    <tr>{s.tabela.cabecalho.map((c) => <th key={c} scope="col" className="px-4 py-3 font-medium text-carvao">{c}</th>)}</tr>
                  </thead>
                  <tbody>
                    {s.tabela.linhas.map(([a, b]) => (
                      <tr key={a} className="border-t border-farinha"><td className="px-4 py-3">{a}</td><td className="px-4 py-3 text-carvao">{b}</td></tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        ))}
        <div className="mt-16 rounded-3xl bg-carvao p-7 text-[#E9DDD3] sm:p-9">
          <p className="font-titulo text-2xl font-semibold leading-tight tracking-[-0.02em] text-white">
            A {MARCA.nome} faz essas contas por você, todo dia.
          </p>
          <p className="mt-3 leading-relaxed">Pedidos, caixa e a lista de quem sumiu, com a mensagem pronta no WhatsApp.</p>
          <CtaPrincipal claro className="mt-7" />
        </div>
        <section className="mt-16">
          <h2 className="mb-6 text-xl font-semibold">Outros guias</h2>
          <ListaDeGuias exceto={guia.slug} />
        </section>
      </article>
      <Rodape />
    </main>
  );
}
