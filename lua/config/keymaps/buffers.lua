-- =========================================================
-- keymaps/buffers.lua
-- Gestion de buffers y archivos.
-- =========================================================

nmap("<leader>w", "<cmd>w<CR>", "File: Write")
nmap("<leader>q", "<cmd>q<CR>", "Window: Quit")
nmap("<leader>ve", "<cmd>edit $MYVIMRC<CR>", "Vim: Edit init.lua")

nmap("<leader>bn", "<cmd>bnext<CR>", "Buffer: Next")
nmap("<leader>bp", "<cmd>bprevious<CR>", "Buffer: Previous")

-- Cerrar buffer (mini.bufremove)
nmap("<leader>bd", function()
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(0, false)
  else
    vim.cmd("bdelete")
  end
end, "Buffer: Delete Safely")

-- Renombrar buffer
nmap("<leader>br", function()
  vim.ui.input({ prompt = "New name: " }, function(input)
    if input and input ~= "" then
      vim.cmd("file " .. input)
    end
  end)
end, "Buffer: Rename / Set Name")

-- Scratchpad flotante (Snacks)
nmap("<leader>bs", function()
  require("snacks").scratch()
end, "Buffer: Scratchpad Temporal")
