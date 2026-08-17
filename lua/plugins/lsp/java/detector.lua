local logger = require("plugins.lsp.java.logger")

local M = {}

--- Obtiene la versión numérica más alta de Java instalada en el sistema (/usr/lib/jvm)
function M.get_latest_installed_version()
  local jvm_entries = vim.fn.glob("/usr/lib/jvm/*", false, true)
  local max_ver = 0

  for _, path in ipairs(jvm_entries) do
    local folder_name = vim.fn.fnamemodify(path, ":t")
    -- Ignorar enlaces simbólicos comunes o genéricos
    if folder_name ~= "default" and folder_name ~= "default-runtime" and folder_name ~= "current" then
      local ver = tonumber(folder_name:match("(%d+)"))
      if ver and ver > max_ver and vim.fn.executable(path .. "/bin/java") == 1 then
        max_ver = ver
      end
    end
  end

  return max_ver > 0 and tostring(max_ver) or "21"
end

--- Obtiene la versión objetivo desde la raíz del proyecto (o usa la más alta si no hay especificación)
function M.detect_target_version(root_dir)
  local pom_path = root_dir .. "/pom.xml"
  local gradle_path = root_dir .. "/build.gradle"
  local java_ver_path = root_dir .. "/.java-version"

  if vim.fn.filereadable(java_ver_path) == 1 then
    local lines = vim.fn.readfile(java_ver_path)
    if #lines > 0 then
      local ver = lines[1]:match("(%d+)")
      if ver then
        logger.debug("Versión detectada desde .java-version:", ver)
        return ver
      end
    end
  elseif vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    local ver = content:match("<maven%.compiler%.release>%s*(%d+)%s*</maven%.compiler%.release>")
      or content:match("<java%.version>%s*(%d+)%s*</java%.version>")
      or content:match("<maven%.compiler%.source>%s*(%d+)%s*</maven%.compiler%.source>")
    if ver then
      logger.debug("Versión detectada desde pom.xml:", ver)
      return ver
    end
  elseif vim.fn.filereadable(gradle_path) == 1 then
    local content = table.concat(vim.fn.readfile(gradle_path), "\n")
    local ver = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
      or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
    if ver then
      logger.debug("Versión detectada desde build.gradle:", ver)
      return ver
    end
  end

  -- Fallback dinámico: usa la versión más alta instalada en el sistema (ej. Java 26)
  local latest = M.get_latest_installed_version()
  logger.debug("Sin especificación en proyecto. Usando la versión instalada más reciente:", latest)
  return latest
end

--- Busca el binario de Java de la versión más reciente instalada para EJECUTAR JDTLS
function M.get_jdtls_runtime_java()
  local latest_ver = M.get_latest_installed_version()
  local jvm_entries = vim.fn.glob("/usr/lib/jvm/*", false, true)

  for _, path in ipairs(jvm_entries) do
    local folder_name = vim.fn.fnamemodify(path, ":t")
    if folder_name:find(latest_ver) and vim.fn.executable(path .. "/bin/java") == 1 then
      return path .. "/bin/java"
    end
  end

  return "java"
end

--- Resuelve el ejecutable java específico que necesita el debugger / runner según el proyecto
function M.resolve_project_java_bin(target_version)
  if target_version then
    local jvm_entries = vim.fn.glob("/usr/lib/jvm/*", false, true)
    for _, path in ipairs(jvm_entries) do
      local folder_name = vim.fn.fnamemodify(path, ":t")
      if folder_name:find(target_version) and vim.fn.executable(path .. "/bin/java") == 1 then
        return path .. "/bin/java"
      end
    end
  end
  return "java"
end

return M
