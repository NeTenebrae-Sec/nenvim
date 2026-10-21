-- =========================================================
-- init.lua
-- Tema Negro/Cyan profundo de Alto Contraste para Neovim.
-- =========================================================

local M = {}

local colors = require("themes.dark_cyan.colors")
local ui = require("themes.dark_cyan.ui")
local syntax = require("themes.dark_cyan.syntax")
local plugins = require("themes.dark_cyan.plugins")
local lsp = require("themes.dark_cyan.lsp")

local hl = vim.api.nvim_set_hl

local function set(group, opts)
  hl(0, group, opts)
end

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "dark_cyan"

  ui.setup(colors, set)
  syntax.setup(colors, set)
  plugins.setup(colors, set)
  lsp.setup(colors, set)
end

return M
