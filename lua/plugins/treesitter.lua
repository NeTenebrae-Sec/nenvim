-- =========================================================
-- treesitter.lua
-- Treesitter base para resaltado, indentado y soporte de autotag.
-- =========================================================

local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
  return
end

vim.schedule(function()
  ts.install({
    -- Base
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",

    -- Shell / sistema
    "bash",
    "awk",
    "make",
    "cmake",

    -- Lenguajes principales
    "c",
    "cpp",
    "python",
    "java",

    -- Web
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "json",
    "yaml",
    "toml",
    "scss",
    "dockerfile",
    "graphql",
    "xml",
    "svelte",
    "vue",
    "astro",

    -- Otros útiles
    "sql",
    "regex",
    "diff",
    "gitignore",
    "gitcommit",
  }):raise_on_error()
end)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    local buftype = vim.bo[args.buf].buftype
    local filetype = vim.bo[args.buf].filetype

    if buftype ~= "" then
      return
    end

    local ignore_ft = {
      "help",
      "qf",
      "checkhealth",
      "snacks_picker_input",
      "snacks_picker_list",
    }

    if vim.tbl_contains(ignore_ft, filetype) then
      return
    end

    local success, parser = pcall(vim.treesitter.get_parser, args.buf)
    if success and parser then
      vim.treesitter.start(args.buf)
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false
vim.opt.foldlevel = 99

-- =========================================================
-- 👑 STICKY SCROLL (Contexto superior al bajar)
-- =========================================================
local ok_context, context = pcall(require, "treesitter_context")
if ok_context then
  context.setup({
    enable = true,
    max_lines = 4,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 1,
    trim_scope = "outer",
    mode = "cursor",

    -- 🛠️ FIX DEFINITIVO EN NEOVIM 0.12:
    on_attach = function(buf)
      -- Nueva sintaxis de API Neovim 0.10/0.11/0.12 para apagar diagnósticos por buffer
      pcall(vim.diagnostic.enable, false, { bufnr = buf })
      return true
    end,
  })
end
-- =========================================================
-- 🏷️ AUTO CLOSE TAG (Solo abre y cierra)
-- =========================================================
local ok_autotag, autotag = pcall(require, "nvim-ts-autotag")
if ok_autotag then
  autotag.setup({
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = true,
    },
  })
end
