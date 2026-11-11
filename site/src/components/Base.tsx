import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { EMPRESA, MARCA, TEXTO_DO_CTA, destinoDoCta, linkWhatsApp } from "@/config/marca";
import { type Origem, lerOrigem } from "@/config/origem";

export const Seta = () => (
  <svg aria-hidden viewBox="0 0 16 16" className="h-4 w-4 transition-transform duration-300 group-hover:translate-x-1">
    <path d="M2 8h11M9 4l4 4-4 4" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

/** O botão principal. Vai para a lista de espera no pré-lançamento e para o cadastro do sistema depois (config/marca.ts). */
export function CtaPrincipal({ children = TEXTO_DO_CTA, className = "", claro = false, plano }: { children?: React.ReactNode; className?: string; claro?: boolean; plano?: string }) {
  // A origem (UTM, indicação) só existe no navegador: no HTML pré-renderizado o link sai sem ela e o
  // React completa ao carregar a página.
  const [origem, setOrigem] = useState<Origem>({});
  useEffect(() => setOrigem(lerOrigem()), []);
  const { href, externo } = destinoDoCta(plano, origem);
  const estilo = `group inline-flex h-12 items-center justify-center gap-2 rounded-full px-7 text-base font-medium transition-[transform,box-shadow] duration-300 hover:-translate-y-px ${
    claro ? "bg-white text-tomate-escuro" : "bg-tomate text-white shadow-[0_10px_30px_-12px_rgba(194,54,28,.6)]"
  } ${className}`;
  return externo ? (
    <a href={href} className={estilo}>
      {children}
      <Seta />
    </a>
  ) : (
    <Link to={href} className={estilo}>
      {children}
      <Seta />
    </Link>
  );
}

/** Marca em texto: a fatia no lugar do pingo do "i" fica para quando houver logo de verdade. */
export const Logo = ({ claro = false }: { claro?: boolean }) => (
  <Link to="/" className="flex items-center gap-2" aria-label={`${MARCA.nome}, página inicial`}>
    <img src="/favicon.svg" alt="" width={28} height={28} className="h-7 w-7" />
    <span className={`font-titulo text-[1.35rem] font-semibold tracking-[-0.03em] ${claro ? "text-white" : "text-carvao"}`}>{MARCA.nome}</span>
  </Link>
);

export function Cabecalho({ simples = false }: { simples?: boolean }) {
  return (
    <header className="sticky top-0 z-50 border-b border-carvao/10 bg-white/95 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-5">
        <Logo />
        <nav className="flex items-center gap-2 sm:gap-6">
          {!simples && (
            <div className="hidden items-center gap-6 text-sm md:flex">
              <a href="/#funcoes" className="hover:text-tomate-escuro">O que faz</a>
              <a href="/#como-funciona" className="hover:text-tomate-escuro">Como funciona</a>
              <a href="/#planos" className="hover:text-tomate-escuro">Planos</a>
              <a href="/#perguntas" className="hover:text-tomate-escuro">Perguntas</a>
              <Link to="/guias" className="hover:text-tomate-escuro">Guias</Link>
            </div>
          )}
          <CtaPrincipal className="!h-9 !px-4 !text-sm" />
        </nav>
      </div>
    </header>
  );
}

export function Rodape() {
  const ano = new Date().getFullYear();
  return (
    <footer className="bg-carvao text-[#E9DDD3]">
      <div className="mx-auto grid max-w-6xl gap-10 px-5 py-14 md:grid-cols-[1.3fr_1fr_1fr]">
        <div>
          <Logo claro />
          <p className="mt-4 max-w-sm text-sm leading-relaxed">{MARCA.descricaoCurta}</p>
          <p className="mt-2 text-xs text-[#BFAFA3]">{MARCA.nome}, {MARCA.assinatura}</p>
        </div>
        <div className="text-sm">
          <p className="font-medium text-white">Fale com a gente</p>
          <a href={linkWhatsApp()} target="_blank" rel="noopener noreferrer" className="mt-3 block underline-offset-4 hover:underline">
            WhatsApp {EMPRESA.whatsappVisivel}
          </a>
          <a href={`mailto:${EMPRESA.email}`} className="mt-1 block underline-offset-4 hover:underline">{EMPRESA.email}</a>
          <p className="mt-1 text-[#BFAFA3]">Atendimento {EMPRESA.horarioAtendimento}</p>
        </div>
        <div className="text-sm">
          <p className="font-medium text-white">Transparência</p>
          <Link to="/termos" className="mt-3 block underline-offset-4 hover:underline">Termos de Uso</Link>
          <Link to="/privacidade" className="mt-1 block underline-offset-4 hover:underline">Política de Privacidade</Link>
          <Link to="/guias" className="mt-1 block underline-offset-4 hover:underline">Guias para donos de pizzaria</Link>
        </div>
      </div>
      <div className="border-t border-white/10">
        <p className="mx-auto max-w-6xl px-5 py-5 text-xs text-[#BFAFA3]">
          © {ano} {MARCA.nome}
          {EMPRESA.razaoSocial ? ` · ${EMPRESA.razaoSocial}` : ""}
          {EMPRESA.cnpj ? ` · CNPJ ${EMPRESA.cnpj}` : ""} · {EMPRESA.cidade}
        </p>
      </div>
    </footer>
  );
}

/** Título de seção. A ideia do título vai em <Ideia>, uma vez só: se tudo é destaque, nada é. */
export const Titulo = ({ children, className = "", claro = false }: { children: React.ReactNode; className?: string; claro?: boolean }) => (
  <h2 className={`font-semibold leading-[1.05] tracking-[-0.035em] ${claro ? "!text-white" : ""} ${className}`}>{children}</h2>
);
export const Ideia = ({ children, className = "text-tomate" }: { children: React.ReactNode; className?: string }) => (
  <em className={`not-italic ${className}`}>{children}</em>
);
/** Sobretítulo com fio de brasa: o "carimbo" de cada seção. */
export const Sobretitulo = ({ children, className = "text-tomate-escuro" }: { children: React.ReactNode; className?: string }) => (
  <p className={`mb-5 flex items-center gap-3 text-[11px] font-semibold uppercase tracking-[0.24em] ${className}`}>
    <span aria-hidden className="h-px w-8 bg-brasa" />
    {children}
  </p>
);

/**
 * Espaço reservado para foto, vídeo ou depoimento que ainda vai chegar. Só aparece com "?espacos" no endereço:
 * o visitante nunca vê quadrado vazio. Tem a proporção da mídia final.
 */
export const EspacoMidia = ({ tipo, proporcao, descricao }: { tipo: string; proporcao: string; descricao: string }) => (
  <div
    className="flex flex-col items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-brasa bg-creme p-5 text-center"
    style={{ aspectRatio: proporcao.replace(":", " / ") }}
  >
    <span className="text-[11px] font-semibold uppercase tracking-[0.18em] text-tomate-escuro">{tipo} · {proporcao}</span>
    <span className="text-sm leading-snug">{descricao}</span>
  </div>
);
