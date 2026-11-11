import { Cabecalho, Rodape } from "@/components/Base";
import { EMPRESA, MARCA } from "@/config/marca";
import { usePagina } from "@/config/paginas";

/**
 * RASCUNHOS de Termos de Uso e Política de Privacidade para a fase de pré-lançamento.
 * Precisam de revisão jurídica e da razão social/CNPJ (config/marca.ts → EMPRESA) antes de o sistema abrir o
 * cadastro e a cobrança. Base: o que o PRD decidiu (seções 11.7 e 12.4) e o modelo da Minha Maleta.
 */
function Documento({ titulo, caminho, children }: { titulo: string; caminho: string; children: React.ReactNode }) {
  usePagina(caminho);
  const quem = EMPRESA.razaoSocial ? `${EMPRESA.razaoSocial}${EMPRESA.cnpj ? `, CNPJ ${EMPRESA.cnpj}` : ""}` : `a empresa responsável pela ${MARCA.nome} (dados a publicar)`;
  return (
    <main className="min-h-dvh">
      <Cabecalho simples />
      <article className="mx-auto max-w-3xl px-5 py-14 md:py-20">
        <p className="mb-6 rounded-xl bg-brasa/20 px-4 py-3 text-sm text-carvao">Rascunho em revisão. Versão de pré-lançamento.</p>
        <h1 className="text-4xl font-semibold tracking-[-0.03em]">{titulo}</h1>
        <p className="mt-3 text-sm">Responsável: {quem} · {EMPRESA.cidade} · {EMPRESA.email}</p>
        <div className="mt-10 space-y-6 text-[16px] leading-relaxed [&_h2]:mt-10 [&_h2]:text-xl [&_h2]:font-semibold">{children}</div>
      </article>
      <Rodape />
    </main>
  );
}

export function Termos() {
  return (
    <Documento titulo="Termos de Uso" caminho="/termos">
      <p>Estes termos valem para o site {MARCA.dominio}. Os termos completos do sistema (assinatura, cobrança, cancelamento e suporte) serão publicados antes da abertura do cadastro.</p>
      <h2>1. O que é a {MARCA.nome}</h2>
      <p>Um sistema de gestão para pizzarias, contratado por assinatura mensal ou anual, por loja. O sistema está em construção; as funções e os preços mostrados no site são os previstos e podem mudar até a abertura.</p>
      <h2>2. Lista de espera</h2>
      <p>Entrar na lista de espera não cria contrato, cobrança nem condição especial: só garante o aviso, por ordem de inscrição, quando o sistema abrir.</p>
      <h2>3. Mensagens para os clientes da pizzaria</h2>
      <p>O sistema prepara mensagens, mas quem envia é a pizzaria, pelo próprio WhatsApp. A pizzaria é responsável por só enviar a quem autorizou e por respeitar quem pediu para sair.</p>
      <h2>4. Contato</h2>
      <p>Dúvidas: {EMPRESA.email} ou WhatsApp {EMPRESA.whatsappVisivel}.</p>
    </Documento>
  );
}

export function Privacidade() {
  return (
    <Documento titulo="Política de Privacidade" caminho="/privacidade">
      <h2>1. Neste site</h2>
      <p>O site não tem cadastro nem formulário que grava dados. O formulário da lista de espera só monta uma mensagem que abre no seu WhatsApp; o que você enviar por lá é tratado como uma conversa comercial, para responder ao seu pedido, e não é repassado a terceiros.</p>
      <p>Não usamos cookies de publicidade. Se passarmos a medir visitas, este texto será atualizado antes.</p>
      <h2>2. No sistema (quando abrir)</h2>
      <p>A pizzaria é dona dos dados dos clientes dela; a {MARCA.nome} trata esses dados em nome dela, só para fazer o sistema funcionar. Cada pizzaria enxerga apenas os próprios dados.</p>
      <p>Mensagens promocionais só para quem deu consentimento, registrado com data e origem. O cliente final pode pedir para sair a qualquer momento, e o sistema bloqueia novos contatos.</p>
      <h2>3. Seus direitos</h2>
      <p>Pela LGPD, você pode pedir acesso, correção ou exclusão dos seus dados: {EMPRESA.email}.</p>
    </Documento>
  );
}
