local M = {}

function M.execute()
  local ok, _ = pcall(require, "jdtls")
  if ok then
    -- Despliega las acciones de código de JDTLS (Getters, Setters, Constructors, etc.)
    vim.lsp.buf.code_action()
  else
    vim.notify("nvim-jdtls is not active", vim.log.levels.WARN)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaGenerateCode", function()
    M.execute()
  end, { desc = "Generate Java code (Getters, Setters, Constructors, etc.)" })
end

return M
