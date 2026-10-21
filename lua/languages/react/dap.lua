-- =========================================================
-- React > runner (<leader>dr): proyecto vite/react → menú; si no, node
-- =========================================================
-- El DAP de navegador (pwa-chrome) sigue opcional (GLOBAL §4 R2):
-- pwa-node lo registra node-ts; aquí no se registra nada.

local M = {}

M.filetypes = { "javascriptreact", "typescriptreact" }
M.priority = 10

local function project_root()
  return vim.fs.root(0, { "vite.config.ts", "vite.config.js", "vite.config.mjs", "package.json", ".git" })
end

local function has_dep(root, dep)
  local fd = io.open(root .. "/package.json", "r")
  if not fd then
    return false
  end
  local content = fd:read("*a") or ""
  fd:close()
  return content:find('"' .. dep .. '"', 1, true) ~= nil
end

--- Confirma un proyecto react (vite o dep react) para priorizar este runner
function M.detect()
  local root = project_root()
  if not root then
    return false
  end
  return vim.fn.glob(root .. "/vite.config.*") ~= "" or has_dep(root, "react")
end

local actions = {
  { label = "1. Dev server (vite)", cmd = "npm run dev" },
  { label = "2. Build (vite)", cmd = "npm run build" },
  { label = "3. Preview", cmd = "npm run preview" },
}

--- Runner: menú del proyecto o node directo (paridad node-ts)
function M.run()
  if M.detect() then
    local root = project_root()
    vim.ui.select(actions, {
      prompt = "React: select execution action:",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end
      local cmd = string.format("cd '%s' && %s; echo ''; read -p 'Presiona Enter para cerrar...'", root, choice.cmd)
      vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
    end)
    return
  end

  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Abre un archivo JSX/TSX válido.", vim.log.levels.WARN)
    return
  end
  local cmd = string.format("node %s; echo ''; read -p 'Presiona Enter para cerrar...'", vim.fn.shellescape(file))
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

function M.setup() end

return M
