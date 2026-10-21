local M = {}

local detector = require("languages.java.commands.JavaAddDependencies.detector")
local search = require("languages.java.commands.JavaAddDependencies.search")
local ui = require("languages.java.commands.JavaAddDependencies.ui")
local installer = require("languages.java.commands.JavaAddDependencies.installer")

local LOGTITLE = "Java LSP"

local function trigger_refresh()
  local ok, java_refresh = pcall(require, "languages.java.commands.JavaRefresh")
  if ok and type(java_refresh.refresh) == "function" then
    java_refresh.refresh({ silent = false })
  end
end

--- Devuelve la versión de Java más alta instalada (fallback a "17")
--- Sigue el patrón de JavaInit/jdks.lua
---@return string
local function get_java_version()
  local ok, java_det = pcall(require, "languages.java.detector")
  if ok and java_det.get_latest_installed_version then
    return java_det.get_latest_installed_version()
  end
  return "17"
end

--- Crea un pom.xml básico para proyectos sin build tool.
--- Sigue el patrón de JavaInit/templates.lua:generate_pure_maven_pom
--- No crea archivos fuente ni directorios (el proyecto ya existe, solo falta el build file)
---@param root string directorio raíz
local function create_basic_project(root)
  local java_version = get_java_version()
  local coords = detector.extract_maven_coords(root)
  local group_id = coords.group_id
  local artifact_id = coords.artifact_id

  -- <sourceDirectory>src</sourceDirectory> para compatibilidad con
  -- proyectos Pure Java de JavaInit (estructura plana src/ en vez de src/main/java)
  local pom = {
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<project xmlns="http://maven.apache.org/POM/4.0.0"',
    '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
    '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">',
    "    <modelVersion>4.0.0</modelVersion>",
    "",
    "    <groupId>" .. group_id .. "</groupId>",
    "    <artifactId>" .. artifact_id .. "</artifactId>",
    "    <version>1.0-SNAPSHOT</version>",
    "",
    "    <properties>",
    "        <maven.compiler.release>" .. java_version .. "</maven.compiler.release>",
    "        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>",
    "    </properties>",
    "",
    "    <build>",
    "        <sourceDirectory>src</sourceDirectory>",
    "    </build>",
    "",
    "    <dependencies>",
    "    </dependencies>",
    "</project>",
  }
  vim.fn.writefile(pom, root .. "/pom.xml")

  vim.notify(
    string.format("Created pom.xml for '%s' (Java %s)", artifact_id, java_version),
    vim.log.levels.INFO,
    { title = LOGTITLE }
  )
end

