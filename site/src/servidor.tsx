/**
 * Entrada do pré-renderizador (só no build). Desenha cada rota em HTML com o StaticRouter.
 * O navegador depois "hidrata" esse HTML (src/main.tsx). Ver scripts/prerender.mjs.
 */
import { StrictMode } from "react";
import { renderToString } from "react-dom/server";
import { StaticRouter } from "react-router-dom/server";
import { Rotas } from "./App";
export { PAGINAS, metaDe, urlAbsoluta } from "./config/paginas";

export function desenhar(caminho: string): string {
  return renderToString(
    <StrictMode>
      <StaticRouter location={caminho}>
        <Rotas />
      </StaticRouter>
    </StrictMode>,
  );
}
