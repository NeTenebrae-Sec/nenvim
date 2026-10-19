-- =========================================================
-- Ficha Astro — astro-ls + eslint del proyecto + prettier (web)
-- =========================================================
-- Datos puros (schema 002). Auxiliares internos: scaffold (:AstroInit)
-- y runner (<leader>dr: dev/preview/check/build en Kitty).
-- prettier para .astro lo aporta el módulo format de node-ts.

local M = {
  name = "astro",
  filetypes = { "astro" },

  lsp = {
    {
      name = "astro",
      config = {
        cmd = { "astro-ls", "--stdio" },
        filetypes = { "astro" },
        root_markers = { "astro.config.mjs", "astro.config.ts", "package.json", ".git" },
        init_options = {
          typescript = {
            -- typescript-language-server solo se lista por el tsdk que astro-ls lee
            tsdk = vim.fn.stdpath("data")
              .. "/tools/packages/typescript-language-server/node_modules/typescript/lib",
          },
        },
      },
    },
  },

  -- eslint local del proyecto (node_modules/.bin); requiere
  -- eslint-plugin-astro en el eslint.config del proyecto para .astro
  lint = { astro = { "eslint" } },

  parsers = { "astro" },

  tools = { "astro-language-server", "typescript-language-server" },

  dap = require("languages.astro.dap"),
}

-- Side effect: comando :AstroInit (online create-astro / local fallback)
pcall(require, "languages.astro.scaffold")

return M
