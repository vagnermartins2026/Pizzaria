import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { Cabecalho, Rodape, Sobretitulo } from "@/components/Base";
import { EMPRESA, LANCAMENTO, MARCA, linkWhatsApp } from "@/config/marca";
import { descreverOrigem, lerOrigem } from "@/config/origem";
import { PLANOS } from "@/config/planos";
import { usePagina } from "@/config/paginas";

/**
 * Pré-cadastro das pizzarias fundadoras (fase "pre-lancamento" em config/marca.ts).
 * Não tem banco: o formulário só monta a mensagem e abre o WhatsApp comercial. Nada fica guardado no site.
 * Quando o sistema abrir o cadastro (fase "aberto"), os botões do site passam a ir direto para `${MARCA.app}/cadastro`
 * e esta página vira a lista de espera ou sai do ar.
 */
export type Dados = { nome: string; pizzaria: string; cidade: string; whatsapp: string; pedidos: string; plano: string; canais: string[] };

const CANAIS = ["WhatsApp", "Telefone", "Balcão", "iFood ou outro marketplace", "Site ou link próprio"];
const FAIXAS = ["Até 20", "20 a 50", "50 a 100", "Mais de 100"];

/** WhatsApp brasileiro: DDD + 8 ou 9 dígitos, com ou sem máscara e com ou sem +55. */
export function whatsappValido(texto: string): boolean {
  let n = texto.replace(/\D/g, "");
  if (n.length >= 12 && n.startsWith("55")) n = n.slice(2);
  return (n.length === 10 || n.length === 11) && !n.startsWith("0");
}

export function montarMensagem(d: Dados, origem = "") {
  const plano = PLANOS.find((p) => p.id === d.plano)?.nome;
  return [
    `Olá! Quero ser uma das pizzarias fundadoras da ${MARCA.nome}.`,
    "",
    `Nome: ${d.nome}`,
    `Pizzaria: ${d.pizzaria}`,
    `Cidade: ${d.cidade}`,
    `WhatsApp: ${d.whatsapp}`,
    `Pedidos por dia: ${d.pedidos || "não informei"}`,
    `Hoje recebo pedidos por: ${d.canais.length ? d.canais.join(", ") : "não informei"}`,
    `Plano de interesse: ${plano ?? "ainda não sei"}`,
    ...(origem ? [`Cheguei por: ${origem}`] : []),
  ].join("\n");
}

