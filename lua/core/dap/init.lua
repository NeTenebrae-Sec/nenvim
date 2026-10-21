-- =========================================================
-- Motor DAP: wiring, runner y registro desde fichas
-- =========================================================
-- Posee: keymap <leader>dr, fallback Kitty, ui (signs/dapui/listeners)
-- y el wiring de adapters/configurations por filetype.
-- Las fichas de languages/ aportan `dap` = { run, setup }
-- (schema 002); el motor llama setup(dap, tools_path) de cada una
-- y el runner resuelve run() por filetype.

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

-- Registro de configurations/adapters desde las fichas (schema 002)
local tools_path = vim.fn.stdpath("data") .. "/tools"

local ok_langs, languages = pcall(require, "languages")
if ok_langs then
  for _, ficha in ipairs(languages.all()) do
    if ficha.dap and type(ficha.dap.setup) == "function" then
      local ok_setup, err = pcall(ficha.dap.setup, dap_lib, tools_path)
      if not ok_setup then
        vim.notify("DAP setup falló (" .. (ficha.name or "?") .. "): " .. tostring(err), vim.log.levels.WARN)
      end
    end
  end
end
