import type { Config } from "tailwindcss";
const config: Config = { content: ["./app/**/*.{js,ts,jsx,tsx,mdx}", "./components/**/*.{js,ts,jsx,tsx,mdx}"], theme: { extend: { colors: { navy: "#102A43", leaf: "#16845B", mist: "#F4F7F8" }, boxShadow: { soft: "0 8px 30px rgba(16,42,67,.06)" } } }, plugins: [] };
export default config;
