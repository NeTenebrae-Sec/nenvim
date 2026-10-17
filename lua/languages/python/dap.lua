local M = {}

--- Lógica de ejecución directa para Python
function M.run()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Abre un archivo .py válido.", vim.log.levels.WARN)
    return
  end

  local cmd = string.format("python3 %s; echo ''; read -p 'Presiona Enter para cerrar...'", vim.fn.shellescape(file))
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

function M.setup(dap, _)
  dap.adapters.python = {
    type = "executable",
    command = "python3",
    args = { "-m", "debugpy.adapter" },
  }

  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      console = "integratedTerminal",
      pythonPath = function()
        return "python3"
      end,
    },
  }
end

return M
