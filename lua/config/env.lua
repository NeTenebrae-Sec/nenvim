-- =========================================================
-- env.lua
-- Carga automática de archivos .env en vim.env
-- Detecta .env tradicional y archivos *.env no ocultos
-- =========================================================

local M = {}

--- Parsea un archivo .env y retorna una tabla {KEY = VALUE}
---@param filepath string Ruta al archivo .env
---@return table<string, string>
function M.parse(filepath)
  local vars = {}
  local ok, lines = pcall(vim.fn.readfile, filepath)
  if not ok then
    return vars
  end

  for _, line in ipairs(lines) do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")

    if line ~= "" and not line:match("^#") and not line:match("^;") then
      local key, value = line:match("^([%w_]+)%s*=%s*(.+)$")
      if key and value then
        value = value:gsub("%s+$", "")

        if value:match('^".*"$') then
          value = value:match('^"(.*)"$')
        elseif value:match("^'.*'$") then
          value = value:match("^'(.*)'$")
        end

        value = value:gsub("#.*$", ""):gsub("%s+$", "")

        if value ~= "" then
          vars[key] = value
        end
      end
    end
  end

  return vars
end

--- Carga archivos .env del directorio de trabajo actual en vim.env
--- Detecta .env tradicional y archivos *.env no ocultos (secrets.env, database.env, etc.)
---@return number Número de variables cargadas
function M.load()
  local cwd = vim.fn.getcwd()
  local files = {}

  -- Buscar .env tradicional
  local tradional_env = cwd .. "/.env"
  if vim.fn.filereadable(tradional_env) == 1 then
    table.insert(files, tradional_env)
  end

  -- Buscar archivos *.env no ocultos (que no empiecen con .)
  local pattern = cwd .. "/[^.]*.env"
  local matches = vim.fn.glob(pattern, false, true)
  for _, f in ipairs(matches) do
    -- Evitar duplicar .env si ya está en la lista
    if f ~= tradional_env and vim.fn.filereadable(f) == 1 then
      table.insert(files, f)
    end
  end

  -- Ordenar para carga consistente
  table.sort(files)

  -- Cargar todos los archivos encontrados
  local count = 0
  for _, filepath in ipairs(files) do
    local vars = M.parse(filepath)
    for key, value in pairs(vars) do
      vim.env[key] = value
      count = count + 1
    end
  end

  return count
end

--- Ejecuta la carga con notificación
function M.reload()
  local count = M.load()
  if count > 0 then
    vim.notify("Loaded " .. count .. " env variables", vim.log.levels.INFO, { title = "EnvFile" })
  else
    vim.notify("No .env files found in " .. vim.fn.getcwd(), vim.log.levels.WARN, { title = "EnvFile" })
  end
end

vim.api.nvim_create_user_command("EnvFile", M.reload, {
  desc = "Recargar archivos .env del directorio actual",
})

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
  desc = "Cargar .env automáticamente",
  callback = function()
    M.load()
  end,
})

return M
