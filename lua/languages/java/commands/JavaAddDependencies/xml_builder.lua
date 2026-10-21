local M = {}

--- Build a single dependency XML block as array of lines
---@param dep table { group_id, artifact_id, version?, scope? }
---@param indent string|nil indentation prefix (default "    ")
---@return string[] lines array of XML lines (without trailing newline)
function M.build_dependency_lines(dep, indent)
  indent = indent or "    "
  local lines = {}
  table.insert(lines, indent .. "<dependency>")
  table.insert(lines, indent .. "    <groupId>" .. dep.group_id .. "</groupId>")
  table.insert(lines, indent .. "    <artifactId>" .. dep.artifact_id .. "</artifactId>")
  if dep.version and dep.version ~= "LATEST" then
    table.insert(lines, indent .. "    <version>" .. dep.version .. "</version>")
  end
  if dep.scope and dep.scope ~= "compile" and dep.scope ~= "implementation" then
    table.insert(lines, indent .. "    <scope>" .. dep.scope .. "</scope>")
  end
  table.insert(lines, indent .. "</dependency>")
  return lines
end

--- Build the full <dependencies> block as array of lines
---@param deps table[] array of { group_id, artifact_id, version?, scope? }
---@return string[] lines array of lines including <dependencies> tags
function M.build_dependencies_block(deps)
  local lines = {}
  table.insert(lines, "")
  table.insert(lines, "    <dependencies>")
  for _, dep in ipairs(deps) do
    local dep_lines = M.build_dependency_lines(dep)
    for _, line in ipairs(dep_lines) do
      table.insert(lines, line)
    end
  end
  table.insert(lines, "    </dependencies>")
  table.insert(lines, "")
  return lines
end

--- Insert dependency lines into existing pom.xml lines array
---@param pom_lines string[] current pom.xml lines
---@param new_dep_lines string[] dependency lines to insert
---@return string[] result new pom.xml lines
function M.insert_into_pom(pom_lines, new_dep_lines)
  local result = vim.deepcopy(pom_lines)

  -- Check if <dependencies> already exists (NOT </dependencies>)
  local has_deps = false
  for _, line in ipairs(result) do
    if line:match("%s*<dependencies>%s*$") then
      has_deps = true
      break
    end
  end

  if has_deps then
    -- Insert before </dependencies>
    local insert_pos = nil
    for i, line in ipairs(result) do
      if line:match("%s*</dependencies>%s*$") then
        insert_pos = i
        break
      end
    end
    if insert_pos then
      for j, line in ipairs(new_dep_lines) do
        table.insert(result, insert_pos + j - 1, line)
      end
    end
  else
    -- Insert before </project>
    local insert_pos = nil
    for i, line in ipairs(result) do
      if line:match("%s*</project>%s*$") then
        insert_pos = i
        break
      end
    end
    if insert_pos then
      for j, line in ipairs(new_dep_lines) do
        table.insert(result, insert_pos + j - 1, line)
      end
    end
  end

  return result
end

--- Read pom.xml and add dependencies, write back
---@param build_file string path to pom.xml
---@param deps table[] array of { group_id, artifact_id, version?, scope? }
function M.add_deps_to_pom(build_file, deps)
  local pom_lines = vim.fn.readfile(build_file)

  -- Check if <dependencies> already exists and detect <dependency> indentation
  local has_deps = false
  local existing_indent = "    "
  local in_deps = false
  for _, line in ipairs(pom_lines) do
    if line:match("%s*<dependencies>%s*$") then
      has_deps = true
      in_deps = true
    elseif in_deps and line:match("%s*<dependency>%s*$") then
      existing_indent = line:match("^(%s*)<dependency>") or "    "
      break
    elseif in_deps and line:match("%s*</dependencies>%s*$") then
      break
    end
  end

  local new_dep_lines
  if has_deps then
    -- Only the dependency blocks (no <dependencies> wrapper)
    new_dep_lines = {}
    for _, dep in ipairs(deps) do
      local dep_lines = M.build_dependency_lines(dep, existing_indent)
      for _, line in ipairs(dep_lines) do
        table.insert(new_dep_lines, line)
      end
    end
  else
    -- Full block with <dependencies> wrapper
    new_dep_lines = M.build_dependencies_block(deps)
  end

  local result = M.insert_into_pom(pom_lines, new_dep_lines)
  vim.fn.writefile(result, build_file)
end

return M
