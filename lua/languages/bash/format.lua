-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/shell.lua
-- PROPÓSITO: Configuración de shfmt para Shell, Bash y Zsh (4 espacios)
-- ============================================================================

local defaults = {
  indent = "4",
}

local M = {}

--- Devuelve las banderas CLI para shfmt
---@param _? string|number Parámetro opcional por consistencia de interfaz
function M.get_cli_args(_)
  return { "-i", defaults.indent }
end

-- Plantilla para :FormatInit (Genera regla de .editorconfig)
M.init_config = {
  filename = ".editorconfig",
  content = string.format("[*.sh]\nindent_style = space\nindent_size = %s\n", defaults.indent),
}

M.formatters_by_ft = {
  sh = { "shfmt" },
  bash = { "shfmt" },
  zsh = { "shfmt" },
}

M.formatters = {
  shfmt = {
    prepend_args = M.get_cli_args(),
  },
}

return M
