-- =========================================================
-- Motor Mason: instalación de binarios declarados
-- =========================================================
-- auto_update=false: sin checks de red en cada arranque (specs/tasks/003).
-- Updates manuales: :MasonToolsUpdate.
-- En F2 (spec 002) la lista `ensure_installed` se absorbe desde los
-- campos `tools` de las fichas de languages/.

local ok_mason, mason = pcall(require, "mason")
if not ok_mason then
  -- R0: sin mason la config sigue arrancando; los binarios se instalan
  -- cuando haya plugin y red (:PackUpdate)
  vim.notify("mason.nvim no está instalado (se omiten binarios LSP)", vim.log.levels.WARN)
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
      "sqlls",
      "postgres-language-server",
      "sqlfluff",
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
    auto_update = false,
  })
end
