-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/lua.lua
-- PROPÓSITO: Configuración de StyLua con fallback dinámico e inicializador.
-- ============================================================================

-- 1. CONFIGURACIÓN POR DEFECTO
local defaults = {
  indent_type = "Spaces", -- "Spaces" o "Tabs"
  indent_width = 2,
}

local stylua_configs = {
  ".stylua.toml",
  "stylua.toml",
}

local M = {}

--- Revisa si existe configuración local de StyLua
---@param target string|number Ruta de directorio o buffer
function M.has_config(target)
  local path = type(target) == "number" and vim.api.nvim_buf_get_name(target) or target
  if not path or path == "" then
    path = vim.fn.getcwd()
  end
  return vim.fs.root(path, stylua_configs) ~= nil
end

--- Genera las banderas CLI según corresponda
---@param target string|number Ruta de directorio o buffer
function M.get_cli_args(target)
  if M.has_config(target) then
    return {}
  end

  return {
    "--indent-type",
    defaults.indent_type,
    "--indent-width",
    tostring(defaults.indent_width),
  }
end

-- 2. PLANTILLA PARA :FormatInit (En formato TOML para StyLua)
M.init_config = {
  filename = ".stylua.toml",
  content = string.format('indent_type = "%s"\nindent_width = %d\n', defaults.indent_type, defaults.indent_width),
}

-- 3. INTEGRACIÓN CON CONFORM.NVIM
M.formatters_by_ft = {
  lua = { "stylua" },
}

M.formatters = {
  stylua = {
    prepend_args = function(_, ctx)
      return M.get_cli_args(ctx.buf)
    end,
  },
}

return M
