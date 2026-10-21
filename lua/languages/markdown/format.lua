-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/markdown.lua
-- PROPÓSITO: Configuración de mdformat a 80 columnas con fallback dinámico.
-- ============================================================================

local defaults = {
  wrap = "80",
}

local M = {}

--- Devuelve los argumentos CLI para mdformat
---@param _? string|number Parámetro opcional por consistencia de interfaz
function M.get_cli_args(_)
  return { "--wrap", defaults.wrap }
end

-- Plantilla opcional para :FormatInit
M.init_config = {
  filename = ".mdformat.toml",
  content = string.format("wrap = %s\n", defaults.wrap),
}

M.formatters_by_ft = {
  markdown = { "mdformat" },
  ["markdown.mdx"] = { "mdformat" },
}

M.formatters = {
  mdformat = {
    prepend_args = M.get_cli_args(),
  },
}

return M
