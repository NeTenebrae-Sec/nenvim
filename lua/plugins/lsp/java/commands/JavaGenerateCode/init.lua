local M = {}

local override_handler = require("plugins.lsp.java.commands.JavaGenerateCode.override")
local constructor_handler = require("plugins.lsp.java.commands.JavaGenerateCode.constructor")
local tostring_handler = require("plugins.lsp.java.commands.JavaGenerateCode.tostring")
local hashcode_handler = require("plugins.lsp.java.commands.JavaGenerateCode.hashcode")
local imports_handler = require("plugins.lsp.java.commands.JavaGenerateCode.imports")
local actions_handler = require("plugins.lsp.java.commands.JavaGenerateCode.actions")

function M.execute()
  local target_buf = vim.api.nvim_get_current_buf()

  local clients = vim.lsp.get_clients({ bufnr = target_buf, name = "jdtls" })
  if #clients == 0 then
    vim.notify("nvim-jdtls is not active in this buffer", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  local jdtls_client = clients[1]
  local encoding = jdtls_client.offset_encoding or "utf-16"

  local params = vim.lsp.util.make_range_params(0, encoding)
  params.context = {
    diagnostics = vim.diagnostic.get(target_buf, { lnum = vim.fn.line(".") - 1 }),
  }

  jdtls_client:request("textDocument/codeAction", params, function(err, result, _)
    if err or not result or vim.tbl_isempty(result) then
      vim.notify("No code actions available", vim.log.levels.INFO, { title = "Java LSP" })
      return
    end

    local seen_titles = {}
    local unique_actions = {}

    for _, action in ipairs(result) do
      local title = action.title or (action.action and action.action.title)
      if title and not seen_titles[title] then
        seen_titles[title] = true
        table.insert(unique_actions, action)
      end
    end

    vim.ui.select(unique_actions, {
      prompt = "Java Code Actions:",
      format_item = function(action)
        return action.title or action.action.title
      end,
    }, function(selected_action)
      if not selected_action then
        return
      end

      local title = (selected_action.title or (selected_action.action and selected_action.action.title) or ""):lower()

      -- Ruteo condicional según la acción seleccionada
      if title:find("import") then
        imports_handler.handle()
      elseif title:find("override") or title:find("implement") then
        override_handler.handle(jdtls_client, target_buf, encoding)
      elseif title:find("constructor") then
        constructor_handler.handle(jdtls_client, target_buf, encoding)
      elseif title:find("tostring") then
        tostring_handler.handle(jdtls_client, target_buf, encoding)
      elseif title:find("hashcode") or title:find("equals") then
        hashcode_handler.handle(jdtls_client, target_buf, encoding)
      else
        actions_handler.apply(jdtls_client, target_buf, encoding, selected_action)
      end
    end)
  end, target_buf)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaGenerateCode", function()
    M.execute()
  end, { desc = "Generate Java code using interactive menus" })
end

return M
