local ok, lint = pcall(require, "lint")
if not ok then
  return
end

-- Tabla global donde cada módulo asignará sus linters
lint.linters_by_ft = {}

-- Cargar módulos de linters directamente en esta misma carpeta
local linters = {
  "javascript",
  "css",
  "html",
  "markdown",
}

for _, name in ipairs(linters) do
  pcall(require, "plugins.lsp.linter." .. name)
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