export default function Fundadores() {
  usePagina("/fundadores");
  const [busca] = useSearchParams();
  const planoDoLink = PLANOS.some((p) => p.id === busca.get("plano")) ? busca.get("plano")! : "";
  const [d, setD] = useState<Dados>({ nome: "", pizzaria: "", cidade: "", whatsapp: "", pedidos: "", plano: planoDoLink, canais: [] });
  useEffect(() => setD((atual) => ({ ...atual, plano: planoDoLink || atual.plano })), [planoDoLink]);
  const [erro, setErro] = useState("");
  const muda = (campo: keyof Dados) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => setD({ ...d, [campo]: e.target.value });

  function enviar(e: React.FormEvent) {
    e.preventDefault();
    if (!d.nome.trim() || !d.pizzaria.trim() || !d.cidade.trim()) return setErro("Preencha seu nome, o nome da pizzaria e a cidade.");
    if (!whatsappValido(d.whatsapp)) return setErro("Confira o WhatsApp: DDD + número, ex.: (19) 99999-9999.");
    setErro("");
    window.open(linkWhatsApp(montarMensagem(d, descreverOrigem(lerOrigem()))), "_blank", "noopener,noreferrer");
  }

  const campo = "mt-1.5 block h-12 w-full rounded-xl border border-farinha bg-white px-4 text-base text-carvao outline-none focus:border-tomate";

  return (
    <main className="min-h-dvh">
      <Cabecalho simples />
      <section className="bg-gradient-to-b from-creme to-white">
        <div className="mx-auto grid max-w-6xl gap-12 px-5 py-14 md:grid-cols-[0.9fr_1.1fr] md:gap-16 md:py-20">
          <div>
            <Sobretitulo>Pizzarias fundadoras</Sobretitulo>
            <h1 className="text-[2.3rem] font-semibold leading-[1.05] tracking-[-0.035em] sm:text-5xl">
              Seja uma das {LANCAMENTO.vagasFundadores} primeiras.
            </h1>
            <ul className="mt-8 space-y-4 text-lg leading-relaxed">
              <li><strong className="text-carvao">{LANCAMENTO.descontoFundadores}</strong> no plano que escolher.</li>
              <li><strong className="text-carvao">Implantação com a gente:</strong> montamos o cardápio junto e treinamos a equipe.</li>
              <li><strong className="text-carvao">Voz no produto:</strong> uma conversa a cada 15 dias com quem está construindo.</li>
              <li><strong className="text-carvao">Em troca:</strong> você usa de verdade e, se gostar, conta como foi.</li>
            </ul>
            <p className="mt-8 text-sm leading-relaxed">
              O sistema está em construção. Vamos chamar as fundadoras por ordem de inscrição, quando a primeira versão estiver
              pronta para o dia a dia da pizzaria.
            </p>
          </div>

          <form onSubmit={enviar} noValidate className="rounded-3xl bg-white p-6 shadow-[0_0_0_1px_#F0E2CF,0_30px_70px_-40px_rgba(194,54,28,.45)] sm:p-8">
            <div className="grid gap-5 sm:grid-cols-2">
              <label className="text-sm sm:col-span-2">Seu nome<input className={campo} value={d.nome} onChange={muda("nome")} autoComplete="name" required /></label>
              <label className="text-sm">Nome da pizzaria<input className={campo} value={d.pizzaria} onChange={muda("pizzaria")} autoComplete="organization" required /></label>
              <label className="text-sm">Cidade<input className={campo} value={d.cidade} onChange={muda("cidade")} autoComplete="address-level2" required /></label>
              <label className="text-sm">WhatsApp<input className={campo} value={d.whatsapp} onChange={muda("whatsapp")} inputMode="tel" autoComplete="tel" placeholder="(19) 99999-9999" required /></label>
              <label className="text-sm">Pedidos por dia
                <select className={campo} value={d.pedidos} onChange={muda("pedidos")}>
                  <option value="">Escolha</option>
                  {FAIXAS.map((f) => <option key={f}>{f}</option>)}
                </select>
              </label>
              <label className="text-sm sm:col-span-2">Plano de interesse
                <select className={campo} value={d.plano} onChange={muda("plano")}>
                  <option value="">Ainda não sei</option>
                  {PLANOS.map((p) => <option key={p.id} value={p.id}>{p.nome}</option>)}
                </select>
              </label>
            </div>
            <fieldset className="mt-6">
              <legend className="text-sm">Hoje você recebe pedidos por</legend>
              <div className="mt-2 flex flex-wrap gap-2">
                {CANAIS.map((c) => {
                  const marcado = d.canais.includes(c);
                  return (
                    <label key={c} className={`inline-flex min-h-11 cursor-pointer items-center rounded-full border px-4 text-sm ${marcado ? "border-tomate bg-tomate/10 text-tomate-escuro" : "border-farinha"}`}>
                      <input type="checkbox" className="sr-only" checked={marcado}
                        onChange={() => setD({ ...d, canais: marcado ? d.canais.filter((x) => x !== c) : [...d.canais, c] })} />
                      {c}
                    </label>
                  );
                })}
              </div>
            </fieldset>
            {erro && <p role="alert" className="mt-5 rounded-xl bg-tomate/10 px-4 py-3 text-sm text-tomate-escuro">{erro}</p>}
            <button type="submit" className="mt-7 inline-flex h-12 w-full items-center justify-center rounded-full bg-[#13803F] px-7 text-base font-medium text-white hover:opacity-95">
              Enviar pelo WhatsApp
            </button>
            <p className="mt-4 text-xs leading-relaxed">
              Este site não guarda o que você preenche: os dados vão só na mensagem que abre no seu WhatsApp, para o número
              comercial {EMPRESA.whatsappVisivel}. Veja a <Link to="/privacidade" className="underline">Política de Privacidade</Link>.
            </p>
          </form>
        </div>
      </section>
      <Rodape />
    </main>
  );
}
