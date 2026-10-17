-- =========================================================
-- Motor DAP > ui: signs, dapui y listeners
-- =========================================================
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return
end

local ok_dapui, dapui = pcall(require, "dapui")
if not ok_dapui then
  return
end

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpointRejected" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })
vim.fn.sign_define("DapStopped", { text = "", linehl = "Visual", numhl = "DiagnosticWarn" })

dapui.setup({
  icons = { expanded = "", collapsed = "", current_frame = "" },
  controls = {
    enabled = true,
    icons = {
      pause = "",
      play = "",
      step_into = "",
      step_over = "",
      step_out = "",
      step_back = "",
      run_last = "↻",
      terminate = "□",
      disconnect = "",
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
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Startup notifications
local notified = false
dap.listeners.before.launch["debugger_notify"] = function()
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
dap.listeners.after.event_terminated["debugger_notify"] = reset_notify
dap.listeners.after.event_exited["debugger_notify"] = reset_notify
