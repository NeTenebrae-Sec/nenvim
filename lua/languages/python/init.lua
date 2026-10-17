-- =========================================================
-- Ficha Python — basedpyright + ruff + black/isort
-- =========================================================

local M = {
  name = "python",
  filetypes = { "python" },

  lsp = {
    {
      name = "basedpyright",
      config = {
        cmd = { "basedpyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        handlers = {
          ["$/progress"] = function(err, result, ctx)
            if result.token == (vim.g.basedpyright_progress_token or result.token) then
              vim.g.basedpyright_progress_token = result.token
              vim.lsp.handlers["$/progress"](err, result, ctx)
            end
          end,
        },
        settings = {
          basedpyright = {
            disableTaggedHints = true,
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "basic",
            },
          },
        },
      },
    },
    {
      name = "ruff",
      config = {
        cmd = { "ruff", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      },
    },
  },

  format = { python = { "isort", "black" } },

  parsers = { "python" },

  tools = { "basedpyright", "ruff", "black", "isort" },

  dap = require("languages.python.dap"),
}

return M
