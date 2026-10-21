-- =========================================================
-- Ficha Lua — lua_ls + lazydev + stylua
-- =========================================================

local M = {
  name = "lua",
  filetypes = { "lua" },

  lsp = {
    {
      name = "lua_ls",
      config = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
        single_file_support = true,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT", pathStrict = true },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              maxPreload = 100,
              preloadFileSize = 1000,
              library = {},
            },
            telemetry = { enable = false },
          },
        },
      },
    },
  },

  -- "lua" ya está en la base de parsers del motor treesitter
  tools = { "lua-language-server", "stylua" },

  format_modules = { "languages.lua.format" },
}

-- Side effect: lazydev (biblioteca vim/.uv para la completación)
pcall(require, "languages.lua.lazydev")

return M
