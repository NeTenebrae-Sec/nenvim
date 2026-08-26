-- =========================================================
-- keymaps/navigation.lua
-- Navegacion, busqueda y Flash.
-- =========================================================

local Snacks = require("snacks")

-- === SNACKS EXPLORER / FINDER ===
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

-- === NOTIFICACIONES ===
nmap("<leader>un", function()
  Snacks.notifier.show_history()
end, "Notification: History")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_notif_history",
  callback = function(event)
    nmap("uu", function()
      local line = vim.api.nvim_get_current_line()
      if line == "" then
        return
      end
      local clean_line = line:gsub("^%d%d:%d%d:%d%d%s+%[%w+%]%s+", "")
      Snacks.win({
        text = clean_line,
        width = 0.7,
        height = 0.3,
        border = "rounded",
        backdrop = 60,
        zindex = 150,
        title = " Notification details ",
        title_pos = "center",
        wo = { wrap = true, conceallevel = 2 },
        bo = {
          filetype = "markdown",
          modifiable = false,
          buftype = "nofile",
          readonly = true,
        },
        keys = { q = "close" },
      })
    end, "Ver detalle de notificacion", event.buf)
  end,
})

-- === CONTROL DE BUSQUEDA Y ESCAPE ===
imap("<C-c>", "<Esc>", "Insert: Escape")
nmap("<C-c>", "<cmd>nohlsearch<CR>", "Clear Search Highlight")
vmap("<C-c>", "<Esc>", "Visual: Escape / Cancel Multi-Cursor")
nmap("<C-c>", function()
  vim.cmd("nohlsearch")
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    vim.api.nvim_win_close(win, false)
  end
end, "Clear Search and Close Float Window")

-- === SCROLL CENTRADO ===
nmap("<C-f>", "<C-f>", "Scroll: Page Down")
nmap("<C-b>", "<C-b>", "Scroll: Page Up")
nmap("n", "nzzzv", "Next Search Result Centered")
nmap("N", "Nzzzv", "Previous Search Result Centered")

-- === FLASH.NVIM ===
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

nmap("S", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.treesitter()
    vim.schedule(function()
      local mode = vim.fn.mode()
      if mode == "v" or mode == "V" then
        vim.cmd("normal! \27")
      end
    end)
  end
end, "Flash: Treesitter (Jump only)")

vmap("S", function()
  local ok, flash = pcall(require, "flash")
  if ok then
    flash.treesitter()
  end
end, "Flash: Treesitter (Select)")
