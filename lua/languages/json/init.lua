-- =========================================================
-- Ficha JSON/TOML — jsonls + taplo
-- =========================================================
-- prettier para .json lo aporta el módulo format de node-ts.
-- yaml no tiene ficha propia: su parser está en la base del motor.

local M = {
  name = "json",
  filetypes = { "json", "jsonc", "toml" },

  lsp = {
    {
      name = "jsonls",
      config = {
        cmd = { "vscode-json-language-server", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { ".git", "package.json" },
      },
    },
  },

  format = { toml = { "taplo" } },

  parsers = { "json", "toml" },

  tools = { "json-lsp", "taplo" },
}

return M
