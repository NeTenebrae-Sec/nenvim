-- =========================================================
-- Ficha Node/TS — vtsls + oxlint + prettier (web module)
-- =========================================================
-- El módulo format es el "web module" de prettier: su formatters_by_ft
-- cubre también fts de otras fichas (astro, html, css, vue, svelte,
-- json, yaml) — prettier es una tool node y se define una sola vez.

local M = {
  name = "node-ts",
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },

  lsp = {
    {
      name = "vtsls",
      config = {
        cmd = { "vtsls", "--stdio" },
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
        settings = {
          typescript = {
            suggest = { completeFunctionCalls = true },
            preferences = {
              importModuleSpecifier = "shortest",
              includeCompletionsForModuleExports = true,
              includeCompletionsWithInsertText = true,
            },
          },
          javascript = {
            suggest = { completeFunctionCalls = true },
            preferences = {
              importModuleSpecifier = "shortest",
              includeCompletionsForModuleExports = true,
              includeCompletionsWithInsertText = true,
            },
          },
          vtsls = {
            autoUseWorkspaceTsdk = true,
            experimental = { completion = { enableServerSideFuzzyMatch = true } },
          },
        },
        -- El formateo lo gestiona conform (prettier), no el LSP
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      },
    },
  },

  lint = {
    javascript = { "oxlint" },
    typescript = { "oxlint" },
    javascriptreact = { "oxlint" },
    typescriptreact = { "oxlint" },
  },

  parsers = { "javascript", "typescript", "tsx" },

  tools = { "vtsls", "oxlint", "prettier", "js-debug-adapter" },

  dap = require("languages.node-ts.dap"),

  format_modules = { "languages.node-ts.format" },
}

-- Side effect: comando :Jsconfig
pcall(require, "languages.node-ts.jsconfig")

return M
