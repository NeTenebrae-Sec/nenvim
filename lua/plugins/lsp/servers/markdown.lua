vim.lsp.config("marksman", {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".git", ".marksman.toml" },
})

vim.lsp.enable("marksman")
