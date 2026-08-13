local M = {}

-- Cache en memoria para no saturar la API
local cached_dependencies = nil

--- Fetchea la metadata oficial de start.spring.io
local function fetch_spring_dependencies(callback)
  if cached_dependencies then
    callback(cached_dependencies)
    return
  end

  vim.notify("Fetching metadata from Spring Initializr...", vim.log.levels.INFO)

  local cmd = "curl -sH 'Accept: application/vnd.initializr.v2.1+json' https://start.spring.io/metadata/client"

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then
        return
      end
      local raw_json = table.concat(data, "")
      local ok, parsed = pcall(vim.json.decode, raw_json)

      if ok and parsed and parsed.dependencies and parsed.dependencies.values then
        local deps_list = {}
        for _, category in ipairs(parsed.dependencies.values) do
          local cat_name = category.name or "Other"
          if category.values then
            for _, dep in ipairs(category.values) do
              table.insert(deps_list, {
                id = dep.id,
                name = string.format("[%s] %s", cat_name, dep.name),
                description = dep.description or "",
              })
            end
          end
        end
        cached_dependencies = deps_list
        callback(deps_list)
      else
        callback(nil)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and not cached_dependencies then
        vim.notify("Failed to fetch Spring metadata. Check your connection.", vim.log.levels.WARN)
        callback(nil)
      end
    end,
  })
end

--- Selector UI multi-opción
function M.select_dependencies(callback)
  fetch_spring_dependencies(function(available_deps)
    -- Fallback si no hay conexión a internet
    if not available_deps or #available_deps == 0 then
      available_deps = {
        { id = "web", name = "[Web] Spring Web" },
        { id = "devtools", name = "[Developer Tools] Spring Boot DevTools" },
        { id = "lombok", name = "[Developer Tools] Lombok" },
        { id = "data-jpa", name = "[SQL] Spring Data JPA" },
        { id = "h2", name = "[SQL] H2 Database" },
      }
    end

    local selected = {}

    local function show_menu()
      local options = { "=== [ CONFIRM & GENERATE PROJECT ] ===" }

      for _, dep in ipairs(available_deps) do
        local mark = selected[dep.id] and "[X]" or "[ ]"
        table.insert(options, string.format("%s %s", mark, dep.name))
      end

      vim.ui.select(options, {
        prompt = "Toggle Spring Boot Dependencies (Select top item when done):",
      }, function(choice)
        if not choice then
          callback("")
          return
        end

        if choice:find("%[ CONFIRM & GENERATE PROJECT %]") then
          local final_deps = {}
          for dep_id, is_selected in pairs(selected) do
            if is_selected then
              table.insert(final_deps, dep_id)
            end
          end
          callback(table.concat(final_deps, ","))
          return
        end

        for _, dep in ipairs(available_deps) do
          if choice:find(dep.name, 1, true) then
            selected[dep.id] = not selected[dep.id]
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
