local M = {}

-- Cache en memoria para no saturar la API
local cached_metadata = nil

--- Fetchea la metadata oficial de start.spring.io (cachea todo el JSON)
local function fetch_metadata(callback)
  if cached_metadata then
    callback(cached_metadata)
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

      if ok and parsed then
        cached_metadata = parsed
        callback(parsed)
      else
        callback(nil)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and not cached_metadata then
        vim.notify("Failed to fetch Spring metadata. Check your connection.", vim.log.levels.WARN)
        callback(nil)
      end
    end,
  })
end

--- Selector de versión de Spring Boot (solo stable releases)
function M.select_boot_version(callback)
  fetch_metadata(function(meta)
    if not meta or not meta.bootVersion or not meta.bootVersion.values then
      vim.notify("Using default Spring Boot version (4.1.1)", vim.log.levels.INFO)
      callback("4.1.1")
      return
    end

    local versions = {}
    for _, v in ipairs(meta.bootVersion.values) do
      if not v.id:match("SNAPSHOT") and not v.id:match("M%d") and not v.id:match("RC%d") then
        local clean_id = v.id:gsub("%.RELEASE$", "")
        table.insert(versions, { id = clean_id, name = v.name })
      end
    end

    if #versions == 0 then
      callback("4.1.1")
      return
    end

    vim.ui.select(versions, {
      prompt = "Select Spring Boot Version:",
      format_item = function(item)
        return item.name
      end,
    }, function(choice)
      callback(choice and choice.id or versions[1].id)
    end)
  end)
end

--- Selector UI multi-opción
function M.select_dependencies(callback)
  fetch_metadata(function(meta)
    local available_deps = {}

    if meta and meta.dependencies and meta.dependencies.values then
      for _, category in ipairs(meta.dependencies.values) do
        local cat_name = category.name or "Other"
        if category.values then
          for _, dep in ipairs(category.values) do
            table.insert(available_deps, {
              id = dep.id,
              name = string.format("[%s] %s", cat_name, dep.name),
              description = dep.description or "",
            })
          end
        end
      end
    end

    -- Fallback si no hay conexión a internet
    if #available_deps == 0 then
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
        table.insert(options, string.format("%s %s ##%s", mark, dep.name, dep.id))
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

        local dep_id = choice:match("##(.+)$")
        if dep_id then
          selected[dep_id] = not selected[dep_id]
        end

        show_menu()
      end)
    end

    show_menu()
  end)
end

return M
