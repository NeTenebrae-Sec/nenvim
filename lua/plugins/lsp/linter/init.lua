-- =========================================================
-- Lint (delgado): motor core/lint + datos temporales
-- =========================================================
-- Los datos (ft→linters) siguen en los submódulos de esta carpeta
-- hasta F2 de la spec 002; en F2 las fichas de languages/ los
-- registrarán directamente en core.lint.

local ok_lint, lint_engine = pcall(require, "core.lint")
if not ok_lint or not lint_engine then
  return
end

-- Cargar módulos de linters directamente en esta misma carpeta
local linters = {
  "javascript",
  "css",
  "html",
  "markdown",
  "astro",
}

for _, name in ipairs(linters) do
  pcall(require, "plugins.lsp.linter." .. name)
end
