-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/javascript.lua
-- ============================================================================

local defaults = {
  tabWidth = 4,
  useTabs = true,
  semi = true,
  singleQuote = true,
  trailingComma = "all",
  printWidth = 80,
}

local prettier_configs = {
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.yml",
  ".prettierrc.yaml",
  ".prettierrc.json5",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
}

-- Mapeamos el módulo local
local M = {}

--- Revisa si existe configuración local de Prettier
---@param target string|number Ruta de directorio o buffer
function M.has_config(target)
  local path = type(target) == "number" and vim.api.nvim_buf_get_name(target) or target
  if not path or path == "" then
    path = vim.fn.getcwd()
  end
  return vim.fs.root(path, prettier_configs) ~= nil
end

--- Genera las banderas de CLI basadas en si existe o no config local
---@param target string|number Ruta de directorio o buffer
function M.get_cli_args(target)
  if M.has_config(target) then
    return {}
  end

  return {
    "--no-editorconfig",
    "--tab-width",
    tostring(defaults.tabWidth),
    "--use-tabs",
    tostring(defaults.useTabs),
    "--semi",
    tostring(defaults.semi),
    "--single-quote",
    tostring(defaults.singleQuote),
    "--trailing-comma",
    defaults.trailingComma,
  }
end

M.init_config = {
  filename = ".prettierrc",
  content = vim.json.encode(defaults),
}

M.formatters_by_ft = {
  javascript = { "injected", "prettier" },
  typescript = { "injected", "prettier" },
  javascriptreact = { "injected", "prettier" },
  typescriptreact = { "injected", "prettier" },
  vue = { "prettier" },
  svelte = { "prettier" },
  astro = { "prettier" },
  html = { "prettier" },
  css = { "prettier" },
  scss = { "prettier" },
  json = { "prettier" },
  yaml = { "prettier" },
}

M.formatters = {
  prettier = {
    prefer_local = "node_modules/.bin",
    require_cwd = false,
    prepend_args = function(_, ctx)
      return M.get_cli_args(ctx.buf)
    end,
  },
}

return M
