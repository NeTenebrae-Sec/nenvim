-- =========================================================
-- keymaps/debugging.lua
-- Debugging (nvim-dap / dap-ui).
-- =========================================================

local ok_dap, dap = pcall(require, "dap")
local ok_dapui, dapui = pcall(require, "dapui")

if ok_dap then
  nmap("<leader>db", function()
    dap.toggle_breakpoint()
  end, "DAP: Toggle Breakpoint")
  nmap("<leader>dc", function()
    dap.continue()
  end, "DAP: Start/Continue Session")
  nmap("<leader>dx", function()
    dap.terminate()
  end, "DAP: Terminate Session")
  nmap("<leader>do", function()
    dap.step_over()
  end, "DAP: Step Over")
  nmap("<leader>di", function()
    dap.step_into()
  end, "DAP: Step Into")
  nmap("<leader>du", function()
    dap.step_out()
  end, "DAP: Step Out")
  nmap("<leader>dr", function()
    dap.repl.toggle()
  end, "DAP: Toggle REPL")
end

if ok_dapui then
  nmap("<leader>ui", function()
    dapui.toggle()
  end, "DAP: Toggle UI panel")
end
