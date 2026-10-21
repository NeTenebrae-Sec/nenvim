-- ==============================================================================
-- Configuración limpia de vim-visual-multi para vimpack
-- ==============================================================================

vim.g.VM_leader = "\\"

vim.g.VM_maps = {
  ["Find Under"] = "<C-n>",
  ["Select All"] = "<leader>A",
  ["Add Cursor Down"] = "<M-j>",
  ["Add Cursor Up"] = "<M-k>",
  ["Find Next"] = "n",
  ["Find Prev"] = "N",
  ["Skip Region"] = "q",
  ["Remove Region"] = "Q",
  ["Undo"] = "u",
  ["Redo"] = "<C-r>",
}

vim.g.VM_theme = "iceblue"
vim.g.VM_mouse_mappings = 1
vim.g.VM_show_warnings = 0
vim.g.VM_silent_exit = 1

-- Marcar estado global para que nvim-cmp lo detecte al instante
local vm_group = vim.api.nvim_create_augroup("VMStateTracking", { clear = true })

vim.api.nvim_create_autocmd("User", {
  pattern = "VM_Start",
  group = vm_group,
  callback = function()
    vim.g.VM_active = 1
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "VM_Exit",
  group = vm_group,
  callback = function()
    vim.g.VM_active = 0
  end,
})
