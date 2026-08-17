local M = {}

M.current_java_bin = "java"

function M.setup()
  local ok_jdtls, jdtls = pcall(require, "jdtls")
  if not ok_jdtls then
    return
  end

  -- 1. Cargar sub-modulos
  local logger = require("plugins.lsp.java.logger")
  local detector = require("plugins.lsp.java.detector")
  local builder = require("plugins.lsp.java.builder")
  local lombok = require("plugins.lsp.java.lombok")
  local settings = require("plugins.lsp.java.settings")

  -- 2. Registrar comandos
  pcall(function()
    require("plugins.lsp.java.commands").setup()
  end)

  local function start_jdtls()
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    -- GUARDIA REFORZADA: Evita que maybe_implicit_save() ejecute `:w` en un buffer vacío/inválido
    if
      bufname == ""
      or vim.bo[bufnr].buftype ~= ""
      or vim.fn.filereadable(bufname) == 0
      or vim.api.nvim_buf_line_count(bufnr) == 0
      or (vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "")
    then
      return
    end

    local home = os.getenv("HOME")
    logger.debug("== INICIANDO CONFIGURACIÓN DE JDTLS ==")

    -- Localizar raíz del proyecto
    local root_dir = jdtls.setup.find_root({
      "pom.xml",
      "build.gradle",
      "gradlew",
      "mvnw",
      ".git",
      ".project",
      ".classpath",
      ".java-version",
    }) or vim.fn.expand("%:p:h")

    logger.debug("Root Directorio detectado:", root_dir)

    -- LIMPIEZA AUTOMÁTICA DE LA CARPETA OUT
    local out_dir = root_dir .. "/out"
    if vim.fn.isdirectory(out_dir) == 1 then
      vim.fn.delete(out_dir, "rf")
      logger.debug("Carpeta 'out' limpiada automáticamente")
    end

    -- Separar la JVM del Servidor LSP de la JVM del Proyecto
    local target_ver = detector.detect_target_version(root_dir)

    -- JDTLS se ejecuta con Java 21+
    local jdtls_java_bin = detector.get_jdtls_runtime_java()
    -- El proyecto/debugger usa la versión real asignada
    local project_java_bin = detector.resolve_project_java_bin(target_ver)

    M.current_java_bin = project_java_bin
    logger.debug("Binario JDTLS:", jdtls_java_bin)
    logger.debug("Binario Proyecto/DAP:", project_java_bin)

    -- Configurar Rutas y Jars de Mason
    local mason_path = home .. "/.local/share/nvim/mason/packages"
    local jdtls_path = mason_path .. "/jdtls"
    local path_to_config = jdtls_path .. "/config_linux"

    local launcher_jars = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)
    local path_to_jar = #launcher_jars > 0 and launcher_jars[1] or ""

    local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
    local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

    -- Bundles para Debugging
    local bundles = {}
    local debug_jars = vim.fn.glob(
      mason_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      false,
      true
    )
    if #debug_jars > 0 then
      table.insert(bundles, debug_jars[1])
    end

    local cmd_args = builder.build_cmd({
      java_bin = jdtls_java_bin,
      lombok_jar = lombok.get_jar_path(),
      path_to_jar = path_to_jar,
      path_to_config = path_to_config,
      workspace_dir = workspace_dir,
    })

    -- Configurar Capabilities y Eventos LSP
    local extendedClientCapabilities = jdtls.extendedClientCapabilities
    extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

    local config = {
      cmd = cmd_args,
      root_dir = root_dir,
      init_options = {
        bundles = bundles,
        extendedClientCapabilities = extendedClientCapabilities,
      },
      settings = settings.get_settings(),

      handlers = {
        ["window/showMessage"] = function(_, result, _)
          if not result or result.type == 4 then
            return
          end

          local msg = result.message or ""
          if msg:lower():find("validate") or msg:lower():find("building") then
            return
          end

          local levels = {
            [1] = vim.log.levels.ERROR,
            [2] = vim.log.levels.WARN,
            [3] = vim.log.levels.INFO,
          }

          vim.notify(result.message or "", levels[result.type] or vim.log.levels.INFO, { title = "Java LSP (JDTLS)" })
        end,
      },
      on_attach = function(_, _)
        jdtls.setup_dap({
          hotcodereplace = "auto",
          config_overrides = {
            classPaths = { "${workspaceFolder}/out" },
          },
        })

        local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
        if ok_jdtls_dap then
          jdtls_dap.setup_dap_main_class_configs()
        end

        local ok_dap, dap = pcall(require, "dap")
        if ok_dap and dap.configurations.java then
          for _, dap_config in ipairs(dap.configurations.java) do
            dap_config.javaExec = project_java_bin
            dap_config.classPaths = { "${workspaceFolder}/out" }
          end
        end
      end,
    }

    -- Proteger la ejecución de start_or_attach
    pcall(function()
      jdtls.start_or_attach(config)
    end)
  end

  -- Auto-comando para buffers de tipo java
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = start_jdtls,
  })

  if vim.bo.filetype == "java" then
    start_jdtls()
  end
end

return M
