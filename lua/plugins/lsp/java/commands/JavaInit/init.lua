local M = {}

local jdks = require("plugins.lsp.java.commands.JavaInit.jdks")
local templates = require("plugins.lsp.java.commands.JavaInit.templates")
local spring_ui = require("plugins.lsp.java.commands.JavaInit.spring_ui")

local SPRING_SUPPORTED_JAVA = { ["17"] = true, ["21"] = true, ["25"] = true }

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

        local function finalize_project(dependencies)
          vim.ui.input({ prompt = "Project Name (Artifact ID): ", default = "demo" }, function(project_name)
            if not project_name or project_name == "" then
              return
            end

            vim.ui.input({ prompt = "Group ID: ", default = "com.example" }, function(group_id)
              if not group_id or group_id == "" then
                group_id = "com.example"
              end

              local package_name = group_id .. "." .. project_name:gsub("-", "_")

              vim.ui.input({ prompt = "Target Directory: ", default = vim.fn.getcwd() }, function(target_dir)
                if not target_dir or target_dir == "" then
                  return
                end

                local full_path = target_dir .. "/" .. project_name

                if vim.fn.isdirectory(full_path) == 1 then
                  vim.notify("Directory already exists: " .. full_path, vim.log.levels.ERROR)
                  return
                end

                -- OPTION A: PURE JAVA
                if is_pure then
                  vim.fn.mkdir(full_path, "p")
                  local main_file = templates.create_pure_java_project(full_path, package_name, java_version)
                  vim.fn.writefile({ java_version }, full_path .. "/.java-version")
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
                  "https://start.spring.io/starter.tgz?type=%s&groupId=%s&artifactId=%s&name=%s&packageName=%s&javaVersion=%s",
                  build_tool,
                  group_id,
                  project_name,
                  project_name,
                  package_name,
                  java_version
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
            end)
          end)
        end

        if is_spring then
          spring_ui.select_dependencies(finalize_project)
        else
          finalize_project("")
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
