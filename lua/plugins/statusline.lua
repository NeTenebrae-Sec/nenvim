-- =========================================================
-- Statusline propia (reemplaza lualine — tarea 012 Fase 2)
-- Secciones equivalentes al setup previo: modo (píldora con
-- color por modo), raíz del proyecto, rama git, diff, archivo,
-- java/vite/lsp, diagnósticos, filetype, progreso y posición.
-- =========================================================

local api = vim.api

local M = {}

-- =========================================================
-- Highlight groups (paridad con la paleta dark_cyan previa)
-- =========================================================
local function setup_hl()
  local set = api.nvim_set_hl
  -- Píldora de modo
  set(0, "NlModeNormal", { fg = "#05080a", bg = "#4ba3db", bold = true })
  set(0, "NlModeInsert", { fg = "#05080a", bg = "#5d7e9e", bold = true })
  set(0, "NlModeVisual", { fg = "#05080a", bg = "#9b51e0", bold = true })
  set(0, "NlModeReplace", { fg = "#05080a", bg = "#2a5980", bold = true })
  set(0, "NlModeCommand", { fg = "#05080a", bg = "#e1f0fa", bold = true })
  -- Sección b (proyecto/rama/diff) teñida por modo
  set(0, "NlProject", { fg = "#4ba3db", bg = "#172129" })
  set(0, "NlProjectInsert", { fg = "#5d7e9e", bg = "#172129" })
  set(0, "NlProjectVisual", { fg = "#9b51e0", bg = "#172129" })
  -- Sección c (archivo) y x (extras)
  set(0, "NlFile", { fg = "#d0dce5", bg = "#10171c" })
  set(0, "NlJava", { fg = "#ff9e64", bg = "#10171c", bold = true })
  set(0, "NlVite", { fg = "#e0af68", bg = "#10171c", bold = true })
  set(0, "NlLsp", { fg = "#7aa2f7", bg = "#10171c", bold = true })
  -- Diagnósticos
  set(0, "NlDiagError", { fg = "#e62e4d", bg = "#10171c", bold = true })
  set(0, "NlDiagWarn", { fg = "#d99b43", bg = "#10171c", bold = true })
  set(0, "NlDiagInfo", { fg = "#a0cded", bg = "#10171c" })
  set(0, "NlDiagHint", { fg = "#5d7e9e", bg = "#10171c" })
  -- Diff
  set(0, "NlDiffAdd", { fg = "#4fa36a", bg = "#172129", bold = true })
  set(0, "NlDiffChange", { fg = "#d99b43", bg = "#172129", bold = true })
  set(0, "NlDiffDel", { fg = "#e62e4d", bg = "#172129", bold = true })
  -- Progreso / posición
  set(0, "NlProgress", { fg = "#92a7b5", bg = "#172129" })
  set(0, "NlLocation", { fg = "#05080a", bg = "#4ba3db", bold = true })
end
setup_hl()

-- =========================================================
-- Helpers
-- =========================================================
local function esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

local MODE_HL = {
  n = "NlModeNormal",
  i = "NlModeInsert",
  v = "NlModeVisual",
  V = "NlModeVisual",
  ["\22"] = "NlModeVisual",
  R = "NlModeReplace",
  c = "NlModeCommand",
}
local MODE_TXT = {
  n = "NORMAL",
  i = "INSERT",
  v = "V-CHAR",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  R = "REPLACE",
  c = "COMMAND",
  t = "TERMINAL",
}
local MODE_PROJ = {
  n = "NlProject",
  i = "NlProjectInsert",
  v = "NlProjectVisual",
  V = "NlProjectVisual",
  ["\22"] = "NlProjectVisual",
}

-- =========================================================
-- Raíz del proyecto (misma lógica que el setup previo)
-- =========================================================
local function project_root()
  local current_file = api.nvim_buf_get_name(0)
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
-- Rama git (async, cacheada por raíz)
-- =========================================================
local branch_cache = {}
local branch_pending = {}

local function refresh_branch(root)
  if branch_pending[root] or branch_cache[root] ~= nil then
    return
  end
  branch_pending[root] = true
  local ok = pcall(vim.system, { "git", "-C", root, "rev-parse", "--abbrev-ref", "HEAD" }, { text = true }, function(out)
    branch_pending[root] = nil
    local b = ""
    if out and out.code == 0 then
      b = (out.stdout or ""):gsub("%s+$", "")
    end
    branch_cache[root] = b
    vim.schedule(function()
      api.nvim_exec_autocmds("User", { pattern = "NvimStatuslineRefresh", modeline = false })
    end)
  end)
  if not ok then
    branch_pending[root] = nil
    branch_cache[root] = ""
  end
end

local function branch_str(root)
  refresh_branch(root)
  return branch_cache[root] or ""
end

-- =========================================================
-- Componentes
-- =========================================================
local function diff_str(buf)
  local ok_gs, gitsigns = pcall(require, "plugins.gitsigns")
  if not ok_gs then
    return ""
  end
  local stats = gitsigns.stats(buf)
  if not stats then
    return ""
  end
  local out = ""
  if stats.add > 0 then
    out = out .. "%#NlDiffAdd#+" .. stats.add .. " "
  end
  if stats.change > 0 then
    out = out .. "%#NlDiffChange#~" .. stats.change .. " "
  end
  if stats.del > 0 then
    out = out .. "%#NlDiffDel#-" .. stats.del .. " "
  end
  return out
end

