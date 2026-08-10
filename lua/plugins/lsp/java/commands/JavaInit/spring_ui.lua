local M = {}

function M.select_dependencies(callback)
  local available_deps = {
    { id = "web", name = "Spring Web (REST API / Embedded Tomcat)" },
    { id = "devtools", name = "Spring Boot DevTools" },
    { id = "lombok", name = "Lombok" },
    { id = "data-jpa", name = "Spring Data JPA (SQL / Hibernate ORM)" },
    { id = "h2", name = "H2 Database (In-Memory DB for testing)" },
  }

  local selected = {}

  local function show_menu()
    local options = { "[ DONE ] Confirm & Generate Project" }

    for _, dep in ipairs(available_deps) do
      local mark = selected[dep.id] and "[X]" or "[ ]"
      table.insert(options, string.format("%s %s", mark, dep.name))
    end

    vim.ui.select(options, {
      prompt = "Toggle Spring Boot Dependencies (Select DONE when finished):",
    }, function(choice)
      if not choice then
        callback("")
        return
      end

      if choice:match("^%[ DONE %]") then
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
end

return M
