vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
  single_file_support = true,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        pathStrict = true,
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        checkThirdParty = false,
        maxPreload = 100,
        preloadFileSize = 1000,
        library = {},
      },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.enable("lua_ls")
