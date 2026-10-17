-- =========================================================
-- Ficha C/C++ — clangd + clang-format + codelldb
-- =========================================================

local M = {
  name = "c",
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },

  lsp = {
    {
      name = "clangd",
      config = {
        cmd = { "clangd" },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        root_markers = {
          ".clangd",
          ".clang-tidy",
          ".clang-format",
          "compile_commands.json",
          "compile_flags.txt",
          "configure.ac",
          ".git",
        },
      },
    },
  },

  format = {
    c = { "clang-format" },
    cpp = { "clang-format" },
  },

  parsers = { "c", "cpp" },

  tools = { "clangd", "clang-format", "codelldb" },

  -- run(): make + ejecuta en Kitty; setup(): codelldb + :CMakefileInit
  dap = require("languages.c.dap"),
}

return M
