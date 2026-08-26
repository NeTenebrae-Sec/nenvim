-- =========================================================
-- keymaps/completion.lua
-- Autocompletado y snippets (nvim-cmp).
-- =========================================================

local function cmp()
  return require("cmp")
end

-- === NAVEGACION CON FLECHAS ===
imap("<Down>", function()
  local c = cmp()
  if c and c.visible() then
    c.select_next_item()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Down>", true, false, true), "n", true)
  end
end, "CMP: Next Item with Arrow")

imap("<Up>", function()
  local c = cmp()
  if c and c.visible() then
    c.select_prev_item()
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Up>", true, false, true), "n", true)
  end
end, "CMP: Prev Item with Arrow")

-- === NAVEGACION ESTANDAR (Ctrl+n / Ctrl+p) ===
imap("<C-n>", function()
  local c = cmp()
  if c and c.visible() then
    c.select_next_item()
  end
end, "CMP: Select Next")

imap("<C-p>", function()
  local c = cmp()
  if c and c.visible() then
    c.select_prev_item()
  end
end, "CMP: Select Previous")

-- === SCROLL DE DOCUMENTACION ===
imap("<C-f>", function()
  local c = cmp()
  if c then
    c.scroll_docs(4)
  end
end, "CMP: Scroll Docs Down")

imap("<C-b>", function()
  local c = cmp()
  if c then
    c.scroll_docs(-4)
  end
end, "CMP: Scroll Docs Up")

-- === ACCIONES Y CONFIRMACION ===
imap("<C-Space>", function()
  local c = cmp()
  if c then
    c.complete()
  end
end, "CMP: Trigger Completion")

imap("<CR>", function()
  local c = cmp()
  if c and c.visible() then
    c.confirm({ select = false })
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
  end
end, "CMP: Smart Confirm Entry")
