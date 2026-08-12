local ok, lualine = pcall(require, "lualine")
if not ok then
  return
end

-- =========================================================
-- Helper: Detección inteligente de la raíz del proyecto
-- =========================================================
local function get_intelligent_project_root()
  local current_file = vim.api.nvim_buf_get_name(0)

  if current_file == "" then
    return vim.fn.getcwd()
  end

  local current_dir = vim.fs.dirname(current_file)

  local git_ancestor = vim.fs.find(".git", { path = current_dir, upward = true })[1]
  if git_ancestor then
    return vim.fs.dirname(git_ancestor)
  end

  return current_dir
end

-- =========================================================
-- Componentes Personalizados e Inteligentes
-- =========================================================

-- Componente inteligente: Nombre de la carpeta raíz real del proyecto actual
local function cwd_name()
  local root = get_intelligent_project_root()
  return vim.fn.fnamemodify(root, ":t")
end

local function vite_status()
  local project_root = get_intelligent_project_root()
  local server = _G.vite_active_servers and _G.vite_active_servers[project_root]

  if server and server.port then
    return "VITE:" .. server.port
  end
  return ""
end

-- Detectar servidores LSP activos en el buffer actual sin duplicar nombres
local function active_lsp_servers()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if next(clients) == nil then
    return "No LSP"
  end

  local seen = {}
  local lsp_names = {}

  for _, client in ipairs(clients) do
    if not seen[client.name] then
      seen[client.name] = true
      table.insert(lsp_names, client.name)
    end
  end

  return "󰒋 " .. table.concat(lsp_names, ", ")
end

-- Detectar la versión de Java directamente del PROYECTO
local function java_version()
  if vim.bo.filetype ~= "java" then
    return ""
  end

  local root = get_intelligent_project_root()

  -- 1. Analizar archivos del proyecto (.java-version, pom.xml, build.gradle)
  local java_ver_path = root .. "/.java-version"
  if vim.fn.filereadable(java_ver_path) == 1 then
    local lines = vim.fn.readfile(java_ver_path)
    if #lines > 0 then
      local ver = lines[1]:match("(%d+)")
      if ver then
        return " Java " .. ver
      end
    end
  end

  local pom_path = root .. "/pom.xml"
  if vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    local ver = content:match("<maven%.compiler%.release>%s*(%d+)%s*</maven%.compiler%.release>")
      or content:match("<java%.version>%s*(%d+)%s*</java%.version>")
      or content:match("<maven%.compiler%.source>%s*(%d+)%s*</maven%.compiler%.source>")
    if ver then
      return " Java " .. ver
    end
  end

  local gradle_path = root .. "/build.gradle"
  local gradle_kts_path = root .. "/build.gradle.kts"
  local gpath = vim.fn.filereadable(gradle_path) == 1 and gradle_path
    or (vim.fn.filereadable(gradle_kts_path) == 1 and gradle_kts_path or nil)

  if gpath then
    local content = table.concat(vim.fn.readfile(gpath), "\n")
    local ver = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
      or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
    if ver then
      return " Java " .. ver
    end
  end

  -- 2. Consultar la variable de ejecutable configurada en el plugin de Java
  local ok_java, java_mod = pcall(require, "plugins.lsp.java")
  if ok_java and java_mod.current_java_bin then
    local ver = java_mod.current_java_bin:match("java%-(%d+)") or java_mod.current_java_bin:match("jdk%-(%d+)")
    if ver then
      return " Java " .. ver
    end
  end

  -- 3. Inspeccionar runtimes explícitos dentro de la configuración de JDTLS
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })
  if #clients > 0 then
    local client = clients[1]
    local runtimes = vim.tbl_get(client.config, "settings", "java", "configuration", "runtimes")
    if runtimes and type(runtimes) == "table" then
      for _, rt in ipairs(runtimes) do
        if rt.default and rt.name then
          local ver = rt.name:match("JavaSE%-(%d+)") or rt.name:match("(%d+)")
          if ver then
            return " Java " .. ver
          end
        end
      end
    end
  end

  return " Java"
end

-- =========================================================
-- Configuración de Lualine
-- =========================================================
lualine.setup({
  options = {
    theme = "auto",
    globalstatus = true,
    icons_enabled = true,
    component_separators = { left = "│", right = "│" },
    section_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = {
      {
        "mode",
        separator = { left = "", right = "" },
        padding = { left = 1, right = 1 },
      },
    },
    lualine_b = {
      { cwd_name, icon = "" },
      { "branch", icon = "" },
      { "diff" },
    },
    lualine_c = {
      {
        "filename",
        path = 0,
        symbols = {
          modified = " ●",
          readonly = " ",
          unnamed = "[No Name]",
        },
      },
    },
    lualine_x = {
      {
        java_version,
        color = { fg = "#ff9e64", gui = "bold" },
      },
      {
        vite_status,
        icon = "󰒋",
        color = { fg = "#e0af68", gui = "bold" },
      },
      {
        active_lsp_servers,
        color = { fg = "#7aa2f7", gui = "bold" },
      },
      { "diagnostics" },
      { "filetype" },
    },
    lualine_y = {
      { "progress" },
    },
    lualine_z = {
      {
        "location",
        separator = { left = "", right = "" },
        padding = { left = 1, right = 1 },
      },
    },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
})
