local M = {}

function M.handle(jdtls_client, target_buf, encoding)
  local range_params = vim.lsp.util.make_range_params(0, encoding)

  jdtls_client:request("java/listOverridableMethods", range_params, function(list_err, overridable_methods)
    if list_err or not overridable_methods or vim.tbl_isempty(overridable_methods.methods or {}) then
      vim.notify("No overridable methods found", vim.log.levels.INFO)
      return
    end

    local available_methods = overridable_methods.methods
    local selected_map = {}

    local function show_override_menu()
      local options = { "=== [ CONFIRM & OVERRIDE METHODS ] ===" }

      for _, method in ipairs(available_methods) do
        local mark = selected_map[method.key or method.bindingKey or method.name] and "[X]" or "[ ]"
        local params_str = table.concat(method.parameters or {}, ", ")
        local label = string.format(
          "%s %s %s(%s) - [%s]",
          mark,
          method.returnType or "void",
          method.name,
          params_str,
          method.declaringClass or ""
        )
        table.insert(options, label)
      end

      vim.ui.select(options, {
        prompt = "Toggle Methods to Override (Select top item when done):",
      }, function(choice)
        if not choice then
          return
        end

        if choice:find("%[ CONFIRM & OVERRIDE METHODS %]") then
          local methods_to_add = {}
          for _, method in ipairs(available_methods) do
            local key = method.key or method.bindingKey or method.name
            if selected_map[key] then
              table.insert(methods_to_add, method)
            end
          end

          if #methods_to_add == 0 then
            vim.notify("No methods selected", vim.log.levels.WARN)
            return
          end

          jdtls_client:request("java/addOverridableMethods", {
            context = range_params,
            overridableMethods = methods_to_add,
          }, function(add_err, edit_res)
            if add_err then
              vim.notify("Error adding methods: " .. tostring(add_err.message or add_err), vim.log.levels.ERROR)
              return
            end

            if edit_res then
              vim.schedule(function()
                vim.lsp.util.apply_workspace_edit(edit_res, encoding)
                vim.notify(#methods_to_add .. " method(s) generated!", vim.log.levels.INFO)
              end)
            end
          end)
          return
        end

        for _, method in ipairs(available_methods) do
          local params_str = table.concat(method.parameters or {}, ", ")
          local expected_label = string.format("%s(%s) - [%s]", method.name, params_str, method.declaringClass or "")
          if choice:find(expected_label, 1, true) then
            local key = method.key or method.bindingKey or method.name
            selected_map[key] = not selected_map[key]
            break
          end
        end

        show_override_menu()
      end)
    end

    show_override_menu()
  end)
end

return M
