local M = {}

local search = require("languages.java.commands.JavaAddDependencies.search")

local MAVEN_SCOPES = {
  "compile (default)",
  "test",
  "provided",
  "runtime",
  "system",
}

local GRADLE_SCOPES = {
  "implementation (default)",
  "testImplementation",
  "compileOnly",
  "runtimeOnly",
  "annotationProcessor",
}

local SCOPE_MAP_MAVEN = {
  ["compile (default)"] = nil,
  ["test"] = "test",
  ["provided"] = "provided",
  ["runtime"] = "runtime",
  ["system"] = "system",
}

local SCOPE_MAP_GRADLE = {
  ["implementation (default)"] = nil,
  ["testImplementation"] = "testImplementation",
  ["compileOnly"] = "compileOnly",
  ["runtimeOnly"] = "runtimeOnly",
  ["annotationProcessor"] = "annotationProcessor",
}

---@param scope_display string
---@param tool string "maven" | "gradle"
---@return string|nil scope nil = default
function M.resolve_scope(scope_display, tool)
  if tool == "maven" then
    return SCOPE_MAP_MAVEN[scope_display]
  end
  return SCOPE_MAP_GRADLE[scope_display]
end

--- Selector UI multi-opción con toggles [ ] / [X]
---@param items table[] items con campo display, group_id, artifact_id
---@param prompt string
---@param callback function(selected: table[])
function M.toggle_select(items, prompt, callback)
  local selected = {}
  local item_by_key = {}

  for _, item in ipairs(items) do
    local key = item.group_id .. ":" .. item.artifact_id
    item_by_key[key] = item
  end

  local function show()
    local options = { "=== [ CONFIRM & ADD DEPENDENCIES ] ===" }

    for _, item in ipairs(items) do
      local key = item.group_id .. ":" .. item.artifact_id
      local mark = selected[key] and "[X]" or "[ ]"
      table.insert(options, mark .. " " .. item.display)
    end

    vim.ui.select(options, {
      prompt = prompt .. " (Select top to confirm)",
    }, function(choice)
      if not choice then
        callback({})
        return
      end

      if choice:find("CONFIRM") and choice:find("ADD DEPENDENCIES") then
        local result = {}
        for key, is_sel in pairs(selected) do
          if is_sel and item_by_key[key] then
            table.insert(result, item_by_key[key])
          end
        end
        callback(result)
        return
      end

      for _, item in ipairs(items) do
        if choice:find(item.display, 1, true) then
          local key = item.group_id .. ":" .. item.artifact_id
          selected[key] = not selected[key]
          show()
          return
        end
      end

      show()
    end)
  end

  show()
end

--- Input para búsqueda con prompt
---@param prompt string
---@param default string|nil
---@param callback function(query: string|nil)
function M.search_input(prompt, default, callback)
  vim.ui.input({
    prompt = prompt,
    default = default or "",
  }, function(input)
    if not input or input:match("^%s*$") then
      callback(nil)
      return
    end
    callback(input:gsub("^%s*(.-)%s*$", "%1"))
  end)
end

