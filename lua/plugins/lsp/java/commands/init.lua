local M = {}

function M.setup()
  -- JavaInit
  local ok_init, java_init = pcall(require, "plugins.lsp.java.commands.JavaInit")
  if ok_init and type(java_init.setup) == "function" then
    java_init.setup()
  end

  -- JavaNewFile
  local ok_newfile, java_newfile = pcall(require, "plugins.lsp.java.commands.JavaNewFile")
  if ok_newfile and type(java_newfile.setup) == "function" then
    java_newfile.setup()
  end

  -- JavaOrganizeImports
  local ok_org, java_org = pcall(require, "plugins.lsp.java.commands.JavaOrganizeImports")
  if ok_org and type(java_org.setup) == "function" then
    java_org.setup()
  end

  -- JavaGenerateCode
  local ok_gen, java_gen = pcall(require, "plugins.lsp.java.commands.JavaGenerateCode")
  if ok_gen and type(java_gen.setup) == "function" then
    java_gen.setup()
  end
end

return M
