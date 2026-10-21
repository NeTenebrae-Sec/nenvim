local M = {}

local xml_builder = require("languages.java.commands.JavaAddDependencies.xml_builder")

--- Verifica si un artifact ya existe en el build file
---@param build_file string
---@param artifact_id string
---@return boolean
local function exists_in_file(build_file, artifact_id)
  local content = table.concat(vim.fn.readfile(build_file), "\n")
  return content:find(artifact_id, 1, true) ~= nil
end

--- Filtra dependencias que ya existen
---@param deps table[]
---@param build_file string
---@return table[] nuevas
---@return table[] existentes
function M.filter_duplicates(deps, build_file)
  local new_deps = {}
  local existing = {}

  for _, dep in ipairs(deps) do
    if exists_in_file(build_file, dep.artifact_id) then
      table.insert(existing, dep)
    else
      table.insert(new_deps, dep)
    end
  end

  return new_deps, existing
end

--- Inyecta dependencias en build.gradle (Groovy DSL)
---@param build_file string
---@param deps table[]
function M.add_to_gradle_groovy(build_file, deps)
  local lines = vim.fn.readfile(build_file)

  local dep_end = nil
  local brace_count = 0
  local in_deps = false

  for i, line in ipairs(lines) do
    if not in_deps and line:match("^dependencies%s*{%s*$") then
      in_deps = true
      brace_count = 1
    elseif in_deps then
      for c in line:gmatch("[{}]") do
        if c == "{" then
          brace_count = brace_count + 1
        elseif c == "}" then
          brace_count = brace_count - 1
          if brace_count == 0 then
            dep_end = i
            break
          end
        end
      end
      if dep_end then break end
    end
  end

  local new_lines = {}
  for _, dep in ipairs(deps) do
    local scope = dep.scope or "implementation"
    local gav
    if dep.no_version then
      gav = string.format("'%s:%s'", dep.group_id, dep.artifact_id)
    else
      gav = string.format("'%s:%s:%s'", dep.group_id, dep.artifact_id, dep.version or "LATEST")
    end
    table.insert(new_lines, string.format("    %s %s", scope, gav))
  end

  if dep_end then
    for _, nl in ipairs(new_lines) do
      table.insert(lines, dep_end, nl)
    end
  else
    table.insert(lines, "")
    table.insert(lines, "dependencies {")
    for _, nl in ipairs(new_lines) do
      table.insert(lines, nl)
    end
    table.insert(lines, "}")
  end

  vim.fn.writefile(lines, build_file)
end

--- Inyecta dependencias en build.gradle.kts (Kotlin DSL)
---@param build_file string
---@param deps table[]
function M.add_to_gradle_kts(build_file, deps)
  local lines = vim.fn.readfile(build_file)

  local dep_end = nil
  local brace_count = 0
  local in_deps = false

  for i, line in ipairs(lines) do
    if not in_deps and line:match("^dependencies%s*{%s*$") then
      in_deps = true
      brace_count = 1
    elseif in_deps then
      for c in line:gmatch("[{}]") do
        if c == "{" then
          brace_count = brace_count + 1
        elseif c == "}" then
          brace_count = brace_count - 1
          if brace_count == 0 then
            dep_end = i
            break
          end
        end
      end
      if dep_end then break end
    end
  end

  local new_lines = {}
  for _, dep in ipairs(deps) do
    local scope = dep.scope or "implementation"
    local gav
    if dep.no_version then
      gav = string.format("\"%s:%s\"", dep.group_id, dep.artifact_id)
    else
      gav = string.format("\"%s:%s:%s\"", dep.group_id, dep.artifact_id, dep.version or "LATEST")
    end
    table.insert(new_lines, string.format("    %s(%s)", scope, gav))
  end

  if dep_end then
    for _, nl in ipairs(new_lines) do
      table.insert(lines, dep_end, nl)
    end
  else
    table.insert(lines, "")
    table.insert(lines, "dependencies {")
    for _, nl in ipairs(new_lines) do
      table.insert(lines, nl)
    end
    table.insert(lines, "}")
  end

  vim.fn.writefile(lines, build_file)
end

--- Función principal: inyecta dependencias en el build file
---@param project table resultado de detector.detect()
---@param deps table[] dependencias con scope y version
---@param callback function(success: boolean)
function M.install(project, deps, callback)
  if not deps or #deps == 0 then
    vim.notify("No dependencies to add.", vim.log.levels.WARN, { title = "Java LSP" })
    callback(true)
    return
  end

  local new_deps, existing = M.filter_duplicates(deps, project.build_file)

  if #existing > 0 then
    local names = {}
    for _, dep in ipairs(existing) do
      table.insert(names, dep.artifact_id)
    end
    vim.notify(
      string.format("Skipped (already exist): %s", table.concat(names, ", ")),
      vim.log.levels.WARN,
      { title = "Java LSP" }
    )
  end

  if #new_deps == 0 then
    vim.notify("All dependencies already exist.", vim.log.levels.INFO, { title = "Java LSP" })
    callback(true)
    return
  end

  if project.tool == "maven" then
    xml_builder.add_deps_to_pom(project.build_file, new_deps)
    callback(true)
    return
  end

  if project.tool == "gradle" then
    if project.gradle_dsl == "kotlin" then
      M.add_to_gradle_kts(project.build_file, new_deps)
    else
      M.add_to_gradle_groovy(project.build_file, new_deps)
    end
    callback(true)
    return
  end

  callback(false)
end

return M
