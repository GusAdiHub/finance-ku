import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-poppins)", "Poppins", "sans-serif"],
      },
      colors: {
        neo: {
          bg: "#FFFDF9",
          canvas: "#FAF8F5",
          yellow: "#FFE600",
          yellowLight: "#FEF08A",
          blue: "#3B82F6",
          blueLight: "#BAE6FD",
          green: "#4ADE80",
          greenLight: "#BBF7D0",
          pink: "#F472B6",
          pinkLight: "#FBCFE8",
          purple: "#C084FC",
          orange: "#FB923C",
          red: "#F87171",
          black: "#000000",
          card: "#FFFFFF",
        },
        brand: {
          50: "#EFF6FF",
          100: "#DBEAFE",
          200: "#BFDBFE",
          500: "#3B82F6",
          600: "#2563EB",
          700: "#1D4ED8",
          800: "#1E40AF",
          900: "#1E3A8A",
        },
      },
      borderRadius: {
        "xl": "12px",
        "2xl": "16px",
        "3xl": "20px",
      },
      boxShadow: {
        "neo-sm": "2px 2px 0px 0px #000000",
        "neo": "4px 4px 0px 0px #000000",
        "neo-lg": "6px 6px 0px 0px #000000",
        "neo-xl": "8px 8px 0px 0px #000000",
        "soft": "4px 4px 0px 0px #000000",
      },
      borderWidth: {
        "3": "3px",
      },
    },
  },
  plugins: [],
};

export default config;
