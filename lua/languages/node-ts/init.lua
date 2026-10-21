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
        -- Guard anti-rogue (spec 002 F3): requiere manifiesto node
        -- (tsconfig/jsconfig/package.json). Un .ts suelto en un repo
        -- sin package.json no arranca vtsls (antes bastaba .git).
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, { "tsconfig.json", "jsconfig.json", "package.json" })
          if root then
            on_dir(root)
          end
        end,
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