--- Lista curada de dependencias comunes (usada sin API call, funciona offline)
--- Sigue el patrón de JavaInit/spring_ui.lua:SPRING_STARTER_FALLBACK
local COMMON_DEPENDENCIES = {
  -- Lombok & Logging
  { group_id = "org.projectlombok", artifact_id = "lombok", display = "Lombok" },
  { group_id = "org.slf4j", artifact_id = "slf4j-api", display = "SLF4J API" },
  { group_id = "ch.qos.logback", artifact_id = "logback-classic", display = "Logback Classic" },
  { group_id = "org.apache.logging.log4j", artifact_id = "log4j-core", display = "Log4j Core" },
  { group_id = "org.apache.logging.log4j", artifact_id = "log4j-api", display = "Log4j API" },

  -- Jackson
  { group_id = "com.fasterxml.jackson.core", artifact_id = "jackson-databind", display = "Jackson Databind" },
  { group_id = "com.fasterxml.jackson.core", artifact_id = "jackson-core", display = "Jackson Core" },
  { group_id = "com.fasterxml.jackson.core", artifact_id = "jackson-annotations", display = "Jackson Annotations" },
  { group_id = "com.fasterxml.jackson.datatype", artifact_id = "jackson-datatype-jsr310", display = "Jackson JSR310" },

  -- Apache Commons
  { group_id = "org.apache.commons", artifact_id = "commons-lang3", display = "Apache Commons Lang" },
  { group_id = "org.apache.commons", artifact_id = "commons-io", display = "Apache Commons IO" },
  { group_id = "org.apache.commons", artifact_id = "commons-collections4", display = "Apache Commons Collections" },
  { group_id = "org.apache.commons", artifact_id = "commons-text", display = "Apache Commons Text" },
  { group_id = "org.apache.commons", artifact_id = "commons-compress", display = "Apache Commons Compress" },

  -- HTTP & Networking
  { group_id = "com.squareup.okhttp3", artifact_id = "okhttp", display = "OkHttp" },
  { group_id = "org.apache.httpcomponents", artifact_id = "httpclient", display = "Apache HttpClient" },
  { group_id = "org.apache.httpcomponents.client5", artifact_id = "httpclient5", display = "Apache HttpClient 5" },

  -- Google
  { group_id = "com.google.guava", artifact_id = "guava", display = "Guava" },

  -- Testing
  { group_id = "org.junit.jupiter", artifact_id = "junit-jupiter", display = "JUnit Jupiter" },
  { group_id = "org.mockito", artifact_id = "mockito-core", display = "Mockito Core" },
  { group_id = "org.assertj", artifact_id = "assertj-core", display = "AssertJ" },
  { group_id = "org.testcontainers", artifact_id = "testcontainers", display = "Testcontainers" },
  { group_id = "org.awaitility", artifact_id = "awaitility", display = "Awaitility" },

  -- Databases
  { group_id = "org.hibernate.orm", artifact_id = "hibernate-core", display = "Hibernate Core" },
  { group_id = "mysql", artifact_id = "mysql-connector-j", display = "MySQL Connector/J" },
  { group_id = "org.postgresql", artifact_id = "postgresql", display = "PostgreSQL JDBC Driver" },
  { group_id = "com.h2database", artifact_id = "h2", display = "H2 Database" },
  { group_id = "com.zaxxer", artifact_id = "HikariCP", display = "HikariCP" },

  -- Validation
  { group_id = "jakarta.validation", artifact_id = "jakarta.validation-api", display = "Jakarta Validation API" },
  { group_id = "org.hibernate.validator", artifact_id = "hibernate-validator", display = "Hibernate Validator" },

  -- JSON Processing
  { group_id = "com.google.code.gson", artifact_id = "gson", display = "Gson" },
  { group_id = "org.json", artifact_id = "json", display = "JSON.org" },

  -- Spring (non-Boot)
  { group_id = "org.springframework", artifact_id = "spring-core", display = "Spring Core" },
  { group_id = "org.springframework", artifact_id = "spring-web", display = "Spring Web (non-Boot)" },
  { group_id = "org.springframework", artifact_id = "spring-context", display = "Spring Context (non-Boot)" },

  -- Utilities
  { group_id = "io.micrometer", artifact_id = "micrometer-core", display = "Micrometer Core" },
  { group_id = "com.github.ben-manes.caffeine", artifact_id = "caffeine", display = "Caffeine Cache" },
}

--- Muestra dependencias comunes y permite seleccionar
--- Las deps comunes no tienen latest_version, por lo que select_versions
--- hará fetch de versiones desde Maven Central al momento de elegir versión
---@param callback function(selected: table[])
function M.select_common_deps(callback)
  local items = {}
  for _, dep in ipairs(COMMON_DEPENDENCIES) do
    table.insert(items, {
      display = dep.display .. " (" .. dep.group_id .. ":" .. dep.artifact_id .. ")",
      group_id = dep.group_id,
      artifact_id = dep.artifact_id,
      latest_version = nil,
    })
  end

  M.toggle_select(items, "Select common dependencies (or use Search Maven Central):", callback)
