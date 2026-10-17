local M = {}

local BUILD_MARKERS = { "pom.xml", "build.gradle", "build.gradle.kts", "gradlew", "mvnw" }

--- Busca la raíz del proyecto subiendo desde el directorio actual
--- Usa getcwd() como punto principal para detectar el proyecto correcto
function M.find_project_root()
  local start = vim.fn.getcwd()

  local dir = start
  for _ = 0, 30 do
    for _, marker in ipairs(BUILD_MARKERS) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return { root = start, no_build_tool = true }
end

--- Detecta el build tool del proyecto
---@return string|nil tool "maven" | "gradle" | nil
---@return string|nil build_file path absoluto del build file
function M.detect_build_tool(root)
  if not root then
    return nil, nil
  end

  -- Si tiene bandera no_build_tool, no buscamos build file
  if root.no_build_tool then
    return nil, nil
  end

  if vim.fn.filereadable(root .. "/pom.xml") == 1 then
    return "maven", root .. "/pom.xml"
  end

  if vim.fn.filereadable(root .. "/build.gradle.kts") == 1 then
    return "gradle", root .. "/build.gradle.kts"
  end

  if vim.fn.filereadable(root .. "/build.gradle") == 1 then
    return "gradle", root .. "/build.gradle"
  end

  return nil, nil
end

--- Detecta si hay wrapper disponible
---@param root string
---@param tool string "maven" | "gradle"
---@return string cmd el comando a usar (ej. "./mvnw", "gradle")
function M.detect_wrapper(root, tool)
  if tool == "maven" and vim.fn.filereadable(root .. "/mvnw") == 1 then
    return "./mvnw"
  end

  if tool == "gradle" and vim.fn.filereadable(root .. "/gradlew") == 1 then
    return "./gradlew"
  end

  return tool == "maven" and "mvn" or "gradle"
end

--- Extrae groupId y artifactId de un pom.xml existente
---@param root string directorio raíz del proyecto
---@return table { group_id = string, artifact_id = string }
function M.extract_maven_coords(root)
  local group_id = "com.example"
  local artifact_id = vim.fn.fnamemodify(root, ":t")
  local pom_path = root .. "/pom.xml"

  if vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")

    local g = content:match("<groupId>%s*([^<]+)%s*</groupId>")
    local a = content:match("<artifactId>%s*([^<]+)%s*</artifactId>")

    if g and g ~= "" then
      group_id = g
    end
    if a and a ~= "" then
      artifact_id = a
    end
  end

  return { group_id = group_id, artifact_id = artifact_id }
end

--- Detecta si es un proyecto Spring Boot
---@param root string
---@param tool string
---@return boolean
---@return string|nil version versión de Spring Boot detectada
function M.is_spring_boot(root, tool)
  if tool == "maven" then
    local pom_path = root .. "/pom.xml"
    if vim.fn.filereadable(pom_path) ~= 1 then
      return false, nil
    end
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    local parent_group = content:match("<parent>%s*<groupId>%s*org%.springframework%.boot%s*</groupId>")
    local parent_artifact = content:match("<parent>%s*<groupId>[^<]*</groupId>%s*<artifactId>%s*spring%-boot%-starter%-parent%s*</artifactId>")
    -- La versión puede estar en <parent><version> o como propiedad <spring-boot.version>
    local version = content:match("<parent>.-<version>%s*([%d%.]+%S*)%s*</version>.-</parent>")
      or content:match("<spring%-boot%.version>%s*([%d%.]+%S*)%s*</spring%-boot%.version>")
    return parent_group and parent_artifact, version
  end

  if tool == "gradle" then
    local build_file = root .. "/build.gradle"
    if vim.fn.filereadable(build_file) ~= 1 then
      build_file = root .. "/build.gradle.kts"
    end
    if vim.fn.filereadable(build_file) ~= 1 then
      return false, nil
    end

    local content = table.concat(vim.fn.readfile(build_file), "\n")
    local has_plugin = content:match("org%.springframework%.boot")
    local version = content:match("org%.springframework%.boot%s*[\"']([%d%.]+%S*)[\"']")
    return has_plugin ~= nil, version
  end

  return false, nil
end

--- Detecta el DSL de Gradle
---@param root string
---@return string|nil "groovy" | "kotlin" | nil
function M.detect_gradle_dsl(root)
  if vim.fn.filereadable(root .. "/build.gradle.kts") == 1 then
    return "kotlin"
  end
  if vim.fn.filereadable(root .. "/build.gradle") == 1 then
    return "groovy"
  end
  return nil
end

--- Retorna toda la info del proyecto de una
---@return table { root, tool, build_file, cmd, is_spring, spring_version, gradle_dsl, no_build_tool }
function M.detect()
  local root = M.find_project_root()
  
  -- Si root es una tabla con no_build_tool, usamos esa info
  if type(root) == "table" and root.no_build_tool then
    return {
      root = root.root,
      tool = nil,
      build_file = nil,
      cmd = nil,
      is_spring = false,
      spring_version = nil,
      gradle_dsl = nil,
      no_build_tool = true,
    }
  end

  local tool, build_file = M.detect_build_tool(root)
  if not tool then
    return {
      root = root,
      tool = nil,
      build_file = nil,
      cmd = nil,
      is_spring = false,
      spring_version = nil,
      gradle_dsl = nil,
      no_build_tool = true,
    }
  end

  local cmd = M.detect_wrapper(root, tool)
  local is_spring, spring_version = M.is_spring_boot(root, tool)
  local gradle_dsl = tool == "gradle" and M.detect_gradle_dsl(root) or nil

  return {
    root = root,
    tool = tool,
    build_file = build_file,
    cmd = cmd,
    is_spring = is_spring,
    spring_version = spring_version,
    gradle_dsl = gradle_dsl,
    no_build_tool = false,
  }
end

return M