-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/init.lua
-- PROPÓSITO: Carga dinámica para Conform.nvim e inicialización de comandos.
-- COMPATIBILIDAD: Neovim 0.10+ / 0.12
-- ============================================================================

-- 1. CARGA SEGURA DE CONFORM
local ok_conform, conform = pcall(require, "conform")
if not ok_conform then
  return
end

-- 2. LISTA DE SUBMÓDULOS
local modules = {
  "plugins.lsp.formatters.javascript",
  "plugins.lsp.formatters.markdown",
  "plugins.lsp.formatters.lua",
  "plugins.lsp.formatters.shell",
  "plugins.lsp.formatters.generic",
}

-- 3. FUSIÓN DINÁMICA DE CONFIGURACIONES PARA CONFORM
local combined_formatters_by_ft = {}
local combined_formatters = {}

for _, mod_path in ipairs(modules) do
  local ok, mod = pcall(require, mod_path)
  if ok and type(mod) == "table" then
    if mod.formatters_by_ft then
      combined_formatters_by_ft = vim.tbl_deep_extend("force", combined_formatters_by_ft, mod.formatters_by_ft)
    end

    if mod.formatters then
      combined_formatters = vim.tbl_deep_extend("force", combined_formatters, mod.formatters)
    end
  end
end

-- 4. INICIALIZACIÓN DE CONFORM.NVIM
conform.setup({
  formatters_by_ft = combined_formatters_by_ft,
  formatters = combined_formatters,
  format_on_save = {
    timeout_ms = 2000,
    lsp_format = "fallback",
  },
})

-- 5. REGISTRO DE COMANDOS DE USUARIO (:FormatProject y :FormatInit)
local ok_commands, commands = pcall(require, "plugins.lsp.formatters.commands")
if ok_commands then
  commands.setup()
end
