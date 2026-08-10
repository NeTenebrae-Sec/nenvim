local M = {}

-- Guardaremos la ruta del java_bin detectado para que otros módulos (runners) la consuman si la necesitan
M.current_java_bin = "java"

-- Función auxiliar para escribir logs en disco
local function log_debug(msg, data)
  local log_file = os.getenv("HOME") .. "/.cache/jdtls/java_init_debug.log"
  vim.fn.mkdir(os.getenv("HOME") .. "/.cache/jdtls", "p")

  local file = io.open(log_file, "a")
  if file then
    local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
    file:write(timestamp .. " " .. msg .. "\n")
    if data then
      if type(data) == "table" then
        file:write(vim.inspect(data) .. "\n")
      else
        file:write(tostring(data) .. "\n")
      end
    end
    file:write("--------------------------------------------------\n")
    file:close()
  end
end

function M.setup()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    return
  end

  -- Cargar comandos de usuario (:JavaInit, :JavaNewFile)
  local ok_commands, commands = pcall(require, "plugins.lsp.java.commands")
  if ok_commands then
    commands.setup()
  end

  local function start_jdtls()
    local home = os.getenv("HOME")
    local ok_lombok, lombok = pcall(require, "plugins.lsp.java.lombok")
    local ok_settings, settings = pcall(require, "plugins.lsp.java.settings")

    log_debug("== INICIANDO CONFIGURACIÓN DE JDTLS ==")

    local lombok_jar = ok_lombok and lombok.get_jar_path() or ""
    local mason_path = home .. "/.local/share/nvim/mason/packages"
    local jdtls_path = mason_path .. "/jdtls"
    local path_to_config = jdtls_path .. "/config_linux"

    local launcher_jars = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)
    local path_to_jar = #launcher_jars > 0 and launcher_jars[1] or ""

    local root_dir = jdtls.setup.find_root({
      "pom.xml",
      "build.gradle",
      "gradlew",
      "mvnw",
      ".git",
      ".project",
      ".classpath",
      ".java-version",
    })

    if not root_dir or root_dir == "" then
      root_dir = vim.fn.expand("%:p:h")
    end

    log_debug("Root Directorio detectado:", root_dir)

    -- DETECCIÓN DINÁMICA DE LA VERSIÓN DE JAVA
    local target_version = nil
    local pom_path = root_dir .. "/pom.xml"
    local gradle_path = root_dir .. "/build.gradle"
    local java_ver_path = root_dir .. "/.java-version"

    if vim.fn.filereadable(java_ver_path) == 1 then
      local lines = vim.fn.readfile(java_ver_path)
      if #lines > 0 then
        target_version = lines[1]:match("(%d+)")
        log_debug("Versión leída desde .java-version:", target_version)
      end
    elseif vim.fn.filereadable(pom_path) == 1 then
      local content = table.concat(vim.fn.readfile(pom_path), "\n")
      target_version = content:match("<maven%.compiler%.release>%s*(%d+)%s*</maven%.compiler%.release>")
        or content:match("<java%.version>%s*(%d+)%s*</java%.version>")
        or content:match("<maven%.compiler%.source>%s*(%d+)%s*</maven%.compiler%.source>")
      log_debug("Versión leída desde pom.xml:", target_version)
    elseif vim.fn.filereadable(gradle_path) == 1 then
      local content = table.concat(vim.fn.readfile(gradle_path), "\n")
      target_version = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
        or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
      log_debug("Versión leída desde build.gradle:", target_version)
    else
      log_debug("No se encontró archivo de versión. Fallback activo.")
    end

    -- RESOLUCIÓN DEL BINARIO DE JAVA
    local java_bin = "java"
    if target_version then
      local jvm_entries = vim.fn.glob("/usr/lib/jvm/*", false, true)
      for _, path in ipairs(jvm_entries) do
        local folder_name = vim.fn.fnamemodify(path, ":t")
        if folder_name:find(target_version) and vim.fn.executable(path .. "/bin/java") == 1 then
          java_bin = path .. "/bin/java"
          break
        end
      end
    end

    M.current_java_bin = java_bin
    log_debug("Binario Java seleccionado para ejecutar JDTLS y DAP:", java_bin)

    local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
    local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

    local bundles = {}
    local debug_jars = vim.fn.glob(
      mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      false,
      true
    )
    if #debug_jars > 0 then
      table.insert(bundles, debug_jars[1])
    end

    local cmd_args = {
      java_bin,
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.level=ERROR",
      "-Xms256m",
      "-Xmx1g",
    }

    if lombok_jar ~= "" and vim.fn.filereadable(lombok_jar) == 1 then
      table.insert(cmd_args, "-javaagent:" .. lombok_jar)
    end

    vim.list_extend(cmd_args, {
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",
      "-jar",
      path_to_jar,
      "-configuration",
      path_to_config,
      "-data",
      workspace_dir,
    })

    local current_settings = ok_settings and settings.get_settings() or {}
    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

    local config = {
      cmd = cmd_args,
      root_dir = root_dir,
      init_options = {
        bundles = bundles,
        extendedClientCapabilities = extendedClientCapabilities,
      },
      settings = current_settings,

      on_attach = function(_, bufnr)
        jdtls.setup_dap({ hotcodereplace = "auto", config_overrides = {} })

        local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
        if ok_jdtls_dap then
          jdtls_dap.setup_dap_main_class_configs()
        end

        -- FIX CRÍTICO: Sobrescribir forzosamente el binario de ejecución en DAP
        local ok_dap, dap = pcall(require, "dap")
        if ok_dap and dap.configurations.java then
          for _, dap_config in ipairs(dap.configurations.java) do
            dap_config.javaExec = java_bin
          end
        end
      end,
    }

    jdtls.start_or_attach(config)
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = start_jdtls,
  })

  if vim.bo.filetype == "java" then
    start_jdtls()
  end
end

return M
