local M = {}

function M.refresh()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    vim.notify("JDTLS is not active in this buffer", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  -- 1. Force JDTLS to update project configurations (pom.xml / build.gradle)
  pcall(jdtls.update_project_config)

  -- 2. Trigger workspace build RPC request
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })
  if #clients > 0 then
    clients[1]:request("java/buildWorkspace", true, function(err, _)
      if not err then
        vim.notify("Workspace rebuilt successfully!", vim.log.levels.INFO, { title = "Java LSP" })
      end
    end)
  end

  -- 3. Touch current buffer to force diagnostics re-evaluation
  local current_buf = vim.api.nvim_get_current_buf()
  if vim.bo[current_buf].filetype == "java" then
    vim.cmd("silent! write")
  end
end

function M.setup()
  vim.api.nvim_create_user_command("JavaRefresh", function()
    M.refresh()
  end, {
    desc = "Refresh JDTLS project configuration and rebuild workspace index",
  })
end

return M
