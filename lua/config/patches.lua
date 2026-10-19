-- =========================================================
-- Parches de plugins de terceros (config propietaria)
-- =========================================================

-- nvim-html-css re-parsea el buffer ENTERO en cada BufEnter y BufWritePre
-- (abrir y guardar) con un parser superlineal: ~4 s en un HTML de 12k
-- líneas (medido; ver specs/tasks/003-rendimiento.md). Guard por tamaño:
-- en buffers grandes se omite su parse y queda sin completado de clases
-- de ESTE plugin; el resto (html-css-lsp, buffers pequeños) intacto.
-- shortcut: >2000 líneas o >512 KB sin fuentes de clases de html-css;
-- subir el umbral o esperar un fix async upstream. Por líneas no basta:
-- un DOM guardado de 1.5 MB en 851 líneas congelaba 1.6 s por parse.
local patched = false

vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("NvimPatches", { clear = true }),
  callback = function()
    if patched then
      return
    end
    -- Los start-packages ya cargaron en este punto; si el plugin no existe,
    -- se reintenta en el próximo read (pcall, sin romper nada)
    local ok, parsers = pcall(require, "html-css.parsers.html")
    if not ok then
      return
    end

    local orig = parsers.setup
    parsers.setup = function(bufnr)
      local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
      if vim.api.nvim_buf_line_count(bufnr) > 2000 or size > 512 * 1024 then
        return { cdn = {}, raw_text = {} }
      end
      return orig(bufnr)
    end
    patched = true
  end,
})
