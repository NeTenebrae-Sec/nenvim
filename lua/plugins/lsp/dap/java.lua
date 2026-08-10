local M = {}

-- Helper to detect declared Java version in the project
local function get_project_java_version(root)
  local java_ver_path = root .. "/.java-version"
  local pom_path = root .. "/pom.xml"
  local gradle_path = root .. "/build.gradle"

  if vim.fn.filereadable(java_ver_path) == 1 then
    local lines = vim.fn.readfile(java_ver_path)
    if #lines > 0 then
      local ver = lines[1]:match("(%d+)")
      if ver then
        return ver
      end
    end
  end

  if vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    local ver = content:match("<maven%.compiler%.release>%s*(%d+)%s*</maven%.compiler%.release>")
      or content:match("<java%.version>%s*(%d+)%s*</java%.version>")
      or content:match("<maven%.compiler%.source>%s*(%d+)%s*</maven%.compiler%.source>")
    if ver then
      return ver
    end
  elseif vim.fn.filereadable(gradle_path) == 1 then
    local content = table.concat(vim.fn.readfile(gradle_path), "\n")
    local ver = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
      or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
    if ver then
      return ver
    end
  end

  return "21"
end

-- Get installed JDK home path
local function get_jdk_home(ver)
  local path = "/usr/lib/jvm/java-" .. ver .. "-openjdk"
  if vim.fn.isdirectory(path) == 1 then
    return path
  end

  local jvm_entries = vim.fn.glob("/usr/lib/jvm/*", false, true)
  for _, jvm_path in ipairs(jvm_entries) do
    local folder_name = vim.fn.fnamemodify(jvm_path, ":t")
    if folder_name:find(ver) and vim.fn.isdirectory(jvm_path) == 1 then
      return jvm_path
    end
  end

  return "/usr/lib/jvm/default"
end

-- Check if current buffer or line array has a main method or @SpringBootApplication
local function has_main_method()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    if
      line:match("public%s+static%s+void%s+main%s*%(")
      or line:match("void%s+main%s*%(")
      or line:match("@SpringBootApplication")
    then
      return true
    end
  end
  return false
end

