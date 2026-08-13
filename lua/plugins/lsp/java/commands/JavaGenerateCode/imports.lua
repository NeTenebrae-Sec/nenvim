local M = {}

function M.handle()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    vim.notify("JDTLS client is not active", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  -- Ejecución vanilla y estándar proveida por nvim-jdtls
  jdtls.organize_imports()
end

return M
