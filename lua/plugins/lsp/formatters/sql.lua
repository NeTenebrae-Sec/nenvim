-- ============================================================================
-- MÓDULO: lua/plugins/lsp/formatters/sql.lua
-- PROPÓSITO: Configuración de sqlfluff como formateador SQL en conform.nvim.
--   Sigue el patrón de formatters/lua.lua y formatters/markdown.lua.
--
-- NOTAS:
--   - sqlfluff también es un linter, pero aquí se usa SOLO como formatter
--   - El linting básico lo provee el sql-language-server (sqlint) integrado
--   - sqlfluff 4.x requiere --dialect DESPUÉS del subcommand "fix"
--     (no como --prepend_args), por eso usamos args en vez de prepend_args
--   - sqlfluff devuelve exit code 1 cuando hay violaciones no fixables,
--     aunque el formateo SÍ se aplica al stdout. Por eso aceptamos codes {0, 1}.
--   - Si existe .sqlfluff local, se respeta la configuración del proyecto
--   - require_cwd = false permite usarlo sin config local
-- ============================================================================

local defaults = {
  -- Dialecto default: PostgreSQL (motor principal).
  -- Proyectos MySQL/MariaDB definen su propio .sqlfluff con dialect = mysql
  dialect = "postgres",
}

local sqlfluff_configs = {
  ".sqlfluff",
  ".sqlfluff.toml",
  ".sqlfluff.ini",
  "pyproject.toml",
  "tox.ini",
  "setup.cfg",
}

local M = {}

--- Revisa si existe configuración local de sqlfluff
--- @param target string|number Ruta de directorio o buffer
function M.has_config(target)
  local path = type(target) == "number" and vim.api.nvim_buf_get_name(target) or target
  if not path or path == "" then
    path = vim.fn.getcwd()
  end
  return vim.fs.root(path, sqlfluff_configs) ~= nil
end

--- Genera las banderas CLI para sqlfluff (van DESPUÉS de "fix")
--- @param target string|number Ruta de directorio o buffer
function M.get_cli_args(target)
  if M.has_config(target) then
    return {}
  end
  return { "--dialect", defaults.dialect, "--disable-progress-bar" }
end

-- Plantilla para :FormatInit (crea .sqlfluff con config básica)
M.init_config = {
  filename = ".sqlfluff",
  content = string.format("[sqlfluff]\ndialect = %s\n", defaults.dialect),
}

M.formatters_by_ft = {
  sql = { "sqlfluff" },
}

M.formatters = {
  sqlfluff = {
    -- sqlfluff requiere --dialect DESPUÉS de "fix", no antes.
    -- Usamos args (no prepend_args) para controlar el orden completo.
    -- Conform.nvim built-in has require_cwd=true, lo que exige .sqlfluff
    -- local. Con require_cwd=false funciona en cualquier directorio.
    stdin = true,
    args = function(_, ctx)
      local extra = M.get_cli_args(ctx.buf)
      local args = { "fix" }
      vim.list_extend(args, extra)
      table.insert(args, "-")
      return args
    end,
    require_cwd = false,
    -- sqlfluff (Python) tarda ~1.2s en iniciar; el timeout default es 1s.
    timeout = 15000,
    -- sqlfluff devuelve exit code 1 cuando hay violaciones no fixables,
    -- pero el formateo SIGUE se aplica al stdout.
    exit_codes = { 0, 1 },
  },
}

return M