--- Flujo: buscar y seleccionar dependencias comunes (sin API call inicial)
--- Sigue el patrón de JavaInit: muestra opciones predefinidas primero
---@param project table
local function from_common_deps(project)
  ui.select_common_deps(function(selected)
    if not selected or #selected == 0 then return end
    -- Same flow as from_maven_search but starting from common deps
    ui.select_scopes(selected, project.tool, function(deps_with_scope)
      if not deps_with_scope or #deps_with_scope == 0 then return end
      ui.select_versions(deps_with_scope, function(deps_with_version)
        if not deps_with_version or #deps_with_version == 0 then return end
        ui.show_confirmation(deps_with_version, project.tool, project.build_file, function(confirmed)
          if not confirmed then
            vim.notify("Cancelled.", vim.log.levels.INFO, { title = LOGTITLE })
            return
          end
          installer.install(project, deps_with_version, function(success)
            if success then
              vim.notify(
                string.format("Added %d dependencies successfully!", #deps_with_version),
                vim.log.levels.INFO,
                { title = LOGTITLE }
              )
              trigger_refresh()
            else
              vim.notify("Failed to add some dependencies.", vim.log.levels.ERROR, { title = LOGTITLE })
            end
          end)
        end)
      end)
    end)
  end)
end

--- Flujo: búsqueda en Maven Central
---@param project table
local function from_maven_search(project)
  ui.search_input("Search Maven Central: ", "", function(query)
    if not query then return end
    vim.notify("Searching Maven Central for: " .. query, vim.log.levels.INFO, { title = LOGTITLE })
    search.search_artifacts(query, function(results)
      if not results or #results == 0 then
        vim.notify("No results found for: " .. query, vim.log.levels.WARN, { title = LOGTITLE })
        return
      end
      ui.select_search_results(results, function(selected)
        if not selected or #selected == 0 then return end
        ui.select_scopes(selected, project.tool, function(deps_with_scope)
          if not deps_with_scope or #deps_with_scope == 0 then return end
          ui.select_versions(deps_with_scope, function(deps_with_version)
            if not deps_with_version or #deps_with_version == 0 then return end
            ui.show_confirmation(deps_with_version, project.tool, project.build_file, function(confirmed)
              if not confirmed then
                vim.notify("Cancelled.", vim.log.levels.INFO, { title = LOGTITLE })
                return
              end
              installer.install(project, deps_with_version, function(success)
                if success then
                  vim.notify(
                    string.format("Added %d dependencies successfully!", #deps_with_version),
                    vim.log.levels.INFO,
                    { title = LOGTITLE }
                  )
                  trigger_refresh()
                else
                  vim.notify("Failed to add some dependencies.", vim.log.levels.ERROR, { title = LOGTITLE })
                end
              end)
            end)
          end)
        end)
      end)
    end)
  end)
end

--- Flujo: Spring Boot Starters via start.spring.io
---@param project table
local function from_spring_starters(project)
  ui.select_spring_starters(function(selected)
    if not selected or #selected == 0 then return end
    local deps = {}
    for _, s in ipairs(selected) do
      table.insert(deps, {
        group_id = s.group_id,
        artifact_id = s.artifact_id,
        version = nil,
        scope = nil,
        no_version = true,
      })
    end
    installer.install(project, deps, function(success)
      if success then
        vim.notify("Added Spring Boot starters successfully!", vim.log.levels.INFO, { title = LOGTITLE })
        trigger_refresh()
      else
        vim.notify("Failed to add some dependencies.", vim.log.levels.ERROR, { title = LOGTITLE })
      end
    end)
  end)
end

function M.execute()
  local project = detector.detect()

  if project.no_build_tool then
    vim.ui.select({ "Yes", "No" }, {
      prompt = "No build tool found. Create a basic Maven project?",
    }, function(choice)
      if not choice or choice == "No" then return end
      create_basic_project(project.root)
      local new_project = detector.detect()
      if new_project and not new_project.no_build_tool then
        M.execute_with_project(new_project)
      end
    end)
    return
  end

  M.execute_with_project(project)
end

---@param project table
function M.execute_with_project(project)
  local tool_label = project.tool == "maven" and "Maven" or "Gradle"
  if project.gradle_dsl then
    tool_label = tool_label .. " (" .. (project.gradle_dsl == "kotlin" and "Kotlin DSL" or "Groovy DSL") .. ")"
  end
  if project.is_spring then
    tool_label = tool_label .. " + Spring Boot"
  end

  -- Extraer y mostrar coordenadas del proyecto (groupId, artifactId)
  -- Sigue el patrón de JavaInit que muestra información del proyecto al usuario
  local coords = detector.extract_maven_coords(project.root)

  vim.notify(string.format(
    "Project detected: %s | coords: %s:%s",
    tool_label, coords.group_id, coords.artifact_id
  ), vim.log.levels.INFO, { title = LOGTITLE })

  local options = { "Browse Common Dependencies", "Search Maven Central" }
  if project.is_spring then
    table.insert(options, "Browse Spring Boot Starters")
  end

  vim.ui.select(options, {
    prompt = "Select dependency source:",
  }, function(choice)
    if not choice then return end

    if choice:match("Common Dependencies") then
      from_common_deps(project)
    elseif choice:match("Maven Central") then
      from_maven_search(project)
    elseif choice:match("Spring Boot Starters") then
      from_spring_starters(project)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaAddDependencies", function()
    M.execute()
  end, {
    desc = "Add dependencies to a Java project (Maven/Gradle)",
  })
end

return M
