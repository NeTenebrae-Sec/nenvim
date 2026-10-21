-- =========================================================
-- keymaps/edit.lua
-- Edicion y manipulacion de texto.
-- =========================================================

-- === YANK / PASTE ===
nmap("<leader>y", '"+y', "Yank: Clipboard")
vmap("<leader>y", '"+y', "Yank: Clipboard")
nmap("<leader>Y", '"+Y', "Yank: Line to Clipboard")
nmap("<leader>ya", function()
  vim.cmd('normal! ggVG"+y')
end, "Yank: All")

nmap("<leader>p", '"+p', "Paste: Clipboard")
vmap("<leader>p", '"+p', "Paste: Clipboard")
nmap("<leader>P", '"+P', "Paste: Clipboard Before")
vmap("p", '"_dP', "Paste Over Selection (No overwrite register)")

-- === DUPLICATE ===
nmap("<leader>dd", "yyp", "Duplicate: Line Below")
vmap("<leader>dd", "y'>p", "Duplicate: Selection")

-- === INDENT (visual) ===
vmap("<", "<gv", "Unindent and Keep Selection")
vmap(">", ">gv", "Indent and Keep Selection")

-- === MINI.MOVE ===
nmap("<C-S-k>", function()
  require("mini.move").move_line("up")
end, "Mini Move: Up")
vmap("<C-S-k>", function()
  require("mini.move").move_selection("up")
end, "Mini Move: Up")

nmap("<C-S-j>", function()
  require("mini.move").move_line("down")
end, "Mini Move: Down")
vmap("<C-S-j>", function()
  require("mini.move").move_selection("down")
end, "Mini Move: Down")

-- === MINI.COMMENT ===
nmap("gcc", function()
  require("mini.comment").toggle_linewise()
end, "Mini Comment: Toggle Line")
vmap("gc", function()
  require("mini.comment").toggle_linewise(vim.fn.visualmode())
end, "Mini Comment: Toggle Selection")
