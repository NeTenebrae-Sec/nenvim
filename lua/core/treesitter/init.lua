-- =========================================================
-- Motor Treesitter: install, highlight, indent, folds
-- =========================================================
-- La lista base (editores de texto del día a día y utilidades)
-- vive aquí; los parsers específicos de lenguaje llegan de los
-- campos `parsers` de las fichas de languages/ (schema 002).

local ok, ts = pcall(require, "nvim-treesitter")
if not ok then
  return
end

vim.schedule(function()
  local wanted = {
    -- Base (editor)
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "regex",
    "diff",
    "gitignore",
    "gitcommit",

    -- Sistema / build
    "awk",
    "make",
    "cmake",
    "dockerfile",
    "yaml",

    -- Markup / datos
    "graphql",
    "xml",
  }

  -- Registro desde fichas de lenguaje (schema 002)
  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    for _, ficha in ipairs(languages.all()) do
      vim.list_extend(wanted, ficha.parsers or {})
    end
  end

  -- Instalar solo los que falten: ts.install en cada arranque revisaba todo
  -- (spawns de git/red). Updates manuales con :TSUpdate.
  local missing = {}
  for _, lang in ipairs(wanted) do
    if not pcall(vim.treesitter.language.add, lang) then
      table.insert(missing, lang)
    end
  end
  if #missing > 0 then
    ts.install(missing):raise_on_error()
  end
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
