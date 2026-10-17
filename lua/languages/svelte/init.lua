-- =========================================================
-- Ficha Svelte
-- =========================================================
-- prettier para .svelte lo aporta el módulo format de node-ts.
-- Idiomas embebidos (ts/js/css) los gestiona otter (plugins/otter).

local M = {
  name = "svelte",
  filetypes = { "svelte" },

  lsp = {
    {
      name = "svelte",
      config = {
        cmd = { "svelteserver", "--stdio" },
        filetypes = { "svelte" },
        root_markers = { "svelte.config.js", "svelte.config.ts", "package.json", ".git" },
      },
    },
  },

  parsers = { "svelte" },

  tools = { "svelte-language-server" },
}

return M
