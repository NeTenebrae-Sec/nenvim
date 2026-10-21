-- =========================================================
-- keymaps/windows.lua
-- Gestion y division de ventanas (splits).
-- =========================================================

-- === CREACION ===
nmap("<leader>v", "<cmd>vsplit<CR>", "Window: Split Vertical")
nmap("<leader>h", "<cmd>split<CR>", "Window: Split Horizontal")

-- === NAVEGACION (Ctrl + Hjkl) ===
nmap("<C-h>", "<C-w>h", "Window: Focus Left")
nmap("<C-j>", "<C-w>j", "Window: Focus Down")
nmap("<C-k>", "<C-w>k", "Window: Focus Up")
nmap("<C-l>", "<C-w>l", "Window: Focus Right")

-- === REDIMENSIONADO (Alt + Flechas) ===
nmap("<M-Up>", "<cmd>resize +2<CR>", "Window: Resize Up")
nmap("<M-Down>", "<cmd>resize -2<CR>", "Window: Resize Down")
nmap("<M-Left>", "<cmd>vertical resize -2<CR>", "Window: Resize Left")
nmap("<M-Right>", "<cmd>vertical resize +2<CR>", "Window: Resize Right")
