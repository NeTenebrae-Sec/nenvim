local map = vim.keymap.set
local Snacks = require("snacks")
local vite = require("plugins.live-server")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function nmap(lhs, rhs, desc, bufnr)
  local opts = { silent = true, desc = desc }
  if bufnr then
    opts.buffer = bufnr
  end
  map("n", lhs, rhs, opts)
end

local function vmap(lhs, rhs, desc)
  map("v", lhs, rhs, { silent = true, desc = desc })
end

local function imap(lhs, rhs, desc)
  map("i", lhs, rhs, { silent = true, desc = desc })
end

-- =========================================================
-- EDITION & TEXT MANIPULATION
-- =========================================================
---------------------- (YANK / PASTE) ------------------
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

nmap("<leader>dd", "yyp", "Duplicate: Line Below")
vmap("<leader>dd", "y'>p", "Duplicate: Selection")

vmap("<", "<gv", "Unindent and Keep Selection")
vmap(">", ">gv", "Indent and Keep Selection")

----------------- MINI.MOVE -----------------
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

-- --- MINI.COMMENT (Comentarios rápidos) ------------------
nmap("gcc", function()
  require("mini.comment").toggle_linewise()
end, "Mini Comment: Toggle Line")
vmap("gc", function()
  require("mini.comment").toggle_linewise(vim.fn.visualmode())
end, "Mini Comment: Toggle Selection")

-- =========================================================
-- GESTIÓN DE BUFFERS / ARCHIVOS
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

-- Input interactivo para renombrar el buffer actual
nmap("<leader>br", function()
  vim.ui.input({ prompt = "New name: " }, function(input)
    if input and input ~= "" then
      vim.cmd("file " .. input)
    end
  end)
end, "Buffer: Rename / Set Name")

-- Scratchpad flotante (Bloc de notas temporal de Snacks)
nmap("<leader>bs", function()
  Snacks.scratch()
end, "Buffer: Scratchpad Temporal")

-- =========================================================
-- NAV, SCROLL & QUICK ACTIONS
-- =========================================================
-- NAVEGACIÓN Y BUSCADORES (Snacks)
nmap("<leader>e", function()
  Snacks.explorer()
end, "Explorer: Toggle")
nmap("<leader>ff", function()
  Snacks.picker.files()
end, "Find: Files")
nmap("<leader>fg", function()
  Snacks.picker.grep()
end, "Find: Grep")
nmap("<leader>fb", function()
  Snacks.picker.buffers()
end, "Find: Buffers")

-- Notificaciones
nmap("<leader>un", function()
  Snacks.notifier.show_history()
end, "Notification: History")

-- Autocomando para abrir la notificación en una ventana flotante con 'uu' (SÓLO LECTURA)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_notif_history",
  callback = function(event)
    nmap("uu", function()
      local line = vim.api.nvim_get_current_line()
      if line == "" then
        return
      end

      -- Limpiamos timestamps y niveles de log (ej: "18:00:22 [INFO] Mensaje")
      local clean_line = line:gsub("^%d%d:%d%d:%d%d%s+%[%w+%]%s+", "")

      Snacks.win({
        text = clean_line,
        width = 0.7,
        height = 0.3,
        border = "rounded",
        backdrop = 60,
        zindex = 150, -- Por encima del historial de Snacks (100)
        title = " Notification details ",
        title_pos = "center",
        wo = {
          wrap = true,
          conceallevel = 2,
        },
        bo = {
          filetype = "markdown",
          modifiable = false,
          buftype = "nofile",
          readonly = true,
        },
        keys = {
          q = "close", -- 'q' cierra la ventana flotante
        },
      })
    end, "Ver detalle de notificación", event.buf)
  end,
})

-- --- CONTROL DE BÚSQUEDA Y ESCAPE ------------------------
imap("<C-c>", "<Esc>", "Insert: Escape")
nmap("<C-c>", "<cmd>nohlsearch<CR>", "Clear Search Highlight")
vmap("<C-c>", "<Esc>", "Visual: Escape / Cancel Multi-Cursor")
nmap("<C-c>", function()
  -- Cierra el resaltado de búsqueda primero
  vim.cmd("nohlsearch")

  -- Si hay una ventana flotante abierta (que no sea el editor principal), la cierra
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    vim.api.nvim_win_close(win, false)
  end
end, "Clear Search and Close Float Window")

-- --- EDICIÓN ÁGIL / SCROLL CENTRADO ----------------------
nmap("<C-f>", "<C-f>", "Scroll: Page Down")
nmap("<C-b>", "<C-b>", "Scroll: Page Up")
nmap("n", "nzzzv", "Next Search Result Centered")
nmap("N", "Nzzzv", "Previous Search Result Centered")

-- NAVEGACIÓN RÁPIDA (Flash.nvim)
nmap("s", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.jump()
  end
end, "Flash: Jump")

vmap("s", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.jump()
  end
end, "Flash: Jump")

