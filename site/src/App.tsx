import { useEffect } from "react";
import { BrowserRouter, Route, Routes, useLocation } from "react-router-dom";
import Inicio from "./pages/Inicio";
import Fundadores from "./pages/Fundadores";
import { Privacidade, Termos } from "./pages/Legais";
import NaoEncontrada from "./pages/NaoEncontrada";
import { Guia, Guias } from "./pages/Guias";
import { guardarOrigemDaUrl } from "./config/origem";

/** Ao trocar de página, volta ao topo (menos quando o endereço aponta para uma seção, ex.: /#planos). */
function RolarParaTopo() {
  const { pathname, hash } = useLocation();
  useEffect(() => {
    if (!hash) window.scrollTo(0, 0);
  }, [pathname, hash]);
  // Anúncio ou indicação (?utm_source=…, ?indicacao=…): guarda para repassar ao cadastro (config/origem.ts).
  useEffect(() => guardarOrigemDaUrl(), []);
  return null;
}

/** As rotas, sem o roteador: o navegador usa com BrowserRouter e o build com StaticRouter (src/servidor.tsx). */
export function Rotas() {
  return (
    <>
      <RolarParaTopo />
      <Routes>
        <Route path="/" element={<Inicio />} />
        <Route path="/fundadores" element={<Fundadores />} />
        <Route path="/guias" element={<Guias />} />
        <Route path="/guias/:slug" element={<Guia />} />
        <Route path="/termos" element={<Termos />} />
        <Route path="/privacidade" element={<Privacidade />} />
        <Route path="*" element={<NaoEncontrada />} />
      </Routes>
    </>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Rotas />
    </BrowserRouter>
  );
}
