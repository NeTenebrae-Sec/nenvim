-- =========================================================
-- Motor Lint (nvim-lint): machinery + registro por fichas
-- =========================================================
-- Los datos (ft→linters) los aportan las fichas de languages/ via
-- su campo `lint` (schema 002). Las configs avanzadas de un linter
-- (args con detección de config del proyecto) viven en los auxiliares
-- de la propia ficha. Sin reset de la tabla: los auxiliares de las
-- fichas pueden haber registrado antes (orden de carga libre).

local M = {}

local ok, lint = pcall(require, "lint")
if not ok then
  return
end

lint.linters_by_ft = lint.linters_by_ft or {}
M.lint = lint

function M.register(ft, linters)
  lint.linters_by_ft[ft] = linters
end

-- Registro desde fichas de lenguaje (schema 002)
local ok_langs, languages = pcall(require, "languages")
if ok_langs then
  for _, ficha in ipairs(languages.all()) do
    for ft, linters in pairs(ficha.lint or {}) do
      M.register(ft, linters)
    end
  end
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
