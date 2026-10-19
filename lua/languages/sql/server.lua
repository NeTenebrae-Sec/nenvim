-- ============================================================================
-- MÓDULO: lua/plugins/lsp/servers/sql.lua
-- PROPÓSITO: Soporte SQL multi-motor (PostgreSQL, MySQL/MariaDB, MongoDB).
--   Gestión explícita de ciclo de vida con vim.lsp.start() + autocmds.
--
-- PostgreSQL  → postgres-language-server (autocompletado de tablas/columnas)
-- MySQL       → sqlls / sql-language-server
-- MongoDB     → treesitter highlighting + mongosh CLI
-- ============================================================================

local DIALECT_FT = { postgres = "sql", mysql = "mysql", mariadb = "mysql", mongosh = "mongosh" }

local project_dialect = {}

--- Capabilities de cmp-nvim-lsp para completado LSP en CMP
local function get_capabilities()
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    caps = cmp_nvim_lsp.default_capabilities(caps)
  end
  return caps
end

--- Ruta absoluta al binario del tools engine propio
local function tools_bin(name)
  local p = vim.fn.stdpath("data") .. "/tools/bin/" .. name
  return vim.uv.fs_stat(p) and p or name
end

--- Resuelve el root del proyecto para un buffer
---@param bufnr integer
---@return string
local function get_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local start_path = (name ~= "" and name) or vim.fn.getcwd()
  return vim.fs.root(start_path, {
    ".git",
    "postgres-language-server.jsonc",
    ".sqllsrc.json",
    ".mongoshrc.js",
  }) or vim.fn.getcwd()
end

--- ¿El cliente name ya está adjunto a este buffer?
local function client_attached(bufnr, name)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.name == name then return true end
  end
  return false
end

--- Desadjunta un cliente LSP de este buffer por nombre
---@param bufnr integer
---@param name string
local function detach_client(bufnr, name)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = name })) do
    vim.lsp.buf_detach_client(bufnr, c.id)
  end
end

--- Aplica el dialecto a todos los buffers .sql abiertos en un root dado
---@param root string
---@param target_ft string
---@return integer count Cantidad de buffers modificados
local function apply_dialect(root, target_ft)
  local count = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) then
      local bufname = vim.api.nvim_buf_get_name(b)
      local buf_root = vim.fs.root(bufname, { ".git" }) or vim.fn.getcwd()
      if buf_root == root and bufname:match("%.sql$") then
        vim.bo[b].filetype = target_ft
        count = count + 1
      end
    end
  end
  return count
end

--- Arranca el LSP adecuado para el buffer actual
---@param bufnr integer
local function start_for_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  local ft = vim.bo[bufnr].filetype
  if ft ~= "sql" and ft ~= "mysql" then return end

  local root = get_root(bufnr)
  local caps = get_capabilities()

  if ft == "sql" then
    -- PostgreSQL: detach sqlls si estuviera, arrancar postgres_lsp
    detach_client(bufnr, "sqlls")
    if not client_attached(bufnr, "postgres_lsp") then
      vim.lsp.start({
        name = "postgres_lsp",
        cmd = { tools_bin("postgres-language-server"), "lsp-proxy" },
        root_dir = root,
        capabilities = caps,
        buffer = bufnr,
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
    end

  elseif ft == "mysql" then
    -- MySQL/MariaDB: detach postgres_lsp si estuviera, arrancar sqlls
    detach_client(bufnr, "postgres_lsp")
    if not client_attached(bufnr, "sqlls") then
      vim.lsp.start({
        name = "sqlls",
        cmd = { tools_bin("sql-language-server"), "up", "--method", "stdio" },
        root_dir = root,
        capabilities = caps,
        buffer = bufnr,
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
    end
  end
end

-- ============================================================================
-- AUTOCMD: Aplicar dialecto guardado al abrir archivos .sql
-- ============================================================================
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("SqlDialectPerProject", { clear = true }),
  pattern = "*.sql",
  callback = function(args)
    local root = get_root(args.buf)
    local dialect = project_dialect[root]
    if dialect and DIALECT_FT[dialect] and DIALECT_FT[dialect] ~= "sql" then
      vim.bo[args.buf].filetype = DIALECT_FT[dialect]
    end
  end,
})

-- ============================================================================
-- AUTOCMD: Arrancar LSP cuando el filetype es sql o mysql
-- ============================================================================
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SqlLspAttach", { clear = true }),
  pattern = { "sql", "mysql" },
  callback = function(args)
    start_for_buffer(args.buf)
  end,
})

-- ============================================================================
-- AUTOCMD: Arrancar LSP en buffers .sql ya abiertos al iniciar Neovim
-- ============================================================================
vim.defer_fn(function()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) then
      local ft = vim.bo[b].filetype
      if ft == "sql" or ft == "mysql" then
        start_for_buffer(b)
      end
    end
  end
end, 3000)

