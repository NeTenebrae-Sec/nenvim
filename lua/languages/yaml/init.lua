-- =========================================================
-- Ficha YAML — yaml-lsp + prettier (web module)
-- =========================================================
-- parser "yaml" en la base del motor treesitter; prettier para .yaml
-- lo aporta el módulo format de node-ts.

local M = {
  name = "yaml",
  filetypes = { "yaml" },

  lsp = {
    {
      name = "yamlls",
      config = {
        cmd = { "yaml-language-server", "--stdio" },
        filetypes = { "yaml" },
        root_markers = { ".git", "package.json" },
      },
    },
  },

  tools = { "yaml-language-server" },
}

return M
