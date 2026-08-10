local M = {}

function M.organize_imports()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if ok_jdtls then
    jdtls.organize_imports()
  else
    vim.notify("JDTLS not active in this buffer", vim.log.levels.WARN)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaOrganizeImports", M.organize_imports, {
    desc = "Organize Java Imports using JDTLS",
  })
end

return M
