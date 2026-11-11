/** Paleta "forno a lenha": a mesma de src/config/paleta.ts (fonte única dos valores). */
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        tomate: "#C2361C", // a cor da marca: botões e a ideia de cada título (5,5:1 com texto branco)
        "tomate-escuro": "#962713", // sobretítulos e links (8,1:1 sobre branco)
        brasa: "#E5A23A", // só decoração: fio, numeral (nunca texto que precisa ser lido)
        "brasa-clara": "#F6D9A6", // destaque sobre o carvão
        carvao: "#2A1D17", // títulos e as faixas escuras
        texto: "#5A4A42", // corpo de texto (8,6:1)
        creme: "#FFF8EF", // fundo das seções alternadas
        farinha: "#F0E2CF", // fios e bordas
        manjericao: "#2C7448", // o dinheiro que volta (5,6:1)
      },
      fontFamily: {
        titulo: ['"Bricolage Grotesque"', "system-ui", "sans-serif"],
        corpo: ['"Inter"', "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
