local lint = require("lint")

-- 1. Ruta del archivo fallback en el directorio temporal/state de Neovim
local tmp_config = vim.fn.stdpath("state") .. "/stylelintrc_fallback.json"

-- 2. Creamos el fallback con reglas nativas si no existe
if vim.fn.filereadable(tmp_config) == 0 then
  local f = io.open(tmp_config, "w")
  if f then
    f:write([[
{
  "rules": {
    "property-no-unknown": true,
    "declaration-block-no-duplicate-properties": true,
    "unit-no-unknown": true,
    "color-no-invalid-hex": true
  }
}
]])
    f:close()
  end
end

-- Asignar Stylelint a archivos CSS y SCSS
lint.linters_by_ft.css = { "stylelint" }
lint.linters_by_ft.scss = { "stylelint" }

-- 3. Lista de nombres de archivos de configuración comunes de Stylelint
local stylelint_configs = {
  ".stylelintrc",
  ".stylelintrc.json",
  ".stylelintrc.yaml",
  ".stylelintrc.yml",
  ".stylelintrc.js",
  ".stylelintrc.cjs",
  ".stylelintrc.mjs",
  "stylelint.config.js",
  "stylelint.config.cjs",
  "stylelint.config.mjs",
}

-- 4. Configuramos los argumentos de Stylelint de forma dinámica
lint.linters.stylelint.args = {
  "--formatter",
  "json",
  "--stdin",
  "--stdin-filename",
  function()
    return vim.api.nvim_buf_get_name(0)
  end,
  function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local buf_dir = vim.fs.dirname(buf_name)

    -- Busca si existe algún archivo de configuración en el proyecto o carpetas superiores
    if buf_dir and buf_dir ~= "" then
      local project_config = vim.fs.find(stylelint_configs, {
        upward = true,
        path = buf_dir,
      })[1]

      if project_config then
        return "--config=" .. project_config
      end
    end

    -- Si no encontró ninguna config en el proyecto, usamos la de fallback
    return "--config=" .. tmp_config
  end,
}