-- En modo normal (nmap): Salta usando Treesitter y limpia la selección al instante
nmap("S", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.treesitter()
    -- Espera un instante a que termine el salto y sale del modo visual automáticamente
    vim.schedule(function()
      local mode = vim.fn.mode()
      if mode == "v" or mode == "V" then
        vim.cmd("normal! \27") -- Envía un caracter <Esc> para quitar la selección
      end
    end)
  end
end, "Flash: Treesitter (Jump only)")

-- En modo visual (vmap): Mantiene la selección activa para operar sobre ella
vmap("S", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.treesitter()
  end
end, "Flash: Treesitter (Select)")

-- --- SISTEMA Y CÓDIGO ------------------------------------
nmap("<leader>X", "<cmd>!chmod +x %<CR>", "Make File Executable")

nmap("<leader>re", function()
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Restart Neovim completely?",
  }, function(choice)
    if choice == "Yes" then
      vim.cmd("silent! wa") -- Guarda todo
      vim.cmd("restart") -- Reinicia
    end
  end)
end, "Restart Config")

nmap("<leader>z", "za", "Fold: Toggle under cursor")

-- --- HISTORIAL DE CAMBIOS (Undotree) ---------------------
nmap("<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  local ok, undotree = pcall(require, "undotree")
  if ok then
    undotree.open()
  end
end, "Toggle Builtin Undotree")

-- --- INTEGRACIONES CON SNACKS ---------------------------
nmap("<leader>tt", function()
  Snacks.terminal()
end, "Terminal: Toggle")

nmap("<leader>ud", function()
  Snacks.toggle.dim():toggle()
end, "Focus: Toggle Dim")

nmap("<leader>uz", function()
  Snacks.toggle.zen():toggle()
end, "Zen: Toggle Mode")

-- --- SERVIDORES LOCALES (Live Server) --------------------
nmap("<leader>us", vite.toggle_vite_server, "Vite: Toggle Server (Multi-project)")

-- GIT (Lazygit & Gitsigns)
nmap("<leader>gg", function()
  Snacks.lazygit()
end, "Git: Lazygit")
nmap("<leader>gb", "<cmd>Gitsigns blame_line<CR>", "Git: Blame Line")
-- Descartar líneas/hunk con Gitsigns
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

-- =========================================================
-- GESTIÓN Y DIVISIÓN DE VENTANAS (SPLITS)
-- =========================================================

-- --- CREACIÓN DE RECUADROS ------------------------------
nmap("<leader>v", "<cmd>vsplit<CR>", "Window: Split Vertical")
nmap("<leader>h", "<cmd>split<CR>", "Window: Split Horizontal")

-- --- NAVEGACIÓN ENTRE VENTANAS (Ctrl + Hjkl) -------------
nmap("<C-h>", "<C-w>h", "Window: Focus Left")
nmap("<C-j>", "<C-w>j", "Window: Focus Down")
nmap("<C-k>", "<C-w>k", "Window: Focus Up")
nmap("<C-l>", "<C-w>l", "Window: Focus Right")

-- --- REDIMENSIONADO DE PANTALLA (Alt + Flechas) ----------
nmap("<M-Up>", "<cmd>resize +2<CR>", "Window: Resize Up")
nmap("<M-Down>", "<cmd>resize -2<CR>", "Window: Resize Down")
nmap("<M-Left>", "<cmd>vertical resize -2<CR>", "Window: Resize Left")
nmap("<M-Right>", "<cmd>vertical resize +2<CR>", "Window: Resize Right")

-- =========================================================
-- 🔥 AUTOCOMPLETADO Y SNIPPETS (nvim-cmp & LuaSnip)
-- =========================================================

-- --- NAVEGACIÓN NATIVA CON FLECHAS -----------------------
imap("<Down>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok and cmp.visible() then
    cmp.select_next_item()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Down>", true, false, true), "n", true)
  end
end, "CMP: Next Item with Arrow")

imap("<Up>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok and cmp.visible() then
    cmp.select_prev_item()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Up>", true, false, true), "n", true)
  end
end, "CMP: Prev Item with Arrow")

-- --- NAVEGACIÓN ESTÁNDAR (Ctrl+n / Ctrl+p) ----------------
imap("<C-n>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok and cmp.visible() then
    cmp.select_next_item()
  end
end, "CMP: Select Next")

imap("<C-p>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok and cmp.visible() then
    cmp.select_prev_item()
  end
end, "CMP: Select Previous")

-- --- DOCUMENTACIÓN (Scroll) ------------------------------
imap("<C-f>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.scroll_docs(4)
  end
end, "CMP: Scroll Docs Down")

imap("<C-b>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.scroll_docs(-4)
  end
end, "CMP: Scroll Docs Up")

-- --- ACCIONES Y CONFIRMACIÓN -----------------------------
imap("<C-Space>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.complete()
  end
end, "CMP: Trigger Completion")

imap("<CR>", function()
  local ok, cmp = pcall(require, "cmp")
  if ok and cmp.visible() then
    cmp.confirm({ select = false })
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
  end
end, "CMP: Smart Confirm Entry")

