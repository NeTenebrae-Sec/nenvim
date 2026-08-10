-- ============================================================================
-- NÚCLEO LSP GLOBAL
-- ============================================================================

-- lua/plugins/lsp/init.lua
require("plugins.lsp.java").setup()

-- PATH de Mason en el entorno Neovim
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Cargar gestión de binarios (Mason)
pcall(require, "plugins.lsp.mason")

-- Capabilities Globales
local capabilities = vim.lsp.protocol.make_client_capabilities()

local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if ok_cmp then
  capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
end

capabilities.textDocument.completion.completionItem.snippetSupport = true

if capabilities.workspace then
  capabilities.workspace.didChangeWatchedFiles = nil
end

-- Aplicar defaults para cualquier servidor en Nvim 0.12+
vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git" },
})

-- Configuración Global de Diagnósticos
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
      [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
      [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
      [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
    },
  },
})

-- Cargar Servidores Modularizados
local servers = {
  "web",
  "html",
  "python",
  "lua",
  "c",
  "markdown",
  "html_css",
}

for _, server in ipairs(servers) do
  pcall(require, "plugins.lsp.servers." .. server)
end

-- Desactivar LSP y diagnósticos en buffers especiales y no modificables
local lsp_ignore_group = vim.api.nvim_create_augroup("LspIgnoreSpecialBuffers", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = lsp_ignore_group,
  pattern = {
    "undotree",
    "diff",
    "qf",
    "noice",
    "notify",
    "lspinfo",
    "mason",
    "lazy",
    "checkhealth",
    "help",
    "man",
    "NvimTree",
    "neo-tree",
    "trouble",
  },
  callback = function(ev)
    local buf = ev.buf
    -- Desactivar diagnósticos explícitamente en el buffer especial
    vim.diagnostic.enable(false, { bufnr = buf })

    -- Detener/desconectar cualquier cliente LSP activo en este buffer
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      vim.lsp.buf_detach_client(buf, client.id)
    end
  end,
})
local lsp_trigger_group = vim.api.nvim_create_augroup("LspTriggerOnRename", { clear = true })

vim.api.nvim_create_autocmd("BufFilePost", {
  group = lsp_trigger_group,
  callback = function(ev)
    local buf = ev.buf
    local bufname = vim.api.nvim_buf_get_name(buf)
    if bufname == "" or not vim.bo[buf].modifiable then
      return
    end

    local detected_ft = vim.filetype.match({ filename = bufname })
    if detected_ft and detected_ft ~= vim.bo[buf].filetype then
      vim.bo[buf].filetype = detected_ft
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspSpecialBufferFilter", { clear = true }),
  callback = function(args)
    local buf = args.buf
    -- Si no es un buffer de archivo normal (ej: nofile, prompt, terminal, quickfix)
    if vim.bo[buf].buftype ~= "" then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        vim.lsp.buf_detach_client(buf, client.id)
      end
      return
    end

    -- Desactivar Semantic Tokens (resaltado de colores por LSP)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