end

--- Muestra resultados de búsqueda y permite seleccionar
---@param results table[]
---@param callback function(selected: table[])
function M.select_search_results(results, callback)
  if not results or #results == 0 then
    vim.notify("No results found.", vim.log.levels.WARN, { title = "Java LSP" })
    callback({})
    return
  end

  local items = {}
  for _, r in ipairs(results) do
    table.insert(items, {
      display = string.format("[%s] %s (%s)", r.group_id, r.display_short, r.latest_version),
      group_id = r.group_id,
      artifact_id = r.artifact_id,
      latest_version = r.latest_version,
    })
  end

  M.toggle_select(items, "Select dependencies to add:", callback)
end

--- Pide scope para cada dependencia seleccionada
---@param deps table[]
---@param tool string "maven" | "gradle"
---@param callback function(deps_con_scope: table[])
function M.select_scopes(deps, tool, callback)
  local scopes = tool == "maven" and MAVEN_SCOPES or GRADLE_SCOPES
  local result = {}
  local idx = 1

  local function ask_next()
    if idx > #deps then
      callback(result)
      return
    end

    local dep = deps[idx]
    local display = string.format("%s:%s", dep.group_id, dep.artifact_id)

    vim.ui.select(scopes, {
      prompt = string.format("Scope for %s:", display),
    }, function(choice)
      if not choice then
        callback({})
        return
      end

      dep.scope = M.resolve_scope(choice, tool)
      if not dep.version then
        dep.version = dep.latest_version or "LATEST"
      end
      table.insert(result, dep)
      idx = idx + 1
      ask_next()
    end)
  end

  ask_next()
end

--- Pide al usuario que seleccione la versión para cada dependencia
---@param deps table[]
---@param callback function(deps_con_version: table[])
function M.select_versions(deps, callback)
  local result = {}
  local idx = 1

  local function ask_next()
    if idx > #deps then
      callback(result)
      return
    end

    local dep = deps[idx]

    if dep.no_version then
      table.insert(result, dep)
      idx = idx + 1
      ask_next()
      return
    end

    local display = string.format("%s:%s", dep.group_id, dep.artifact_id)
    vim.notify("Fetching versions for " .. display .. "...", vim.log.levels.INFO, { title = "Java LSP" })

    search.get_versions(dep.group_id, dep.artifact_id, function(versions)
      if not versions or #versions == 0 then
        dep.version = dep.latest_version or dep.version or "LATEST"
        table.insert(result, dep)
        idx = idx + 1
        ask_next()
        return
      end

      -- Prepend the latest version option only if latest_version is known
      -- (common deps from COMMON_DEPENDENCIES may not have this field)
      if dep.latest_version then
        table.insert(versions, 1, dep.latest_version .. " (latest)")
      end

      vim.ui.select(versions, {
        prompt = string.format("Version for %s:", display),
      }, function(choice)
        if not choice then
          callback({})
          return
        end

        dep.version = choice:gsub(" %(latest%)", "")
        table.insert(result, dep)
        idx = idx + 1
        ask_next()
      end)
    end)
  end

  ask_next()
end

--- Muestra resumen de confirmación
---@param deps table[]
---@param tool string
---@param build_file string
---@param callback function(confirmed: boolean)
function M.show_confirmation(deps, tool, build_file, callback)
  local lines = { "Dependencies to add:", "" }

  for i, dep in ipairs(deps) do
    local scope_str = dep.scope or (tool == "maven" and "compile" or "implementation")
    local version_str = dep.version and (":" .. dep.version) or ""
    local spring_note = dep.no_version and " (version from BOM)" or ""
    table.insert(lines, string.format(
      "  %d. %s:%s%s (%s)%s",
      i, dep.group_id, dep.artifact_id, version_str, scope_str, spring_note
    ))
  end

  table.insert(lines, "")
  table.insert(lines, string.format("Build tool: %s", tool))
  table.insert(lines, string.format("Target file: %s", build_file))
  table.insert(lines, "")
  table.insert(lines, "Proceed?")

  local summary = table.concat(lines, "\n")
  vim.notify(summary, vim.log.levels.INFO, { title = "Java LSP" })

  vim.ui.select({ "Yes, add dependencies", "Cancel" }, {
    prompt = summary,
  }, function(choice)
    callback(choice and choice:find("Yes") ~= nil)
  end)
