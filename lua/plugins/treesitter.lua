-- =========================================================
-- treesitter.lua
-- Treesitter base para resaltado, indentado y soporte de autotag.
-- =========================================================

local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
  return
end

ts.install({
  ignore_install = { "tmux" },

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
})

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
local ok_context, context = pcall(require, "treesitter_context") -- 🎯 ¡Cambiado a guion bajo!
if ok_context then
  context.setup({
    enable = true, -- Activar el plugin
    max_lines = 4, -- Cuántas líneas fijadas como máximo arriba (para que no tape tu pantalla)
    min_window_height = 0, -- Monitorear en cualquier tamaño de ventana
    line_numbers = true, -- Muestra los números de línea reales del if/función arriba
    multiline_threshold = 1, -- Si el header ocupa mucho, solo fija la primera línea
    trim_scope = "outer", -- Descarta el exceso de scopes externos si pasa el max_lines
    mode = "cursor", -- Sigue el contexto basado en dónde está tu cursor
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