-- =========================================================
-- FORMATO / LSP
-- =========================================================
nmap("<leader>f", function()
  local ok_conform, conform = pcall(require, "conform")
  if ok_conform then
    conform.format({ async = true, lsp_fallback = true })
  else
    vim.lsp.buf.format({ async = true })
  end
end, "Format: File")

nmap("K", function()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  -- Disparamos la petición a todos los LSP activos de forma manual y controlada
  vim.lsp.buf_request(0, "textDocument/hover", params, function(err, result, ctx, config)
    -- Si hay error o la respuesta no tiene contenido (contents), MORIR EN SILENCIO
    if err or not result or not result.contents then
      return
    end

    -- Si un servidor respondió con contenido válido, renderizarlo con Noice o el flotante nativo
    local ok_noice, noice_handlers = pcall(require, "noice.lsp.handlers")
    if ok_noice and noice_handlers.hover then
      noice_handlers.hover(err, result, ctx, config)
    else
      local _, winnr = vim.lsp.handlers["textDocument/hover"](
        err,
        result,
        ctx,
        vim.tbl_deep_extend("force", config or {}, {
          border = "rounded",
          focusable = true,
        })
      )

      -- Desactivar diagnósticos explícitamente en la ventana flotante generada
      if winnr and vim.api.nvim_win_is_valid(winnr) then
        local bufnr = vim.api.nvim_win_get_buf(winnr)
        vim.diagnostic.enable(false, { bufnr = bufnr })
      end
    end
  end)
end, "Universal Silent LSP Hover")
nmap("gd", vim.lsp.buf.definition, "LSP: Definition")
nmap("gr", vim.lsp.buf.references, "LSP: References")
nmap("GD", vim.diagnostic.open_float, "LSP: Show diagnostic float")
nmap("GR", vim.diagnostic.setloclist, "LSP: Open Loclist")

nmap("gn", function()
  vim.diagnostic.jump({ count = 1 })
end, "LSP: Next diagnostic")

nmap("gN", function()
  vim.diagnostic.jump({ count = -1 })
end, "LSP: Prev diagnostic")

nmap("<leader>rn", function()
  local ok_otter, otter = pcall(require, "otter")
  if ok_otter and type(otter.rename) == "function" then
    -- Intentar renombrar vía Otter (ideal para archivos políglotas/múltiples LSPs en el mismo buffer)
    local status = pcall(otter.rename)
    if status then
      return
    end
  end

  -- Fallback universal nativo para cualquier archivo o LSP estándar
  vim.lsp.buf.rename()
end, "LSP / Otter: Rename")
nmap("<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")

nmap("GI", function()
  local items = vim.inspect_pos()
  local lines = {}

  if #items.treesitter > 0 then
    table.insert(lines, "Treesitter:")
    for _, capture in ipairs(items.treesitter) do
      table.insert(lines, string.format("  - @%s -> %s", capture.capture, capture.hl_group))
    end
  end

  if #items.syntax > 0 then
    if #lines > 0 then
      table.insert(lines, "")
    end
    table.insert(lines, "Syntax:")
    for _, syn in ipairs(items.syntax) do
      table.insert(lines, string.format("  - %s -> %s", syn.hl_group, syn.hl_group))
    end
  end

  if #lines == 0 then
    lines = { "No highlight information found here." }
  end

  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focusable = true,
    focus = true,
  })
end, "Inspect highlights in floating window")

-- =========================================================
-- DEBUGGING (nvim-dap / dap-ui)
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

-- =========================================================
--  NAVEGACIÓN QUIRÚRGICA (Movimientos Esenciales)
-- =========================================================

-- 1. MOVIMIENTO POR PALABRAS (w, e, b)
-- w, e, b, ge son nativos, no los remapes.
-- Solo documentación mental:
--   w -> inicio de la siguiente palabra
--   e -> final de la siguiente palabra
--   b -> inicio de la anterior palabra
--   ge -> final de la anterior palabra

-- 2. BÚSQUEDA EN LÍNEA HORIZONTAL (f, F, t, T)
-- Estos “no cambian nada”, pero les pones `desc` para que aparezca en :harm
-- y en tu ayuda de nvim-treeview / which-key / etc.

nmap("f", "f", "Buscar carácter adelante (Horizontal)")
nmap("F", "F", "Buscar carácter atrás (Horizontal)")
nmap("t", "t", "Saltar hasta antes del carácter (Adelante)")
nmap("T", "T", "Saltar hasta después del carácter (Atrás)")

-- 3. REPETICIÓN DE BÚSQUEDA HORIZONTAL
nmap(";", ";", "Repetir último salto horizontal")
nmap(",", ",", "Repetir último salto horizontal (Inverso)")

-- 4. EXTREMOS DE LA LÍNEA (Inicio y Fin Reales)
nmap("H", "^", "Ir al primer carácter útil de la línea")
nmap("L", "$", "Ir al final de la línea")

-- 5. NAVEGACIÓN VERTICAL RÁPIDA (Saltos de Bloque)
nmap("}", "}", "Saltar al siguiente bloque de código")
nmap("{", "{", "Saltar al anterior bloque de código")
