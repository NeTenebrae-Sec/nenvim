-- =========================================================
-- Ficha Vue — Volar
-- =========================================================
-- prettier para .vue lo aporta el módulo format de node-ts.
-- Idiomas embebidos (ts/js/css) los gestiona otter (plugins/otter).

local M = {
  name = "vue",
  filetypes = { "vue" },

  lsp = {
    {
      name = "volar",
      config = {
        cmd = { "vue-language-server", "--stdio" },
        filetypes = { "vue" },
        root_markers = { "vue.config.js", "vue.config.ts", "vite.config.js", "vite.config.ts", "package.json", ".git" },
      },
    },
  },

  parsers = { "vue" },

  tools = { "vue-language-server" },
}

return M
