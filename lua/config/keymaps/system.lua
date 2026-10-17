-- =========================================================
-- keymaps/system.lua
-- Sistema, utilidades generales y herramientas auxiliares.
-- =========================================================

local ok_snacks, Snacks = pcall(require, "snacks")

-- === SISTEMA ===
nmap("<leader>X", "<cmd>!chmod +x %<CR>", "Make File Executable")

nmap("<leader>re", function()
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Restart Neovim completely?",
  }, function(choice)
    if choice == "Yes" then
      vim.cmd("silent! wa")
      vim.cmd("restart")
    end
  end)
end, "Restart Config")

-- === FOLD ===
nmap("<leader>z", "za", "Fold: Toggle under cursor")

-- === UNDOTREE ===
nmap("<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  local ok, undotree = pcall(require, "undotree")
  if ok then
    undotree.open()
  end
end, "Toggle Builtin Undotree")

-- === SNACKS TERMINAL / TOGGLE ===
nmap("<leader>tt", function()
  if not ok_snacks then
    return
  end
  Snacks.terminal()
end, "Terminal: Toggle")

nmap("<leader>ud", function()
  if not ok_snacks then
    return
  end
  Snacks.toggle.dim():toggle()
end, "Focus: Toggle Dim")

nmap("<leader>uz", function()
  if not ok_snacks then
    return
  end
  Snacks.toggle.zen():toggle()
end, "Zen: Toggle Mode")

-- === WEB SERVER (Serve & Open) ===
local ok_vite, vite = pcall(require, "plugins.live-server")
if ok_vite then
  nmap("<leader>us", vite.toggle_vite_server, "Web: Serve & Open")
end

-- === GIT (Lazygit & Gitsigns) ===
nmap("<leader>gg", function()
  if not ok_snacks then
    return
  end
  Snacks.lazygit()
end, "Git: Lazygit")
nmap("<leader>gb", "<cmd>Gitsigns blame_line<CR>", "Git: Blame Line")

nmap("<leader>gr", function()
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.reset_hunk()
  end
end, "Git: Reset Hunk / Line under cursor")

vmap("<leader>gr", function()
  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
  end
end, "Git: Reset Selected Lines")

-- === NAVEGACION QUIRURGICA ===
nmap("f", "f", "Buscar caracter adelante (Horizontal)")
nmap("F", "F", "Buscar caracter atras (Horizontal)")
nmap("t", "t", "Saltar hasta antes del caracter (Adelante)")
nmap("T", "T", "Saltar hasta despues del caracter (Atras)")

nmap(";", ";", "Repetir ultimo salto horizontal")
nmap(",", ",", "Repetir ultimo salto horizontal (Inverso)")

nmap("H", "^", "Ir al primer caracter util de la linea")
nmap("L", "$", "Ir al final de la linea")

nmap("}", "}", "Saltar al siguiente bloque de codigo")
nmap("{", "{", "Saltar al anterior bloque de codigo")
