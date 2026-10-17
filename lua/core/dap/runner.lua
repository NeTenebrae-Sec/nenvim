-- =========================================================
-- Motor DAP > runner: <leader>dr (detección → ficha del lenguaje)
-- =========================================================
-- Resuelve run() desde el campo `dap` de las fichas de languages/,
-- matcheando el filetype contra `dap.filetypes` (o `filetypes` de la
-- ficha). Resolución determinista cuando varias fichas cubren el mismo
-- ft (p. ej. react/nextjs sobre jsx/tsx): gana la ficha cuyo
-- `dap.detect()` confirma el proyecto con mayor `dap.priority`
-- (mayor = más específico; next=20 sobre react=10); sin detect, la
-- primera.

local M = {}

function M.run_current_file()
  local ft = vim.bo.filetype

  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    local fallback, best, best_priority
    for _, ficha in ipairs(languages.all()) do
      local dap = ficha.dap
      local fts = (dap and dap.filetypes) or ficha.filetypes or {}
      if dap and type(dap.run) == "function" and vim.tbl_contains(fts, ft) then
        -- Cualquier run() matcheado sirve de fallback (react/next degradan
        -- a `node <archivo>` cuando detect() es false, p. ej. archivos sueltos)
        fallback = fallback or dap.run
        if type(dap.detect) == "function" then
          local ok_d, detected = pcall(dap.detect)
          local priority = dap.priority or 10
          if ok_d and detected and (not best or priority > (best_priority or 0)) then
            best, best_priority = dap.run, priority
          end
        end
      end
    end
    if best then
      return best()
    end
    if fallback then
      return fallback()
    end
  end

  vim.notify("No hay runner DAP para filetype: " .. ft, vim.log.levels.WARN)
end

return M
