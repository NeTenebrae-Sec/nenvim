local logger = require("plugins.lsp.java.logger")

local M = {}

--- Obtiene la versión objetivo desde la raíz del proyecto
function M.detect_target_version(root_dir)
  local pom_path = root_dir .. "/pom.xml"
  local gradle_path = root_dir .. "/build.gradle"
  local java_ver_path = root_dir .. "/.java-version"

  if vim.fn.filereadable(java_ver_path) == 1 then
    local lines = vim.fn.readfile(java_ver_path)
    if #lines > 0 then
      local ver = lines[1]:match("(%d+)")
      logger.debug("Versión detectada desde .java-version:", ver)
      return ver
    end
  elseif vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    local ver = content:match("<maven%.compiler%.release>%s*(%d+)%s*</maven%.compiler%.release>")
      or content:match("<java%.version>%s*(%d+)%s*</java%.version>")
      or content:match("<maven%.compiler%.source>%s*(%d+)%s*</maven%.compiler%.source>")
    logger.debug("Versión detectada desde pom.xml:", ver)
    return ver
  elseif vim.fn.filereadable(gradle_path) == 1 then
    local content = table.concat(vim.fn.readfile(gradle_path), "\n")
    local ver = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
      or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
    logger.debug("Versión detectada desde build.gradle:", ver)
    return ver
  end

  logger.debug("No se encontró versión explícita. Usando versión del sistema/fallback.")
  return nil
end

--- Resuelve la ruta al ejecutable java según la versión deseada
function M.resolve_java_bin(target_version)
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