-- ============================================================================
-- COMMAND: :SqlDialect {postgres|mysql|mariadb}
-- ============================================================================
vim.api.nvim_create_user_command("SqlDialect", function(opts)
  local dialect = opts.args
  local target_ft = DIALECT_FT[dialect]
  if not target_ft then
    vim.notify("Dialecto invalido: '" .. dialect .. "'. Usa: postgres | mysql | mariadb", vim.log.levels.ERROR)
    return
  end

  local root = get_root(vim.api.nvim_get_current_buf())
  project_dialect[root] = dialect
  local changed = apply_dialect(root, target_ft)

  local engine
  if dialect == "postgres" then
    engine = "PostgreSQL (postgres_lsp)"
  elseif dialect == "mysql" or dialect == "mariadb" then
    engine = "MySQL/MariaDB (sqlls)"
  else
    engine = dialect
  end
  vim.notify(("SQL dialecto -> %s [%d buffer(s)]"):format(engine, changed), vim.log.levels.INFO)
end, {
  nargs = 1,
  desc = "Cambia el dialecto SQL del proyecto: postgres|mysql|mariadb",
  complete = function() return { "postgres", "mysql", "mariadb" } end,
})

-- ============================================================================
-- COMMAND: :SqlInit [database] [usuario]
-- Genera postgres-language-server.jsonc con credenciales de conexion.
-- ============================================================================
local PG_CONFIG_TEMPLATE = [[{
  "$schema": "https://pg-language-server.com/latest/schema.json",
  "linter": {
    "enabled": false
  },
  "db": {
    "host": "127.0.0.1",
    "port": 5432,
    "username": "%s",
    "password": "%s",
    "database": "%s",
    "connTimeoutSecs": 10,
    "disableConnection": false
  }
}
]]

vim.api.nvim_create_user_command("SqlInit", function(opts)
  local parts = vim.split(vim.trim(opts.args), "%s+", { trimempty = true })
  local database = parts[1] or "postgres"
  local username = parts[2] or "postgres"
  local password = "<ver ~/.pgpass>"

  local root = get_root(vim.api.nvim_get_current_buf())
  local target_path = root .. "/postgres-language-server.jsonc"

  if vim.uv.fs_stat(target_path) then
    vim.notify("Ya existe postgres-language-server.jsonc en: " .. root, vim.log.levels.WARN)
    return
  end

  local file, err = io.open(target_path, "w")
  if not file then
    vim.notify("No se pudo crear el archivo: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  file:write(PG_CONFIG_TEMPLATE:format(username, password, database))
  file:close()

  -- Agregar a .gitignore
  local gitignore_path = root .. "/.gitignore"
  local gitignore = io.open(gitignore_path, "a+")
  if gitignore then
    local found = false
    for line in gitignore:lines() do
      if line == "postgres-language-server.jsonc" then
        found = true
        break
      end
    end
    if not found then
      gitignore:write("postgres-language-server.jsonc\n")
      gitignore:flush()
    end
    gitignore:close()
  end

  vim.notify(
    "Creado postgres-language-server.jsonc en " .. root
      .. "\n1) Edita la contrasena (ver ~/.pgpass)"
      .. "\n2) Reabre el archivo SQL (:e) para recargar el LSP",
    vim.log.levels.INFO
  )
end, {
  nargs = "?",
  desc = "Genera postgres-language-server.jsonc [:SqlInit database usuario]",
})

-- ============================================================================
-- COMMAND: :MongoInit
-- Genera template de conexion MongoDB.
-- ============================================================================
vim.api.nvim_create_user_command("MongoInit", function()
  local root = get_root(vim.api.nvim_get_current_buf())
  local target_path = root .. "/.mongoshrc.js"

  if vim.uv.fs_stat(target_path) then
    vim.notify("Ya existe .mongoshrc.js en: " .. root, vim.log.levels.WARN)
    return
  end

  local template = [[-- MongoDB connection config for mongosh
-- Editar segun tu entorno local

const config = {
  host: "localhost",
  port: 27017,
  // database: "mi_base_datos",
  // user: "usuario",
  // password: "contrasena",
};

// connect(config.host, config.port);
]]

  local file, err = io.open(target_path, "w")
  if not file then
    vim.notify("No se pudo crear el archivo: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  file:write(template)
  file:close()

  vim.notify(
    "Creado .mongoshrc.js en " .. root
      .. "\nEdita el archivo con tus credenciales MongoDB",
    vim.log.levels.INFO
  )
end, {
  desc = "Genera template .mongoshrc.js para conexion MongoDB",
})

-- ============================================================================
-- CONFIGURACION ESTATICA para :checkhealth
-- ============================================================================
vim.lsp.config("postgres_lsp", {
  cmd = { tools_bin("postgres-language-server"), "lsp-proxy" },
  filetypes = { "sql" },
  root_markers = { "postgres-language-server.jsonc", ".git" },
})

vim.lsp.config("sqlls", {
  cmd = { tools_bin("sql-language-server"), "up", "--method", "stdio" },
  filetypes = { "mysql" },
  root_markers = { ".sqllsrc.json", ".git" },
})

-- ============================================================================
-- TREESITTER: Registrar parser "sql" para mysql y mongosh
-- ============================================================================
pcall(function()
  vim.treesitter.language.register("sql", "mysql")
  vim.treesitter.language.register("sql", "mongosh")
end)

-- ============================================================================
-- FILETYPE: Asociar extensiones comunes de MongoDB
-- ============================================================================
vim.filetype.add({
  extension = {
    mongosh = "mongosh",
    mongojs = "mongosh",
  },
  filename = {
    [".mongoshrc.js"] = "mongosh",
  },
})
