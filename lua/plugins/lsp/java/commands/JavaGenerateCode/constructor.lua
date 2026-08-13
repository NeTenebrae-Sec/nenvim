local M = {}

function M.handle(jdtls_client, target_buf, encoding)
  local range_params = vim.lsp.util.make_range_params(0, encoding)

  jdtls_client:request("java/checkConstructorsStatus", range_params, function(status_err, status_res)
    if status_err or not status_res then
      vim.notify("Could not check constructor status", vim.log.levels.WARN)
      return
    end

    local fields = status_res.fields or {}
    local constructors = status_res.constructors or {}

    local function select_fields_and_generate(selected_super_constructor)
      local selected_fields_map = {}

      local function show_fields_menu()
        local options = { "=== [ CONFIRM & GENERATE CONSTRUCTOR ] ===" }

        for _, field in ipairs(fields) do
          local mark = selected_fields_map[field.bindingKey or field.name] and "[X]" or "[ ]"
          table.insert(options, string.format("%s %s %s", mark, field.type or "", field.name))
        end

        vim.ui.select(options, {
          prompt = "Step 2: Select Local Fields for Automovil (Select top item when done):",
        }, function(choice)
          if not choice then
            return
          end

          if choice:find("%[ CONFIRM & GENERATE CONSTRUCTOR %]") then
            local selected_fields = {}
            for _, field in ipairs(fields) do
              local key = field.bindingKey or field.name
              if selected_fields_map[key] then
                table.insert(selected_fields, field)
              end
            end

            local payload = {
              context = range_params,
              constructors = selected_super_constructor and { selected_super_constructor } or {},
              fields = selected_fields,
            }

            jdtls_client:request("java/generateConstructors", payload, function(gen_err, edit_res)
              if gen_err then
                vim.notify(
                  "Error generating constructor: " .. tostring(gen_err.message or gen_err),
                  vim.log.levels.ERROR
                )
                return
              end

              if edit_res then
                vim.schedule(function()
                  vim.lsp.util.apply_workspace_edit(edit_res, encoding)
                  vim.notify("Constructor generated successfully!", vim.log.levels.INFO)
                end)
              else
                vim.notify("No changes returned by language server", vim.log.levels.WARN)
              end
            end)
            return
          end

          for _, field in ipairs(fields) do
            if choice:find(field.name, 1, true) then
              local key = field.bindingKey or field.name
              selected_fields_map[key] = not selected_fields_map[key]
              break
            end
          end

          show_fields_menu()
        end)
      end

      show_fields_menu()
    end

    -- Paso 1: Elegir el constructor de la Superclase (super)
    if #constructors > 0 then
      local super_options = {}

      for _, ctor in ipairs(constructors) do
        local params_list = {}
        for idx, param in ipairs(ctor.parameters or {}) do
          local param_type = type(param) == "string" and param or (param.type or "Object")

          -- Asignamos nombres sugeridos legibles según tipo de dato
          local param_name = "param" .. idx
          if param_type == "String" then
            param_name = "str" .. idx
          elseif param_type == "int" or param_type == "double" or param_type == "float" then
            param_name = "num" .. idx
          end

          table.insert(params_list, string.format("%s %s", param_type, param_name))
        end

        local signature = #params_list > 0 and table.concat(params_list, ", ") or "vacío / default"
        local label = string.format("%s(%s)", ctor.name or "super", signature)
        table.insert(super_options, label)
      end

      vim.ui.select(super_options, {
        prompt = "Step 1: Select Superclass Constructor Signature to call:",
      }, function(choice, idx)
        if not choice or not idx then
          return
        end
        select_fields_and_generate(constructors[idx])
      end)
    else
      select_fields_and_generate(nil)
    end
  end)
end

return M
