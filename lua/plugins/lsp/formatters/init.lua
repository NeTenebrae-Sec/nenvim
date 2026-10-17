-- =========================================================
-- Formato (delgado): motor core/format + datos temporales
-- =========================================================
-- Los datos (ft→formatters) siguen en los submódulos de esta carpeta
-- hasta F2 de la spec 002; el motor los absorbe vía register().

local ok_format, format = pcall(require, "core.format")
if not ok_format or not format then
  return
end

-- Lista de submódulos de datos
local modules = {
  "plugins.lsp.formatters.javascript",
  "plugins.lsp.formatters.markdown",
  "plugins.lsp.formatters.lua",
  "plugins.lsp.formatters.shell",
  "plugins.lsp.formatters.sql",
  "plugins.lsp.formatters.generic",
}

for _, mod_path in ipairs(modules) do
  local ok, mod = pcall(require, mod_path)
  if ok and type(mod) == "table" then
    format.register(mod)
  end
end

format.setup()

-- Registro de comandos de usuario (:FormatProject y :FormatInit)
local ok_commands, commands = pcall(require, "plugins.lsp.formatters.commands")
if ok_commands then
  commands.setup()
end
