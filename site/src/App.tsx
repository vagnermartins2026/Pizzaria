import { useEffect } from "react";
import { BrowserRouter, Route, Routes, useLocation } from "react-router-dom";
import Inicio from "./pages/Inicio";
import Fundadores from "./pages/Fundadores";
import { Privacidade, Termos } from "./pages/Legais";
import NaoEncontrada from "./pages/NaoEncontrada";

/** Ao trocar de página, volta ao topo (menos quando o endereço aponta para uma seção, ex.: /#planos). */
function RolarParaTopo() {
  const { pathname, hash } = useLocation();
  useEffect(() => {
    if (!hash) window.scrollTo(0, 0);
  }, [pathname, hash]);
  return null;
}

export default function App() {
  return (
    <BrowserRouter>
      <RolarParaTopo />
      <Routes>
        <Route path="/" element={<Inicio />} />
        <Route path="/fundadores" element={<Fundadores />} />
        <Route path="/termos" element={<Termos />} />
        <Route path="/privacidade" element={<Privacidade />} />
        <Route path="*" element={<NaoEncontrada />} />
      </Routes>
    </BrowserRouter>
  );
}
