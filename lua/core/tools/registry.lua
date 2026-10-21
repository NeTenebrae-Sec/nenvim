-- =========================================================
-- Tools engine > registry: install recipes per tool
-- =========================================================
-- Maps a tool name (as declared in a language card's `tools` list)
-- to its install recipe. Versions are pinned to releases proven to
-- work on linux x86_64; bump them by hand when updating a recipe.
--
-- Recipe shapes:
--   { method = "npm",  pkg = "@scope/name@1.2.3", bins = { ... } }
--   { method = "pip",  pkg = "name==1.2.3",       bins = { ... } }
--   { method = "github", url|dir, extract, strip, bins, links, pkg_wrappers }
--     url    direct download URL of the archive
--     dir    base dir holding a latest.txt with the archive filename
--            (eclipse-style; resolved at install time)
--     extract "tar.gz" | "zip" | "gz" | "raw"
--     strip  flatten a single top-level dir after extraction
--     links  bin name -> path relative to the package dir
--     pkg_wrappers  script name (inside the package dir) ->
--                   { interpreter, target path relative to the package dir }
--                   (some language cards exec a script inside the package
--                   dir instead of a PATH bin)

local M = {}

M.recipes = {
  -- npm ------------------------------------------------------
  ["astro-language-server"] = { method = "npm", pkg = "@astrojs/language-server@2.17.2", bins = { "astro-ls" } },
  ["typescript-language-server"] = {
    method = "npm",
    -- typescript is not a dependency of the server: pin it so the tsdk
    -- path used by astro-ls exists
    pkg = "typescript-language-server@6.0.2 typescript@5.9.3",
    bins = { "typescript-language-server" },
  },
  ["vtsls"] = { method = "npm", pkg = "@vtsls/language-server@0.3.0", bins = { "vtsls" } },
  ["oxlint"] = { method = "npm", pkg = "oxlint@1.88.0", bins = { "oxlint" } },
  ["prettier"] = { method = "npm", pkg = "prettier@3.9.10", bins = { "prettier" } },
  ["yaml-language-server"] = { method = "npm", pkg = "yaml-language-server@1.25.0", bins = { "yaml-language-server" } },
  ["emmet-language-server"] =
    { method = "npm", pkg = "@olrtg/emmet-language-server@2.8.0", bins = { "emmet-language-server" } },
  ["tailwindcss-language-server"] =
    { method = "npm", pkg = "@tailwindcss/language-server@0.16.0", bins = { "tailwindcss-language-server" } },
  ["markdownlint"] = { method = "npm", pkg = "markdownlint-cli@0.49.1", bins = { "markdownlint" } },
  ["markuplint"] = { method = "npm", pkg = "markuplint@5.2.0", bins = { "markuplint" } },
  ["stylelint"] = { method = "npm", pkg = "stylelint@17.16.0", bins = { "stylelint" } },
  ["svelte-language-server"] =
    { method = "npm", pkg = "svelte-language-server@0.18.4", bins = { "svelteserver" } },
  ["vue-language-server"] = { method = "npm", pkg = "@vue/language-server@3.3.13", bins = { "vue-language-server" } },
  ["sqlls"] = { method = "npm", pkg = "sql-language-server@1.7.1", bins = { "sql-language-server" } },
  ["html-lsp"] = { method = "npm", pkg = "vscode-langservers-extracted@4.10.0", bins = { "vscode-html-language-server" } },
  ["css-lsp"] = { method = "npm", pkg = "vscode-langservers-extracted@4.10.0", bins = { "vscode-css-language-server" } },
  ["json-lsp"] = { method = "npm", pkg = "vscode-langservers-extracted@4.10.0", bins = { "vscode-json-language-server" } },

  -- pip (own venv per tool) ----------------------------------
  ["black"] = { method = "pip", pkg = "black==26.10.1", bins = { "black" } },
  ["isort"] = { method = "pip", pkg = "isort==9.0.2", bins = { "isort" } },
  ["sqlfluff"] = { method = "pip", pkg = "sqlfluff==4.4.0", bins = { "sqlfluff" } },
  ["mdformat"] = { method = "pip", pkg = "mdformat==1.0.0", bins = { "mdformat" } },
  ["basedpyright"] = { method = "pip", pkg = "basedpyright==1.40.2", bins = { "basedpyright", "basedpyright-langserver" } },
  ["clang-format"] = { method = "pip", pkg = "clang-format==23.1.3", bins = { "clang-format" } },

  -- github / openvsx releases --------------------------------
  ["clangd"] = {
    method = "github",
    url = "https://github.com/clangd/clangd/releases/download/23.1.0/clangd-linux-23.1.0.zip",
    extract = "zip",
    strip = true,
    bins = { "clangd" },
    links = { clangd = "bin/clangd" },
  },
  ["codelldb"] = {
    method = "github",
    url = "https://github.com/vadimcn/vscode-lldb/releases/download/v1.12.3/codelldb-linux-x64.vsix",
    extract = "zip",
    bins = { "codelldb" },
    links = { codelldb = "extension/adapter/codelldb" },
  },
  ["jdtls"] = {
    method = "github",
    dir = "https://download.eclipse.org/jdtls/milestones/1.61.0/",
    extract = "tar.gz",
    strip = true,
    bins = { "jdtls" },
    links = { jdtls = "bin/jdtls" },
  },
  ["java-debug-adapter"] = {
    method = "github",
    url = "https://open-vsx.org/api/vscjava/vscode-java-debug/0.59.0/file/vscjava.vscode-java-debug-0.59.0.vsix",
    extract = "zip",
    bins = {},
  },
  ["java-test"] = {
    method = "github",
    url = "https://open-vsx.org/api/vscjava/vscode-java-test/0.46.0/file/vscjava.vscode-java-test-0.46.0.vsix",
    extract = "zip",
    bins = {},
  },
  -- No bin exposed on purpose: the springboot LSP stays disabled behind
  -- its executable guard until the card opts in (same as before).
  ["vscode-spring-boot-tools"] = {
    method = "github",
    url = "https://open-vsx.org/api/VMware/vscode-spring-boot/2.2.0/file/VMware.vscode-spring-boot-2.2.0.vsix",
    extract = "zip",
    bins = {},
  },
  ["lua-language-server"] = {
    method = "github",
    url = "https://github.com/luals/lua-language-server/releases/download/3.19.2/lua-language-server-3.19.2-linux-x64.tar.gz",
    extract = "tar.gz",
    strip = true,
    bins = { "lua-language-server" },
    links = { ["lua-language-server"] = "bin/lua-language-server" },
  },
  ["js-debug-adapter"] = {
    method = "github",
    url = "https://github.com/microsoft/vscode-js-debug/releases/download/v1.140.0/js-debug-dap-v1.140.0.tar.gz",
    extract = "tar.gz",
    -- archive already unpacks into js-debug/, which is the layout the card expects
    bins = { "js-debug-adapter" },
    pkg_wrappers = { ["js-debug-adapter"] = { "node", "js-debug/src/dapDebugServer.js" } },
    links = { ["js-debug-adapter"] = "js-debug-adapter" },
  },
  ["bash-debug-adapter"] = {
    method = "github",
    url = "https://github.com/rogalmic/vscode-bash-debug/releases/download/untagged-438733f35feb8659d939/bash-debug-0.3.9.vsix",
    extract = "zip",
    bins = { "bash-debug-adapter" },
    pkg_wrappers = { ["bash-debug-adapter"] = { "node", "extension/out/bashDebug.js" } },
    links = { ["bash-debug-adapter"] = "bash-debug-adapter" },
  },
  ["google-java-format"] = {
    method = "github",
    url = "https://github.com/google/google-java-format/releases/download/v1.37.0/google-java-format_linux-x86-64",
    extract = "raw",
    bins = { "google-java-format" },
    links = { ["google-java-format"] = "google-java-format_linux-x86-64" },
  },
  ["marksman"] = {
    method = "github",
    url = "https://github.com/artempyanykh/marksman/releases/download/2026-02-08/marksman-linux-x64",
    extract = "raw",
    bins = { "marksman" },
    links = { marksman = "marksman-linux-x64" },
  },
  ["postgres-language-server"] = {
    method = "github",
    url = "https://github.com/supabase-community/postgres-language-server/releases/download/0.28.2/postgres-language-server_x86_64-unknown-linux-gnu",
    extract = "raw",
    bins = { "postgres-language-server" },
    links = { ["postgres-language-server"] = "postgres-language-server_x86_64-unknown-linux-gnu" },
  },
  ["ruff"] = {
    method = "github",
    url = "https://github.com/astral-sh/ruff/releases/download/0.17.1/ruff-x86_64-unknown-linux-musl.tar.gz",
    extract = "tar.gz",
    strip = true,
    bins = { "ruff" },
    links = { ruff = "ruff" },
  },
  ["shfmt"] = {
    method = "github",
    url = "https://github.com/mvdan/sh/releases/download/v3.14.1/shfmt_v3.14.1_linux_amd64",
    extract = "raw",
    bins = { "shfmt" },
    links = { shfmt = "shfmt_v3.14.1_linux_amd64" },
  },
  ["stylua"] = {
    method = "github",
    url = "https://github.com/johnnymorganz/stylua/releases/download/v2.6.0/stylua-linux-x86_64.zip",
    extract = "zip",
    strip = true,
    bins = { "stylua" },
    links = { stylua = "stylua" },
  },
  ["taplo"] = {
    method = "github",
    url = "https://github.com/tamasfe/taplo/releases/download/0.10.0/taplo-linux-x86_64.gz",
    extract = "gz",
    bins = { "taplo" },
    links = { taplo = "taplo-linux-x86_64" },
  },
}

return M
