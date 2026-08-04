-- Basedpyright
vim.lsp.config("basedpyright", {
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
})

-- Ruff
vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
})

vim.lsp.enable({ "basedpyright", "ruff" })
