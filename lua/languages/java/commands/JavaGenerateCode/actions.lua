local M = {}

function M.apply(jdtls_client, target_buf, encoding, action)
  local function execute_action(act)
    if act.edit then
      vim.lsp.util.apply_workspace_edit(act.edit, encoding)
    end

    if act.command then
      local cmd = type(act.command) == "table" and act.command or act
      jdtls_client:exec_cmd(cmd, { bufnr = target_buf })
    end
  end

  if
    not action.edit
    and not action.command
    and jdtls_client:supports_method("codeAction/resolve", { bufnr = target_buf })
  then
    jdtls_client:request("codeAction/resolve", action, function(resolve_err, resolved_action)
      if resolve_err or not resolved_action then
        vim.schedule(function()
          execute_action(action)
        end)
        return
      end
      vim.schedule(function()
        execute_action(resolved_action)
      end)
    end, target_buf)
  else
    vim.schedule(function()
      execute_action(action)
    end)
  end
end

return M
