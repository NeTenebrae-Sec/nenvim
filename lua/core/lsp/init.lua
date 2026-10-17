-- =========================================================
-- Motor LSP: capabilities globales + habilitación desde fichas
-- =========================================================
-- Diagnósticos y guards viven en sus sub-núcleos. Los servers se
-- definen hoy en plugins/lsp/servers/* (temporal hasta F2 de la 002);
-- las fichas de languages/ se registran aquí automáticamente.

local M = {}

local capabilities = vim.lsp.protocol.make_client_capabilities()

local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

capabilities.textDocument.completion.completionItem.snippetSupport = true

if capabilities.workspace then
  capabilities.workspace.didChangeWatchedFiles = nil
end

M.capabilities = capabilities

-- Defaults para cualquier servidor (Neovim 0.12+)
vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git" },
})

require("core.lsp.diagnostics")
require("core.lsp.guards")

-- Registro desde fichas de lenguaje (schema 002). Lista vacía en F0.
local ok_langs, languages = pcall(require, "languages")
if ok_langs then
  for _, ficha in ipairs(languages.all()) do
    for _, server in ipairs(ficha.lsp or {}) do
      if type(server) == "table" and server.name and server.config then
        pcall(vim.lsp.config, server.name, server.config)
        vim.lsp.enable(server.name)
      end
    end
  end
end

return M
