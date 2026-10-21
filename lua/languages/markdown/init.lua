-- =========================================================
-- Ficha Markdown — marksman + markdownlint + mdformat
-- =========================================================
-- "markdown"/"markdown_inline" ya están en la base de parsers del motor.

local M = {
  name = "markdown",
  filetypes = { "markdown", "markdown.mdx" },

  lsp = {
    {
      name = "marksman",
      config = {
        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".git", ".marksman.toml" },
      },
    },
  },

  lint = { markdown = { "markdownlint" } },

  tools = { "marksman", "markdownlint", "mdformat" },

  format_modules = { "languages.markdown.format" },
}

return M