end

--- Cache para Spring Initializr metadata
local spring_deps_cache = nil

--- Fallo: lista estática de starters comunes (usado cuando la API no responde)
local SPRING_STARTER_FALLBACK = {
  { id = "web", display = "[Web] Spring Web", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-web", name = "Spring Web", description = "Build web, including RESTful, applications using Spring MVC" },
  { id = "devtools", display = "[Developer Tools] Spring Boot DevTools", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-devtools", name = "Spring Boot DevTools", description = "Provides fast application restarts, LiveReload, and enhanced debugging" },
  { id = "lombok", display = "[Developer Tools] Lombok", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-lombok", name = "Lombok", description = "Java library that helps to reduce boilerplate Java code" },
  { id = "data-jpa", display = "[SQL] Spring Data JPA", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-data-jpa", name = "Spring Data JPA", description = "Persist data in SQL using Spring Data JPA and Hibernate" },
  { id = "h2", display = "[SQL] H2 Database", group_id = "com.h2database", artifact_id = "h2", name = "H2 Database", description = "H2 embedded database" },
  { id = "validation", display = "[Web] Spring Boot Starter Validation", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-validation", name = "Validation", description = "Bean Validation with Hibernate Validator" },
  { id = "actuator", display = "[Operations] Spring Boot Actuator", group_id = "org.springframework.boot", artifact_id = "spring-boot-starter-actuator", name = "Actuator", description = "Production-ready features for monitoring and managing applications" },
}

--- Fetch Spring Boot starters from start.spring.io
---@param callback function(deps: table[]|nil)
local function fetch_spring_dependencies(callback)
  if spring_deps_cache then
    callback(spring_deps_cache)
    return
  end

  vim.notify("Fetching Spring Boot starters from start.spring.io...", vim.log.levels.INFO, { title = "Java LSP" })

  local cmd = "curl -sH 'Accept: application/vnd.initializr.v2.1+json' https://start.spring.io/metadata/client"

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data or #data == 0 then
        return
      end
      local raw = table.concat(data, "")
      local ok, parsed = pcall(vim.json.decode, raw)

      if ok and parsed and parsed.dependencies and parsed.dependencies.values then
        local deps_list = {}
        for _, category in ipairs(parsed.dependencies.values) do
          local cat_name = category.name or "Other"
          if category.values then
            for _, dep in ipairs(category.values) do
              table.insert(deps_list, {
                id = dep.id,
                display = string.format("[%s] %s", cat_name, dep.name),
                group_id = "org.springframework.boot",
                artifact_id = "spring-boot-starter-" .. dep.id,
                name = dep.name,
                description = dep.description or "",
              })
            end
          end
        end
        spring_deps_cache = deps_list
        callback(deps_list)
      else
        callback(SPRING_STARTER_FALLBACK)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and not spring_deps_cache then
        vim.notify("Failed to fetch Spring metadata. Using fallback starters.", vim.log.levels.WARN, { title = "Java LSP" })
        callback(SPRING_STARTER_FALLBACK)
      end
    end,
  })
end

--- Selector de Spring Boot starters
---@param callback function(selected: table[])
function M.select_spring_starters(callback)
  fetch_spring_dependencies(function(available_deps)
    if not available_deps or #available_deps == 0 then
      vim.notify("No Spring Boot starters available.", vim.log.levels.WARN, { title = "Java LSP" })
      callback({})
      return
    end

    M.toggle_select(available_deps, "Select Spring Boot starters:", callback)
  end)
end

return M
