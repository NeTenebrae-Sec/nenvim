local M = {}

local function get_bash_args()
  local input = vim.fn.input("Arguments (Enter = none): ", "", "file")
  vim.cmd("redraw")
  input = vim.trim(input)
  return input == "" and {} or vim.split(input, "%s+")
end

--- Lógica de ejecución directa para Bash
function M.run()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Abre un archivo de script válido.", vim.log.levels.WARN)
    return
  end

  local cmd = string.format("bash %s; echo ''; read -p 'Presiona Enter para cerrar...'", vim.fn.shellescape(file))
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

function M.setup(dap, mason_path)
  local bashdb_dir = mason_path .. "/packages/bash-debug-adapter/extension/bashdb_dir"
  local bashdb_path = bashdb_dir .. "/bashdb"

  dap.adapters.bash = {
    type = "executable",
    command = mason_path .. "/packages/bash-debug-adapter/bash-debug-adapter",
    name = "bashdb",
  }

  dap.configurations.sh = {
    {
      type = "bash",
      request = "launch",
      name = "Launch bash script",
      program = function()
        return vim.fn.expand("%:p")
      end,
      file = "${file}",
      cwd = "${workspaceFolder}",
      pathBashdb = bashdb_path,
      pathBashdbLib = bashdb_dir,
      pathBash = vim.fn.exepath("bash") ~= "" and vim.fn.exepath("bash") or "/bin/bash",
      pathCat = vim.fn.exepath("cat") ~= "" and vim.fn.exepath("cat") or "cat",
      pathMkfifo = vim.fn.exepath("mkfifo") ~= "" and vim.fn.exepath("mkfifo") or "mkfifo",
      pathPkill = vim.fn.exepath("pkill") ~= "" and vim.fn.exepath("pkill") or "pkill",
      pathGrep = vim.fn.exepath("grep") ~= "" and vim.fn.exepath("grep") or "grep",
      pathSleep = vim.fn.exepath("sleep") ~= "" and vim.fn.exepath("sleep") or "sleep",
      terminalKind = "external",
      env = {},
      args = get_bash_args,
      argsString = "",
      showDebugOutput = false,
      trace = false,
    },
  }

  dap.configurations.bash = dap.configurations.sh
end

return M
