-- =========================================================
-- :Jsconfig — genera jsconfig.json en la raíz del proyecto
-- =========================================================

local default_jsconfig = {
  compilerOptions = {
    moduleResolution = "node",
    target = "ES2022",
    checkJs = true,
  },
  include = {
    "**/*.js",
    "**/*.jsx",
    "**/*.ts",
    "**/*.tsx",
  },
}

vim.api.nvim_create_user_command("Jsconfig", function()
  local root = vim.fs.root(0, { "package.json", ".git" }) or vim.fn.getcwd()
  local jsconfig_path = root .. "/jsconfig.json"
  local tsconfig_path = root .. "/tsconfig.json"

  if vim.fn.filereadable(jsconfig_path) == 1 or vim.fn.filereadable(tsconfig_path) == 1 then
    vim.notify("Ya existe un archivo de configuración JS/TS en la raíz.", vim.log.levels.WARN, { title = "Jsconfig" })
    return
  end

  local formatted_json = vim.fn.json_encode(default_jsconfig)

  local file = io.open(jsconfig_path, "w")
  if file then
    file:write(formatted_json)
    file:close()
    vim.notify("jsconfig.json creado en: " .. root, vim.log.levels.INFO, { title = "Jsconfig" })

    -- Disparar el evento FileType del buffer actual para refrescar sin tocar nada de LSP
    vim.bo.filetype = vim.bo.filetype
  else
    vim.notify("Error al intentar crear jsconfig.json", vim.log.levels.ERROR, { title = "Jsconfig" })
  end
end, {
  desc = "Genera un archivo jsconfig.json básico en la raíz del proyecto",
})
