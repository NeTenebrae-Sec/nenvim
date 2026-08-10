-- ===============================
-- DAP BASE MODULE LOADING
-- ===============================
local ok_dap, dap_lib = pcall(require, "dap")
if not ok_dap then
  return
end

local ok_dapui, dapui = pcall(require, "dapui")
if not ok_dapui then
  return
end

-- ===============================
-- GLOBAL KEYMAPS & RUNNER
-- ===============================
local runner = require("plugins.lsp.dap.runner")

-- <leader>dr executes the runner function based on the current filetype
vim.keymap.set("n", "<leader>dr", runner.run_current_file, { desc = "Run current file/project in Kitty" })

-- Global external terminal setup (Kitty)
dap_lib.defaults.fallback.focus_terminal = true
dap_lib.defaults.fallback.external_terminal = {
  command = "/usr/bin/kitty",
  args = { "--hold", "-e" },
}

-- ===============================
-- DAP UI SETUP & SIGNS
-- ===============================
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpointRejected" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "Visual", numhl = "DiagnosticWarn" })

dapui.setup({
  icons = { expanded = "", collapsed = "", current_frame = "" },
  controls = {
    enabled = true,
    icons = {
      pause = "",
      play = "",
      step_into = "",
      step_over = "",
      step_out = "",
      step_back = "",
      run_last = "↻",
      terminate = "□",
      disconnect = "",
    },
  },
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.60 },
        { id = "breakpoints", size = 0.20 },
        { id = "stacks", size = 0.20 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = { { id = "watches", size = 1.0 } },
      size = 10,
      position = "bottom",
    },
  },
})

-- AUTO-BIND EVENT LISTENERS TO OPEN/CLOSE UI
dap_lib.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap_lib.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap_lib.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Startup notifications
local notified = false
dap_lib.listeners.before.launch["debugger_notify"] = function()
  if notified then
    return
  end
  notified = true
  local ok_bp, dap_breakpoints = pcall(require, "dap.breakpoints")
  local has_bp = ok_bp and not vim.tbl_isempty(dap_breakpoints.get())
  vim.notify(has_bp and "Starting debugger..." or "Starting debugger without breakpoints.", vim.log.levels.INFO)
end

local function reset_notify()
  notified = false
end
dap_lib.listeners.after.event_terminated["debugger_notify"] = reset_notify
dap_lib.listeners.after.event_exited["debugger_notify"] = reset_notify

-- ===============================
-- DYNAMIC MODULAR CONFIG LOADING
-- ===============================
local mason_path = vim.fn.stdpath("data") .. "/mason"

local configs = { "js", "python", "bash", "c", "java" }
for _, config in ipairs(configs) do
  local ok, module = pcall(require, "plugins.lsp.dap." .. config)
  if ok and type(module.setup) == "function" then
    module.setup(dap_lib, mason_path)
  else
    vim.notify("Failed to load DAP config for: " .. config, vim.log.levels.WARN)
  end
end
