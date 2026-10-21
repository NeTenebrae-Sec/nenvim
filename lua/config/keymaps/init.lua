-- =========================================================
-- keymaps/init.lua
-- Punto de entrada: leader keys, helpers y carga de módulos.
-- =========================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

function _G.nmap(lhs, rhs, desc, bufnr)
  local opts = { silent = true, desc = desc }
  if bufnr then
    opts.buffer = bufnr
  end
  map("n", lhs, rhs, opts)
end

function _G.vmap(lhs, rhs, desc)
  map("v", lhs, rhs, { silent = true, desc = desc })
end

function _G.imap(lhs, rhs, desc)
  map("i", lhs, rhs, { silent = true, desc = desc })
end

require("config.keymaps.edit")
require("config.keymaps.buffers")
require("config.keymaps.navigation")
require("config.keymaps.windows")
require("config.keymaps.completion")
require("config.keymaps.lsp")
require("config.keymaps.debugging")
require("config.keymaps.system")
