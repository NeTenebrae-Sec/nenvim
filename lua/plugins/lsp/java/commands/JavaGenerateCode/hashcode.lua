local M = {}

function M.handle(jdtls_client, target_buf, encoding)
  local range_params = vim.lsp.util.make_range_params(0, encoding)

  jdtls_client:request("java/checkHashCodeEqualsStatus", range_params, function(status_err, status_res)
    if status_err or not status_res then
      vim.notify("Could not check hashCode/equals status", vim.log.levels.WARN, { title = "Java LSP" })
      return
    end

    local fields = status_res.fields or {}
    if #fields == 0 then
      vim.notify("No fields available for hashCode/equals", vim.log.levels.INFO, { title = "Java LSP" })
      return
    end

    local selected_map = {}
    -- Seleccionar todos los campos por defecto
    for _, item in ipairs(fields) do
      selected_map[item.bindingKey or item.name] = true
    end

    local function show_menu()
      local options = { "=== [ CONFIRM & GENERATE HASHCODE/EQUALS ] ===" }

      for _, item in ipairs(fields) do
        local key = item.bindingKey or item.name
        local mark = selected_map[key] and "[X]" or "[ ]"
        table.insert(options, string.format("%s %s %s", mark, item.type or "", item.name))
      end

      vim.ui.select(options, {
        prompt = "Select Fields for hashCode() and equals():",
      }, function(choice)
        if not choice then
          return
        end

        if choice:find("%[ CONFIRM & GENERATE HASHCODE/EQUALS %]") then
          local selected_fields = {}
          for _, item in ipairs(fields) do
            local key = item.bindingKey or item.name
            if selected_map[key] then
              table.insert(selected_fields, item)
            end
          end

          local payload = {
            context = range_params,
            fields = selected_fields,
            regenerate = status_res.existingMethods and #status_res.existingMethods > 0 or false,
          }

          jdtls_client:request("java/generateHashCodeEquals", payload, function(gen_err, edit_res)
            if gen_err then
              vim.notify(
                "Error generating hashCode/equals: " .. tostring(gen_err.message or gen_err),
                vim.log.levels.ERROR,
                { title = "Java LSP" }
              )
              return
            end

            if edit_res then
              vim.schedule(function()
                vim.lsp.util.apply_workspace_edit(edit_res, encoding)
                vim.notify("hashCode() & equals() generated successfully!", vim.log.levels.INFO, { title = "Java LSP" })
              end)
            end
          end)
          return
        end

        for _, item in ipairs(fields) do
          if choice:find(item.name, 1, true) then
            local key = item.bindingKey or item.name
            selected_map[key] = not selected_map[key]
            break
          end
        end

        show_menu()
      end)
    end

    show_menu()
  end)
end

return M
