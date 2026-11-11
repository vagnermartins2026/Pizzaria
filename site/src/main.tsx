import { StrictMode } from "react";
import { createRoot, hydrateRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

const raiz = document.getElementById("root")!;
const app = (
  <StrictMode>
    <App />
  </StrictMode>
);
// Página pré-renderizada no build (scripts/prerender.mjs): aproveita o HTML. Em `npm run dev`, desenha do zero.
if (raiz.hasChildNodes()) hydrateRoot(raiz, app);
else createRoot(raiz).render(app);
