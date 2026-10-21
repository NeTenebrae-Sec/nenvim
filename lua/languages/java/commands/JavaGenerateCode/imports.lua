local M = {}

function M.handle()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    vim.notify("JDTLS client is not active", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  local clients = vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })
  if #clients == 0 then
    vim.notify("JDTLS not attached to this buffer", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  jdtls.organize_imports()
end

return M
