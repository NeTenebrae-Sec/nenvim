-- =========================================================
-- Next.js > runner (<leader>dr): proyecto next → menú; si no, node
-- =========================================================

local M = {}

M.filetypes = { "javascriptreact", "typescriptreact" }

-- Prioridad del runner: un proyecto next también tiene react (dep
-- next ⊂ react) — next gana por ser más específico
M.priority = 20

local function project_root()
  return vim.fs.root(0, { "next.config.js", "next.config.mjs", "next.config.ts", "package.json", ".git" })
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

--- Confirma un proyecto next (dep next) para priorizar este runner
function M.detect()
  local root = project_root()
  return root ~= nil and has_dep(root, "next")
end

local actions = {
  { label = "1. Dev server (next dev)", cmd = "npm run dev" },
  { label = "2. Build (next build)", cmd = "npm run build" },
  { label = "3. Start (next start)", cmd = "npm run start" },
  { label = "4. Lint (next lint)", cmd = "npm run lint" },
}

--- Runner: menú del proyecto o node directo (paridad node-ts)
function M.run()
  if M.detect() then
    local root = project_root()
    vim.ui.select(actions, {
      prompt = "Next.js: select execution action:",
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
