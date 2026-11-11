/**
 * A tela "Oportunidades" do painel (PRD, seção 6.1), desenhada em HTML porque o sistema ainda não tem telas.
 * Os números e frases são os REAIS do motor do CRM rodando sobre a pizzaria fictícia Forno da Vila (DEMO):
 * demo/gabarito_2026-11-08.txt. Quando o painel existir, troque por prints/vídeo das telas reais.
 */

const CARTOES = [
  {
    titulo: "45 clientes frequentes saíram do ritmo",
    exemplo: "Sofia M. não pede há 38 dias. Antes pedia a cada ~8 dias. Favorita: Portuguesa.",
    vip: true,
  },
  {
    titulo: "47 clientes passaram de 25 dias sem pedir",
    exemplo: "Rafael G. não pede há 38 dias. Favorita: Romeu e Julieta.",
  },
  {
    titulo: "25 clientes pediram uma vez e não voltaram",
    exemplo: "A segunda compra é a que mais define se o cliente fica.",
  },
];

export function TelaOportunidades() {
  return (
    <div className="flex h-full flex-col bg-creme text-[11px] leading-snug text-carvao">
      <div className="bg-white px-4 pb-2 pt-9">
        <p className="text-[9px] font-semibold uppercase tracking-[0.18em] text-tomate-escuro">Forno da Vila · demo</p>
        <p className="mt-0.5 font-titulo text-[17px] font-semibold tracking-[-0.02em]">Oportunidades de hoje</p>
      </div>
      <div className="mx-3 mt-3 grid grid-cols-2 gap-2">
        <div className="rounded-xl bg-white p-2.5 shadow-sm">
          <p className="font-titulo text-lg font-semibold tabular-nums text-tomate">218</p>
          <p className="text-[9.5px] text-texto">clientes para chamar hoje</p>
        </div>
        <div className="rounded-xl bg-white p-2.5 shadow-sm">
          <p className="font-titulo text-lg font-semibold tabular-nums text-manjericao">R$ 97</p>
          <p className="text-[9.5px] text-texto">valor médio de cada pedido</p>
        </div>
      </div>
      <div className="mt-3 flex-1 space-y-2 overflow-hidden px-3">
        {CARTOES.map((c) => (
          <div key={c.titulo} className="rounded-xl bg-white p-3 shadow-sm">
            <p className="text-[12px] font-semibold">{c.titulo}</p>
            <p className="mt-1 text-[10px] text-texto">
              {c.vip && <span className="mr-1 rounded bg-brasa/25 px-1 font-semibold text-tomate-escuro">VIP</span>}
              {c.exemplo}
            </p>
            <div className="mt-2 inline-flex items-center gap-1 rounded-full bg-[#13803F] px-2.5 py-1 text-[10px] font-medium text-white">
              Abrir WhatsApp com a mensagem
            </div>
          </div>
        ))}
      </div>
      <div className="mt-2 grid grid-cols-4 border-t border-farinha bg-white px-2 py-2 text-center text-[9px] text-texto">
        <span>Pedidos</span>
        <span>Caixa</span>
        <span>Clientes</span>
        <span className="font-semibold text-tomate">Oportunidades</span>
      </div>
    </div>
  );
}

/** Celular de hoje (9:19,5), com moldura, ilha e reflexo. Tamanho em unidades do contêiner: igual em qualquer largura. */
export const Celular = ({ children, className = "" }: { children: React.ReactNode; className?: string }) => (
  <div className={`relative [container-type:inline-size] ${className}`}>
    <div aria-hidden className="pointer-events-none absolute -inset-[16%] -z-10 rounded-full bg-[radial-gradient(closest-side,rgba(229,162,58,.35),rgba(194,54,28,.18)_55%,transparent_78%)] blur-3xl" />
    <div className="rounded-[15cqw] bg-gradient-to-br from-[#5b4a42] via-[#2a1d17] to-[#6b574c] p-[0.9cqw] shadow-[0_28px_50px_-20px_rgba(42,29,23,.45)]">
      <div className="rounded-[14cqw] bg-[#0D0A09] p-[3cqw]">
        <div className="relative aspect-[9/19.5] overflow-hidden rounded-[11.5cqw] bg-white">
          {children}
          <div aria-hidden className="absolute left-1/2 top-[1.2%] z-10 h-[3.2%] w-[30%] -translate-x-1/2 rounded-full bg-black" />
          <div aria-hidden className="pointer-events-none absolute inset-0 z-10 bg-[linear-gradient(118deg,rgba(255,255,255,.18)_0%,rgba(255,255,255,0)_35%)]" />
        </div>
      </div>
    </div>
  </div>
);

/** A mensagem que sai pronta (modelo G2 do PRD, seção 10.7, com os dados da demo). */
export const BalaoWhatsApp = () => (
  <div aria-hidden className="pz-flutuar w-[236px] rounded-2xl bg-[#E7FFDB] p-3.5 text-[12.5px] leading-snug text-[#1d2a20] shadow-[0_24px_50px_-24px_rgba(42,29,23,.5)] ring-1 ring-black/5">
    <p className="mb-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-manjericao">Pronta para enviar</p>
    Oi, Sofia! Faz um tempinho que você não pede com a gente. Vimos que <strong>Portuguesa</strong> está entre as suas favoritas. Que tal hoje? 🍕
    <p className="mt-1 text-right text-[10px] text-[#5c6b60]">18:02 ✓✓</p>
  </div>
);
