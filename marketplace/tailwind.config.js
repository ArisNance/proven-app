module.exports = {
  content: [
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.{js,jsx}"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["DM Sans", "ui-sans-serif", "system-ui", "sans-serif"],
        header: ["Red Hat Display", "ui-sans-serif", "system-ui", "sans-serif"]
      },
      colors: {
        primary: "#0D0D0D",
        secondary: "#F4F4F0",
        accent: "#D4F93D"
      },
      borderRadius: {
        "4xl": "2rem",
        "5xl": "3rem"
      },
      boxShadow: {
        soft: "0 20px 40px -15px rgba(0, 0, 0, 0.05)",
        "card-float": "0 30px 60px -10px rgba(0, 0, 0, 0.15)"
      }
    }
  },
  plugins: [require("daisyui")],
  daisyui: {
    themes: [
      {
        proven: {
          primary: "#0D0D0D",
          secondary: "#F4F4F0",
          accent: "#d4f93d",
          neutral: "#0D0D0D",
          "base-100": "#FAFAF8",
          "base-200": "#F4F4F0",
          "base-300": "#E8E8E2",
          info: "#0ea5e9",
          success: "#16a34a",
          warning: "#f59e0b",
          error: "#dc2626"
        }
      }
    ]
  }
}
