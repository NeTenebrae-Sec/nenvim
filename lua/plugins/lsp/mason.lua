local ok_mason, mason = pcall(require, "mason")
if not ok_mason then
  vim.notify("mason.nvim no está instalado", vim.log.levels.ERROR)
  return
end

mason.setup({
  ui = {
    border = "rounded",
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

local ok_mti, mti = pcall(require, "mason-tool-installer")
if ok_mti then
  mti.setup({
    ensure_installed = {
      -- LSPs
      "astro-language-server",
      "bash-language-server",
      "clangd",
      "css-lsp",
      "emmet-language-server",
      "html-lsp",
      "json-lsp",
      "lua-language-server",
      "marksman",
      "prisma-language-server",
      "basedpyright",
      "svelte-language-server",
      "tailwindcss-language-server",
      "taplo",
      "vue-language-server",
      "vtsls",
      "yaml-language-server",
      "typescript-language-server",
      -- Formatters & Linters
      "markuplint",
      "oxlint",
      "prettier",
      "prettierd",
      "stylua",
      "black",
      "isort",
      "ruff",
      "shfmt",
      "clang-format",
      "shellcheck",
      "markdownlint",
      "stylelint",
      "mdformat",
      -- DAP
      "bash-debug-adapter",
      "codelldb",
      "debugpy",
      "js-debug-adapter",
      "jdtls",
      "java-debug-adapter",
      "java-test",
      "vscode-spring-boot-tools",
    },
    run_on_start = true,
    auto_update = true,
  })
end
