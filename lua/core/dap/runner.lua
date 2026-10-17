-- =========================================================
-- Motor DAP > runner: <leader>dr (detección → ficha del lenguaje)
-- =========================================================
-- Resuelve run() desde el campo `dap` de las fichas de languages/,
-- matcheando el filetype actual contra `filetypes` de cada ficha.

local M = {}

function M.run_current_file()
  local ft = vim.bo.filetype

  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    for _, ficha in ipairs(languages.all()) do
      if ficha.dap and type(ficha.dap.run) == "function" and vim.tbl_contains(ficha.filetypes or {}, ft) then
        return ficha.dap.run()
      end
    end
  end

  vim.notify("No hay runner DAP para filetype: " .. ft, vim.log.levels.WARN)
end

return M
