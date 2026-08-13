local M = {}

local jdks = require("plugins.lsp.java.commands.JavaInit.jdks")
local templates = require("plugins.lsp.java.commands.JavaInit.templates")
local spring_ui = require("plugins.lsp.java.commands.JavaInit.spring_ui")

local SPRING_SUPPORTED_JAVA = { ["17"] = true, ["21"] = true, ["25"] = true, ["26"] = true }

-- === VALIDADORES DE NOMBRES DE JAVA / ARTIFACTS ===
local function is_valid_project_name(name)
  if not name or name == "" then
    return false
  end
  -- Permite solo letras, números, guiones y guiones bajos (sin espacios ni caracteres especiales)
  return name:match("^[a-zA-Z0-9_%-]+$") ~= nil
end

local function is_valid_group_id(group_id)
  if not group_id or group_id == "" then
    return false
  end
  -- Formato tipo paquete: com.ejemplo (sin espacios, separado por puntos)
  return group_id:match("^[a-zA-Z_][a-zA-Z0-9_]*%.[a-zA-Z0-9_%.]+$") ~= nil
end

function M.create_project()
  vim.ui.select({
    "Pure Java (No Build Tool)",
    "Standard CLI Application (Maven / Gradle)",
    "Spring Boot Application (Web / API)",
  }, { prompt = "Select Project Type:" }, function(type_choice)
    if not type_choice then
      return
    end

    local is_pure = type_choice:match("^Pure")
    local is_spring = type_choice:match("^Spring")

    local function proceed_with_build(build_choice)
      local available_jdks = jdks.get_installed_jdks()

      if is_spring then
        local filtered = {}
        for _, ver in ipairs(available_jdks) do
          if SPRING_SUPPORTED_JAVA[ver] then
            table.insert(filtered, ver)
          end
        end
        available_jdks = #filtered > 0 and filtered or { "21", "17" }
      end

      vim.ui.select(available_jdks, { prompt = "Select Java Version:" }, function(java_version)
        if not java_version then
          return
        end

        local function finalize_project(dependencies, packaging)
          packaging = packaging or "jar"

          -- === PASO 1: DIRECTORIO OBJETIVO ===
          local function prompt_target_dir()
            vim.ui.input({ prompt = "Target Directory: ", default = vim.fn.getcwd() }, function(target_dir)
              if not target_dir or target_dir == "" then
                return
              end

              -- === PASO 2: NOMBRE DEL PROYECTO (ARTIFACT ID) ===
              local function prompt_project_name()
                vim.ui.input({ prompt = "Project Name (Artifact ID): ", default = "demo" }, function(project_name)
                  if not project_name then
                    return
                  end

                  -- Validar formato del nombre
                  if not is_valid_project_name(project_name) then
                    vim.notify("Invalid project name! Avoid spaces and special characters.", vim.log.levels.ERROR)
                    return prompt_project_name() -- Reintenta
                  end

                  local full_path = target_dir .. "/" .. project_name

                  -- Validar si la carpeta existe
                  if vim.fn.isdirectory(full_path) == 1 then
                    vim.notify("Directory already exists: " .. full_path, vim.log.levels.ERROR)
                    return prompt_project_name() -- Reintenta inmediatamente pidiendo otro nombre
                  end

                  -- === PASO 3: GROUP ID / PACKAGE ===
                  local function prompt_group_id()
                    vim.ui.input({ prompt = "Group ID: ", default = "com.example" }, function(group_id)
                      if not group_id then
                        return
                      end

                      if not is_valid_group_id(group_id) then
                        vim.notify(
                          "Invalid Group ID! Must follow Java package structure (e.g. com.example)",
                          vim.log.levels.ERROR
                        )
                        return prompt_group_id() -- Reintenta
                      end

                      local package_name = group_id .. "." .. project_name:gsub("-", "_")

                      -- === CREACIÓN / DESCARGA DEL PROYECTO ===

                      -- OPTION A: PURE JAVA
                      if is_pure then
                        vim.fn.mkdir(full_path, "p")
                        local main_file = templates.create_pure_java_project(full_path, package_name, java_version)
                        vim.notify("Pure Java project created successfully.", vim.log.levels.INFO)
                        vim.cmd("cd " .. vim.fn.fnameescape(full_path))
                        vim.cmd("edit " .. vim.fn.fnameescape(main_file))
                        return
                      end

                      -- OPTION B: STANDARD CLI PROJECT
                      if not is_spring then
                        vim.fn.mkdir(full_path, "p")
                        local main_file = templates.create_main_class(full_path, package_name, java_version)

                        if build_choice:match("^Maven") then
                          templates.generate_pure_maven_pom(full_path, group_id, project_name, java_version)
                        elseif build_choice:match("Groovy") then
                          templates.generate_pure_gradle_build(full_path, group_id, project_name, java_version, false)
                        else
                          templates.generate_pure_gradle_build(full_path, group_id, project_name, java_version, true)
                        end

                        vim.notify("Standard Java project created successfully.", vim.log.levels.INFO)
                        vim.cmd("cd " .. vim.fn.fnameescape(full_path))
                        vim.cmd("edit " .. vim.fn.fnameescape(main_file))
                        return
                      end

                      -- OPTION C: SPRING BOOT
                      vim.fn.mkdir(full_path, "p")

                      local build_tool = "maven-project"
                      if build_choice:match("Groovy") then
                        build_tool = "gradle-project"
                      elseif build_choice:match("Kotlin") then
                        build_tool = "gradle-project-kotlin"
                      end

                      local url = string.format(
                        "https://start.spring.io/starter.tgz?type=%s&groupId=%s&artifactId=%s&name=%s&packageName=%s&javaVersion=%s&packaging=%s",
                        build_tool,
                        group_id,
                        project_name,
                        project_name,
                        package_name,
                        java_version,
                        packaging
                      )

                      if dependencies and dependencies ~= "" then
                        url = url .. "&dependencies=" .. dependencies
                      end

                      vim.notify("Downloading Spring Boot template...", vim.log.levels.INFO)
                      local cmd = string.format(
                        "curl -sL %s | tar -xzvf - -C %s",
                        vim.fn.shellescape(url),
                        vim.fn.shellescape(full_path)
                      )

                      vim.fn.jobstart(cmd, {
                        on_exit = function(_, exit_code)
                          if exit_code == 0 then
                            vim.cmd("cd " .. vim.fn.fnameescape(full_path))
                            local main_files = vim.fn.glob(full_path .. "/src/main/java/**/*.java", false, true)
                            if #main_files > 0 then
                              vim.cmd("edit " .. vim.fn.fnameescape(main_files[1]))
                            end
                            vim.notify("Spring Boot project initialized successfully!", vim.log.levels.INFO)
                          else
                            vim.notify("Failed to download or extract project template.", vim.log.levels.ERROR)
                          end
                        end,
                      })
                    end)
                  end

                  prompt_group_id()
                end)
              end

              prompt_project_name()
            end)
          end

          prompt_target_dir()
        end

        if is_spring then
          spring_ui.select_dependencies(function(deps)
            vim.ui.select({ "jar", "war" }, { prompt = "Select Packaging Type:" }, function(pkg)
              finalize_project(deps, pkg or "jar")
            end)
          end)
        else
          finalize_project("", "jar")
        end
      end)
    end

    if is_pure then
      proceed_with_build("none")
    else
      vim.ui.select({
        "Maven",
        "Gradle (Groovy DSL)",
        "Gradle (Kotlin DSL)",
      }, { prompt = "Select Build Tool:" }, function(bt_choice)
        if bt_choice then
          proceed_with_build(bt_choice)
        end
      end)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaInit", M.create_project, { desc = "Initialize Java Project" })
end

return M