-- Scan project src directory for a class containing main or @SpringBootApplication
local function find_main_class(src_dir)
  local cmd = vim.fn.executable("rg") == 1
      and string.format(
        "rg -l 'public static void main|void main|@SpringBootApplication' %s",
        vim.fn.shellescape(src_dir)
      )
    or string.format(
      "grep -rlE 'public static void main|void main|@SpringBootApplication' %s",
      vim.fn.shellescape(src_dir)
    )

  local matches = vim.fn.systemlist(cmd)
  if #matches > 0 then
    local main_file = matches[1]
    local rel_path = main_file:sub(#src_dir + 2):gsub("%.java$", "")
    return rel_path:gsub("/", ".")
  end
  return nil
end

-- Detect if the project uses Spring Boot
local function is_spring_boot_project(root, src_dir)
  local pom_path = root .. "/pom.xml"
  local gradle_path = root .. "/build.gradle"

  if vim.fn.filereadable(pom_path) == 1 then
    local content = table.concat(vim.fn.readfile(pom_path), "\n")
    if content:find("spring%-boot") then
      return true
    end
  elseif vim.fn.filereadable(gradle_path) == 1 then
    local content = table.concat(vim.fn.readfile(gradle_path), "\n")
    if content:find("org%.springframework%.boot") then
      return true
    end
  end

  return false
end

-- Execute command in Kitty external terminal
local function execute_in_kitty(cmd)
  cmd = cmd .. "; echo ''; read -p 'Press Enter to close...'"
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

function M.run()
  local file = vim.fn.expand("%:p")
  if file == "" or not file:match("%.java$") then
    vim.notify("Please open a valid .java file.", vim.log.levels.WARN)
    return
  end

  local root = vim.fs.root(0, { ".java-version", ".git", "mvnw", "gradlew", "pom.xml", ".classpath", ".project" })
    or vim.fn.getcwd()
  local java_ver = get_project_java_version(root)
  local jdk_home = get_jdk_home(java_ver)
  local env_prefix =
    string.format("export JAVA_HOME=%s && export PATH=$JAVA_HOME/bin:$PATH", vim.fn.shellescape(jdk_home))

  local src_dir = root
  if vim.fn.isdirectory(root .. "/src/main/java") == 1 then
    src_dir = root .. "/src/main/java"
  elseif vim.fn.isdirectory(root .. "/src") == 1 then
    src_dir = root .. "/src"
  end

  -- Detect Target Class
  local target_class = nil
  if has_main_method() then
    local rel_path = file:sub(#src_dir + 2):gsub("%.java$", "")
    target_class = rel_path:gsub("/", ".")
  else
    target_class = find_main_class(src_dir)
    if target_class then
      vim.notify("Using detected main: " .. target_class, vim.log.levels.INFO)
    end
  end

  local has_mvnw = vim.fn.filereadable(root .. "/mvnw") == 1
  local has_pom = vim.fn.filereadable(root .. "/pom.xml") == 1
  local has_gradlew = vim.fn.filereadable(root .. "/gradlew") == 1

  -- OPTION A: SPRING BOOT (Abre menú de verbosidad pero enfocado 100% en Spring)
  if is_spring_boot_project(root, src_dir) then
    vim.ui.select({
      "1. Normal execution (Clean Spring Boot logs)",
      "2. Quiet mode (-q, hides Maven build info)",
      "3. Debug mode (-X, full Maven trace)",
    }, { prompt = "Spring Boot detected. Select run mode:" }, function(choice)
      if not choice then
        return
      end

      local cmd = ""
      if has_gradlew then
        local quiet_flag = choice:match("^2") and " -q" or ""
        local debug_flag = choice:match("^3") and " --debug" or ""
        cmd = string.format(
          "%s && cd %s && ./gradlew bootRun%s%s",
          env_prefix,
          vim.fn.shellescape(root),
          quiet_flag,
          debug_flag
        )
      else
        local mvn_cmd = has_mvnw and "./mvnw" or "mvn"
        local quiet_flag = choice:match("^2") and " -q" or ""
        local debug_flag = choice:match("^3") and " -X" or ""
        cmd = string.format(
          "%s && cd %s && %s%s%s spring-boot:run",
          env_prefix,
          vim.fn.shellescape(root),
          mvn_cmd,
          quiet_flag,
          debug_flag
        )
      end

      execute_in_kitty(cmd)
    end)
    return
  end

  -- OPTION B: STANDARD MAVEN / GRADLE PROJECT
  if has_mvnw or has_pom or has_gradlew then
    if not target_class then
      vim.notify("No class with main() method found in project.", vim.log.levels.WARN)
      return
    end

    vim.ui.select({
      "1. Quiet execution (-q)",
      "2. Full execution with logs",
    }, { prompt = "Select execution mode:" }, function(choice)
      if not choice then
        return
      end

      local mvn_cmd = has_mvnw and "./mvnw" or "mvn"
      local quiet_flag = choice:match("^1") and " -q" or ""
      local cmd = string.format(
        '%s && cd %s && %s%s compile exec:java -Dexec.mainClass="%s"',
        env_prefix,
        vim.fn.shellescape(root),
        mvn_cmd,
        quiet_flag,
        target_class
      )
      execute_in_kitty(cmd)
    end)
  else
    -- OPTION C: PURE JAVA
    if not target_class then
      vim.notify("No class with main() method found.", vim.log.levels.WARN)
      return
    end

    local javac_flags = ""
    local java_flags = ""

    if tonumber(java_ver) and tonumber(java_ver) >= 26 then
      javac_flags = string.format(" --release %s --enable-preview", java_ver)
      java_flags = " --enable-preview"
    end

    local cmd = string.format(
      "%s && cd %s && mkdir -p out && javac%s -d out $(find %s -name '*.java') && java%s -cp out %s",
      env_prefix,
      vim.fn.shellescape(root),
      javac_flags,
      vim.fn.shellescape(src_dir),
      java_flags,
      target_class
    )
    execute_in_kitty(cmd)
  end
end

function M.setup(_, mason_path)
  local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
  if ok_jdtls_dap then
    pcall(jdtls_dap.setup_dap, { hotcodereplace = "auto", config_overrides = {} })
  end
end
return M
