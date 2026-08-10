local M = {}

--- Lógica de ejecución directa para JavaScript / Node.js en Kitty (<leader>fr)
function M.run()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Abre un archivo JS/TS válido.", vim.log.levels.WARN)
    return
  end

  local cmd = string.format("node %s; echo ''; read -p 'Presiona Enter para cerrar...'", vim.fn.shellescape(file))
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

function M.setup(dap, mason_path)
  local js_debug_path = mason_path .. "/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = 8124,
    executable = {
      command = "node",
      args = { js_debug_path, "8124", "127.0.0.1" },
    },
    options = { detached = false },
  }

  local node_configs = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      sourceMaps = true,
      skipFiles = { "<node_internals>/**" },
    },
  }

  dap.configurations.javascript = node_configs
  dap.configurations.typescript = node_configs
  dap.configurations.javascriptreact = node_configs
  dap.configurations.typescriptreact = node_configs
end

return M
