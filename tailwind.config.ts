import type { Config } from "tailwindcss"

const config = {
  darkMode: ["class"],
  content: [
    "./src/**/*.{ts,tsx}",
    "./index.html",
  ],
  prefix: "",
  theme: {
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
        // Apple-inspired palette
        "apple-gray": {
          100: "rgba(242, 242, 247, 0.8)",
          200: "rgba(229, 229, 234, 0.8)",
          300: "rgba(209, 209, 214, 0.8)",
          400: "rgba(199, 199, 204, 0.8)",
          500: "rgba(174, 174, 178, 0.8)",
          600: "rgba(142, 142, 147, 0.8)",
          700: "rgba(99, 99, 102, 0.8)",
          800: "rgba(72, 72, 74, 0.8)",
          900: "rgba(58, 58, 60, 0.8)",
        },
        "apple-blue": "rgba(0, 122, 255, 0.9)",
        "apple-blue-light": "rgba(10, 132, 255, 0.9)",
        "apple-green": "rgba(52, 199, 89, 0.9)",
        "apple-green-dark": "rgba(41, 163, 72, 0.9)", // Darker green
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
        xl: "calc(var(--radius) + 4px)",
        "2xl": "calc(var(--radius) + 10px)",
        "3xl": "calc(var(--radius) + 18px)",
      },
      boxShadow: {
        "apple-sm": "0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 1px 0 rgba(0,0,0,0.02)",
        "apple-md": "0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -2px rgba(0, 0, 0, 0.04)",
        "apple-lg": "0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -4px rgba(0, 0, 0, 0.04)",
        "apple-xl": "0 20px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.04)",
        "apple-inner": "inset 0 1px 1px 0 rgba(255,255,255,0.1), inset 0 -1px 1px 0 rgba(0,0,0,0.05)",
        "apple-lifted": "0px 5px 15px rgba(0, 0, 0, 0.1), 0px 2px 5px rgba(0, 0, 0, 0.05)",
      },
      backdropBlur: {
        xs: "2px",
        sm: "4px",
        md: "8px",
        lg: "16px",
        xl: "24px",
        "2xl": "40px",
        "3xl": "64px",
      },
      keyframes: {
        "expand-in": {
          "0%": { opacity: "0", transform: "scale(0.97)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
        "slide-up-fade": {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "subtle-pulse": {
          "0%, 100%": { transform: "scale(1)", opacity: "0.8" },
          "50%": { transform: "scale(1.1)", opacity: "1" },
        },
        "slide-in-from-right": {
          "0%": { transform: "translateX(100%)", opacity: "0" },
          "100%": { transform: "translateX(0%)", opacity: "1" },
        },
        "slide-out-to-right": {
          "0%": { transform: "translateX(0%)", opacity: "1" },
          "100%": { transform: "translateX(100%)", opacity: "0" },
        },
      },
      animation: {
        "expand-in": "expand-in 0.3s cubic-bezier(0.25, 1, 0.5, 1)",
        "slide-up-fade": "slide-up-fade 0.3s cubic-bezier(0.25, 1, 0.5, 1)",
        "subtle-pulse": "subtle-pulse 1.5s ease-in-out infinite",
        "slide-in-from-right": "slide-in-from-right 0.35s cubic-bezier(0.25, 1, 0.5, 1)",
        "slide-out-to-right": "slide-out-to-right 0.35s cubic-bezier(0.25, 1, 0.5, 1) forwards",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
} satisfies Config

export default config
