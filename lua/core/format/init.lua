-- =========================================================
-- Motor Formato (conform): machinery + registro por fichas
-- =========================================================
-- Los datos llegan de las fichas de languages/ (schema 002):
-- `format` = tabla simple ft→formatters; `format_modules` = rutas a
-- módulos completos (args dinámicos por proyecto, init_config).

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
  -- Registro desde fichas de lenguaje (schema 002)
  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    for _, ficha in ipairs(languages.all()) do
      if ficha.format then
        M.register({ formatters_by_ft = ficha.format })
      end
      for _, mod_path in ipairs(ficha.format_modules or {}) do
        local ok_mod, mod = pcall(require, mod_path)
        if ok_mod and type(mod) == "table" then
          M.register(mod)
        end
      end
    end
  end

  conform.setup({
    formatters_by_ft = combined_by_ft,
    formatters = combined_defs,
    format_on_save = {
      timeout_ms = 5000,
      lsp_format = "fallback",
    },
  })

  -- Comandos de usuario (:FormatProject y :FormatInit)
  local ok_commands, commands = pcall(require, "core.format.commands")
  if ok_commands and commands then
    commands.setup()
  end
end

-- El motor se activa al cargarse: en la lista de módulos va DESPUÉS
-- de core.lsp (el scanner de fichas queda cacheado y disponible)
M.setup()

return M
