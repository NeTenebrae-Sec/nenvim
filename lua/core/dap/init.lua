-- =========================================================
-- Motor DAP: wiring, runner y registro desde fichas
-- =========================================================
-- Posee: keymap <leader>dr, fallback Kitty, ui (signs/dapui/listeners)
-- y el wiring de adapters/configurations por filetype.
-- Las fichas de languages/ aportan `dap` (schema 002); mientras tanto
-- la lista de módulos temporal carga plugins/lsp/dap/<ft>.lua (F2 002).

local ok_dap, dap_lib = pcall(require, "dap")
if not ok_dap then
  return
end

local ok_dapui = pcall(require, "dapui")
if not ok_dapui then
  return
end

local runner = require("core.dap.runner")

-- <leader>dr executes the runner function based on the current filetype
vim.keymap.set("n", "<leader>dr", runner.run_current_file, { desc = "Run current file/project in Kitty" })

-- Global external terminal setup (Kitty)
dap_lib.defaults.fallback.focus_terminal = true
dap_lib.defaults.fallback.external_terminal = {
  command = "/usr/bin/kitty",
  args = { "--hold", "-e" },
}

require("core.dap.ui")

-- Registro de configurations/adapters por filetype (schema 002)
local M = {}

-- Temporal: módulos de lenguaje todavía en plugins/lsp/dap/ (F2 002)
local configs = { "js", "python", "bash", "c", "java", "astro" }
local mason_path = vim.fn.stdpath("data") .. "/mason"

for _, config in ipairs(configs) do
  local ok, module = pcall(require, "plugins.lsp.dap." .. config)
  if ok and type(module.setup) == "function" then
    module.setup(dap_lib, mason_path)
  else
    vim.notify("Failed to load DAP config for: " .. config, vim.log.levels.WARN)
  end
end

return M
