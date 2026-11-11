import { useState } from "react";
import { PLANOS, reais } from "@/config/planos";

/**
 * "A conta do mês": duas contas que o dono faz com os próprios números (plano de negócio, seção 6).
 * Os valores iniciais são de EXEMPLO (o valor médio de R$ 97 é o da pizzaria demo). A comissão do marketplace
 * é a do contrato DELE: o site não afirma a taxa de nenhuma empresa.
 */
function Campo({ rotulo, valor, onChange, min, max, passo = 1, sufixo }: {
  rotulo: string; valor: number; onChange: (v: number) => void; min: number; max: number; passo?: number; sufixo: string;
}) {
  const id = rotulo.replace(/\W+/g, "-").toLowerCase();
  return (
    <div>
      <div className="flex items-baseline justify-between gap-4">
        <label htmlFor={id} className="text-sm">{rotulo}</label>
        <span className="font-titulo text-lg font-semibold tabular-nums text-carvao">{sufixo === "R$" ? reais(valor * 100) : `${valor}${sufixo}`}</span>
      </div>
      <input id={id} type="range" min={min} max={max} step={passo} value={valor} onChange={(e) => onChange(Number(e.target.value))}
        className="mt-2 w-full accent-tomate" />
    </div>
  );
}

export function Calculadora() {
  const [ticket, setTicket] = useState(97);
  const [recuperados, setRecuperados] = useState(8);
  const [pedidosMarketplace, setPedidosMarketplace] = useState(300);
  const [comissao, setComissao] = useState(20);
  const [migracao, setMigracao] = useState(20);

  const vendaRecuperada = recuperados * ticket;
  const comissaoEvitada = Math.round(pedidosMarketplace * (migracao / 100) * ticket * (comissao / 100));
  const total = vendaRecuperada + comissaoEvitada;
  const plano = PLANOS.find((p) => p.destaque)!;

  return (
    <div className="rounded-3xl bg-white p-6 shadow-[0_0_0_1px_#F0E2CF,0_30px_70px_-40px_rgba(194,54,28,.45)] sm:p-8">
      <Campo rotulo="Valor médio de um pedido" valor={ticket} onChange={setTicket} min={40} max={200} sufixo="R$" />
      <div className="mt-7 border-t border-farinha pt-6">
        <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-tomate-escuro">1 · Cliente que volta</p>
        <div className="mt-4">
          <Campo rotulo="Pedidos recuperados por mês com o CRM" valor={recuperados} onChange={setRecuperados} min={0} max={60} sufixo="" />
        </div>
      </div>
      <div className="mt-7 border-t border-farinha pt-6">
        <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-tomate-escuro">2 · Pedido que sai do marketplace</p>
        <div className="mt-4 space-y-5">
          <Campo rotulo="Pedidos por mês no marketplace" valor={pedidosMarketplace} onChange={setPedidosMarketplace} min={0} max={1500} passo={10} sufixo="" />
          <Campo rotulo="Comissão do seu contrato" valor={comissao} onChange={setComissao} min={0} max={35} sufixo="%" />
          <Campo rotulo="Quantos passam a pedir no seu link" valor={migracao} onChange={setMigracao} min={0} max={100} passo={5} sufixo="%" />
        </div>
      </div>
      <dl className="mt-8 space-y-2 rounded-2xl bg-creme p-5 tabular-nums">
        <div className="flex justify-between gap-3 text-sm"><dt>Venda de quem voltou</dt><dd>{reais(vendaRecuperada * 100)}</dd></div>
        <div className="flex justify-between gap-3 text-sm"><dt>Comissão que deixa de pagar</dt><dd>{reais(comissaoEvitada * 100)}</dd></div>
        <div className="flex items-baseline justify-between gap-3 border-t border-farinha pt-3">
          <dt className="font-medium text-carvao">A mais por mês<span className="block text-xs font-normal text-texto">venda que voltou + comissão economizada</span></dt>
          <dd className="font-titulo text-2xl font-semibold text-manjericao">{reais(total * 100)}</dd>
        </div>
      </dl>
      <p className="mt-4 text-xs leading-relaxed">
        Conta de exemplo: troque pelos seus números. Para comparar, o plano {plano.nome} está previsto em {reais(plano.centavos)} por mês.
      </p>
    </div>
  );
}
