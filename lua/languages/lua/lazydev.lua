-- ============================================================================
-- LAZYDEV (Forzar carga antes que los servidores)
-- ============================================================================
local ok_lazydev, lazydev = pcall(require, "lazydev")
if ok_lazydev then
  lazydev.setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
  })
else
  vim.notify("lazydev no se pudo cargar", vim.log.levels.WARN)
end
