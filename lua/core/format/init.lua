-- =========================================================
-- Motor Formato (conform): machinery + registro por fichas
-- =========================================================
-- Los datos (ft→formatters) llegan por register(). En F0 los siguen
-- aportando los módulos de plugins/lsp/formatters/ (temporal hasta
-- F2 de la spec 002); en F2 las fichas de languages/ los registran.

local M = {}

local ok_conform, conform = pcall(require, "conform")
if not ok_conform then
  return
end

local combined_by_ft = {}
local combined_defs = {}

-- Registro: accepts { formatters_by_ft = {...}, formatters = {...} }
function M.register(mod)
  if mod.formatters_by_ft then
    combined_by_ft = vim.tbl_deep_extend("force", combined_by_ft, mod.formatters_by_ft)
  end
  if mod.formatters then
    combined_defs = vim.tbl_deep_extend("force", combined_defs, mod.formatters)
  end
end

function M.setup()
  conform.setup({
    formatters_by_ft = combined_by_ft,
    formatters = combined_defs,
    format_on_save = {
      timeout_ms = 5000,
      lsp_format = "fallback",
    },
  })
end

return M
