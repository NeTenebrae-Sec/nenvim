local M = {}

--- Refresh JDTLS project configuration and rebuild workspace
---@param opts table|nil options: { silent = boolean } - silent=true suppresses notification
function M.refresh(opts)
  opts = opts or {}
  local silent = opts.silent == true

  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    if not silent then
      vim.notify("JDTLS is not active in this buffer", vim.log.levels.WARN, { title = "Java LSP" })
    end
    return
  end

  local clients = vim.lsp.get_clients({ name = "jdtls" })
  if #clients == 0 then
    if not silent then
      vim.notify("No JDTLS client attached to current buffer", vim.log.levels.WARN, { title = "Java LSP" })
    end
    return
  end

  pcall(jdtls.update_project_config)

  clients[1]:request("java/buildWorkspace", true, function(err, _)
    if not err and not silent then
      vim.notify("Workspace rebuilt successfully!", vim.log.levels.INFO, { title = "Java LSP" })
    end
  end)

  local current_buf = vim.api.nvim_get_current_buf()
  if vim.bo[current_buf].filetype == "java" then
    vim.cmd("silent! write")
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaRefresh", function()
    M.refresh({ silent = false })
  end, {
    desc = "Refresh JDTLS project configuration and rebuild workspace index",
  })
end

return M
