-- =========================================================
-- Motor LSP > guards: filtros de attach y buffers especiales
-- =========================================================

-- Sin LSP ni diagnósticos en buffers especiales/no modificables
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
    vim.diagnostic.enable(false, { bufnr = buf })

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      vim.lsp.buf_detach_client(buf, client.id)
    end
  end,
})

-- Detach de clientes en buffers no-normales (buftype ~= "") y sin
-- semantic tokens (el resaltado lo lleva treesitter)
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
    if vim.bo[buf].buftype ~= "" then
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        vim.lsp.buf_detach_client(buf, client.id)
      end
      return
    end

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end,
})