local function filename_str(buf)
  local name = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
  if name == "" then
    name = "[No Name]"
  end
  local flags = ""
  if vim.bo[buf].modified then
    flags = flags .. " ●"
  end
  if vim.bo[buf].readonly then
    flags = flags .. " "
  end
  return "%#NlFile#  " .. esc(name) .. flags .. "  "
end

local function active_lsp_servers()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if next(clients) == nil then
    return ""
  end
  local seen, names = {}, {}
  for _, client in ipairs(clients) do
    if not seen[client.name] then
      seen[client.name] = true
      table.insert(names, client.name)
    end
  end
  return "%#NlLsp#󰒋 " .. esc(table.concat(names, ", ")) .. "  "
end

local function java_version()
  if vim.bo.filetype ~= "java" then
    return ""
  end
  local root = project_root()

  local java_ver_path = root .. "/.java-version"
  if vim.fn.filereadable(java_ver_path) == 1 then
    local lines = vim.fn.readfile(java_ver_path)
    if #lines > 0 then
      local ver = lines[1]:match("(%d+)")
      if ver then
        return "%#NlJava# Java " .. ver .. "  "
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
      return "%#NlJava# Java " .. ver .. "  "
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
      return "%#NlJava# Java " .. ver .. "  "
    end
  end

  local ok_java, java_mod = pcall(require, "languages.java.core")
  if ok_java and java_mod.current_java_bin then
    local ver = java_mod.current_java_bin:match("java%-(%d+)") or java_mod.current_java_bin:match("jdk%-(%d+)")
    if ver then
      return "%#NlJava# Java " .. ver .. "  "
    end
  end

  local clients = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })
  if #clients > 0 then
    local runtimes = vim.tbl_get(clients[1].config, "settings", "java", "configuration", "runtimes")
    if type(runtimes) == "table" then
      for _, rt in ipairs(runtimes) do
        if rt.default and rt.name then
          local ver = rt.name:match("JavaSE%-(%d+)") or rt.name:match("(%d+)")
          if ver then
            return "%#NlJava# Java " .. ver .. "  "
          end
        end
      end
    end
  end

  return "%#NlJava# Java  "
end

local function vite_status()
  local server = _G.vite_active_servers and _G.vite_active_servers[project_root()]
  if server and server.port then
    return "%#NlVite#󰒋 VITE:" .. server.port .. "  "
  end
  return ""
end

local function diagnostics_str(buf)
  local sev = vim.diagnostic.severity
  local counts = { error = 0, warn = 0, info = 0, hint = 0 }
  local ok, c = pcall(vim.diagnostic.count, buf)
  if ok and type(c) == "table" then
    counts.error = c[sev.ERROR] or 0
    counts.warn = c[sev.WARN] or 0
    counts.info = c[sev.INFO] or 0
    counts.hint = c[sev.HINT] or 0
  end
  local out = ""
  if counts.error > 0 then
    out = out .. "%#NlDiagError# " .. counts.error .. " "
  end
  if counts.warn > 0 then
    out = out .. "%#NlDiagWarn# " .. counts.warn .. " "
  end
  if counts.info > 0 then
    out = out .. "%#NlDiagInfo# " .. counts.info .. " "
  end
  if counts.hint > 0 then
    out = out .. "%#NlDiagHint# " .. counts.hint .. " "
  end
  return out
end

-- =========================================================
-- Render
-- =========================================================
function M.render()
  local buf = api.nvim_get_current_buf()
  local m = vim.api.nvim_get_mode().mode:sub(1, 1)
  local root = project_root()
  local proj_hl = MODE_PROJ[m] or "NlProject"

  local parts = {
    "%#" .. (MODE_HL[m] or "NlModeNormal") .. "# " .. (MODE_TXT[m] or m:upper()) .. " ",
    "%#" .. proj_hl .. "#  " .. esc(vim.fn.fnamemodify(root, ":t")) .. " ",
  }

  local branch = branch_str(root)
  if branch ~= "" then
    parts[#parts + 1] = "%#" .. proj_hl .. "#  " .. esc(branch) .. " "
  end
  parts[#parts + 1] = diff_str(buf)
  parts[#parts + 1] = "%#" .. proj_hl .. "# "

  parts[#parts + 1] = filename_str(buf)
  parts[#parts + 1] = java_version()
  parts[#parts + 1] = vite_status()
  parts[#parts + 1] = active_lsp_servers()
  parts[#parts + 1] = diagnostics_str(buf)
  if vim.bo.filetype ~= "" then
    parts[#parts + 1] = "%#NlFile#" .. esc(vim.bo.filetype) .. "  "
  end

  parts[#parts + 1] = "%#NlProgress# %P "
  parts[#parts + 1] = "%#NlLocation# " .. api.nvim_win_get_cursor(0)[1] .. ":" .. api.nvim_win_get_cursor(0)[2] .. " "

  return table.concat(parts) .. "%#StatusLine#"
end

-- =========================================================
-- Setup
-- =========================================================
vim.o.statusline = "%!v:lua.require'plugins.statusline'.render()"

local group = api.nvim_create_augroup("NvimStatusline", { clear = true })
for _, ev in ipairs({ "LspAttach", "LspDetach", "BufEnter", "DiagnosticChanged", "FileType" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function()
      vim.o.statusline = vim.o.statusline -- refresh del formato
      vim.cmd("redrawstatus!")
    end,
  })
end
api.nvim_create_autocmd("User", {
  group = group,
  pattern = { "NvimStatuslineRefresh", "NvimGitSignsUpdate" },
  callback = function()
    vim.cmd("redrawstatus!")
  end,
})

return M
