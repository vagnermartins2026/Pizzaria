import { Link, useLocation } from "react-router-dom";
import { usePagina } from "@/config/paginas";
import { Cabecalho } from "@/components/Base";

export default function NaoEncontrada() {
  usePagina(useLocation().pathname);
  return (
    <main className="min-h-dvh">
      <Cabecalho simples />
      <div className="mx-auto max-w-xl px-5 py-24 text-center">
        <h1 className="text-4xl font-semibold">Essa página saiu do forno antes da hora.</h1>
        <Link to="/" className="mt-8 inline-block font-medium text-tomate-escuro underline underline-offset-4">Voltar ao início</Link>
      </div>
    </main>
  );
}
