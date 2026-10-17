-- =========================================================
-- Motor Lint (nvim-lint): machinery + registro por fichas
-- =========================================================
-- Los datos (ft→linters) los registran en F0 los módulos de
-- plugins/lsp/linter/ (temporal hasta F2 de la spec 002) y en F2
-- las fichas de languages/, vía M.register(ft, linters).

local M = {}

local ok, lint = pcall(require, "lint")
if not ok then
  return
end

lint.linters_by_ft = {}
M.lint = lint

function M.register(ft, linters)
  lint.linters_by_ft[ft] = linters
end

-- Autocomando global para ejecutar nvim-lint
local group = vim.api.nvim_create_augroup("NvimLintConfig", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = group,
  callback = function(args)
    if not vim.api.nvim_buf_is_valid(args.buf) then
      return
    end

    if vim.bo[args.buf].buftype ~= "" then
      return
    end

    vim.schedule(function()
      lint.try_lint()
    end)
  end,
})

return M
