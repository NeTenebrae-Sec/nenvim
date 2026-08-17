-- ============================================================================
-- JAVA DAP / RUNNER MODULE (Neovim)
-- ============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- CONFIG & UI CONSTANTS
-- ----------------------------------------------------------------------------
local CONFIG_TEXTS = {
  menu_prompt = "Select execution action:",
  pure_run = "1. Pure Java: Compile & Run Class",
  pure_debug = "2. Pure Java: Compile & Run in Debug Mode (JDWP Port 5005)",
}

-- ----------------------------------------------------------------------------
-- HELPER: SYSTEM & EXECUTION
-- ----------------------------------------------------------------------------
local function execute_in_kitty(cmd)
  cmd = cmd .. "; echo ''; read -p 'Press Enter to close...'"
  vim.fn.jobstart({ "/usr/bin/kitty", "-e", "bash", "-c", cmd }, { detach = true })
end

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

-- ----------------------------------------------------------------------------
-- HELPER: JAVA CLASS & VERSION PARSING
-- ----------------------------------------------------------------------------
local function get_project_java_version(root)
  local java_ver_path = root .. "/.java-version"
  local pom_path = root .. "/pom.xml"
  local gradle_path = root .. "/build.gradle"
  local gradle_kts_path = root .. "/build.gradle.kts"

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
  end

  local target_gradle = vim.fn.filereadable(gradle_path) == 1 and gradle_path or gradle_kts_path
  if vim.fn.filereadable(target_gradle) == 1 then
    local content = table.concat(vim.fn.readfile(target_gradle), "\n")
    local ver = content:match("JavaLanguageVersion%.of%s*%(%s*(%d+)%s*%)")
      or content:match("sourceCompatibility%s*=%s*['\"]?(%d+)")
    if ver then
      return ver
    end
  end

  return "21"
end

local function get_fqcn_from_file(file_path)
  local lines = vim.fn.readfile(file_path)
  local pkg = ""
  for _, line in ipairs(lines) do
    local p = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if p then
      pkg = p
      break
    end
  end

  local class_name = vim.fn.fnamemodify(file_path, ":t:r")
  return pkg ~= "" and (pkg .. "." .. class_name) or class_name
end

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
    return get_fqcn_from_file(matches[1])
  end
  return nil
end

-- ----------------------------------------------------------------------------
-- MODULE: BUILD TOOL & ENVIRONMENT DETECTION
-- ----------------------------------------------------------------------------
local function detect_build_environment(root, src_dir)
  local has_gradlew = vim.fn.filereadable(root .. "/gradlew") == 1
  local has_mvnw = vim.fn.filereadable(root .. "/mvnw") == 1
  local has_gradle_file = vim.fn.filereadable(root .. "/build.gradle") == 1
    or vim.fn.filereadable(root .. "/build.gradle.kts") == 1
  local has_pom_file = vim.fn.filereadable(root .. "/pom.xml") == 1

  local gradle_exec = nil
  if has_gradlew then
    gradle_exec = "./gradlew"
  elseif has_gradle_file and vim.fn.executable("gradle") == 1 then
    gradle_exec = "gradle"
  end

  local maven_exec = nil
  if has_mvnw then
    maven_exec = "./mvnw"
  elseif has_pom_file and vim.fn.executable("mvn") == 1 then
    maven_exec = "mvn"
  end

  local project_type = "pure"
  if has_gradle_file and gradle_exec then
    project_type = "gradle"
  elseif has_pom_file and maven_exec then
    project_type = "maven"
  end

  -- Spring Boot detection
  local is_spring = false
  if project_type ~= "pure" then
    if has_pom_file then
      local content = table.concat(vim.fn.readfile(root .. "/pom.xml"), "\n")
      if content:find("spring-boot") then
        is_spring = true
      end
    end
    if not is_spring and has_gradle_file then
      local gfile = vim.fn.filereadable(root .. "/build.gradle") == 1 and (root .. "/build.gradle")
        or (root .. "/build.gradle.kts")
      local content = table.concat(vim.fn.readfile(gfile), "\n")
      if content:find("org%.springframework%.boot") or content:find("spring%-boot") then
        is_spring = true
      end
    end
  end

  if not is_spring then
    local cmd = vim.fn.executable("rg") == 1
        and string.format("rg -q '@SpringBootApplication' %s", vim.fn.shellescape(src_dir))
      or string.format("grep -rq '@SpringBootApplication' %s", vim.fn.shellescape(src_dir))
    vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
      is_spring = true
    end
  end

  return {
    gradle_bin = gradle_exec,
    maven_bin = maven_exec,
    has_gradle_file = has_gradle_file,
    has_gradlew = has_gradlew,
    is_spring = is_spring,
    type = project_type,
  }
end

-- ----------------------------------------------------------------------------
-- FLOW RUNNERS
-- ----------------------------------------------------------------------------
local function run_build_tool_flow(env, root, file, src_dir, env_prefix)
  local menu_options = {}
  local actions = {}

  if env.is_spring then
    table.insert(menu_options, "1. Spring Boot: Run Application")
    actions[1] = function()
      return env.type == "gradle"
          and string.format("%s && cd %s && %s bootRun", env_prefix, vim.fn.shellescape(root), env.gradle_bin)
        or string.format("%s && cd %s && %s spring-boot:run", env_prefix, vim.fn.shellescape(root), env.maven_bin)
    end

    table.insert(menu_options, "2. Spring Boot: Remote Debug Mode (Port 5005)")
    actions[2] = function()
      return env.type == "gradle"
          and string.format(
            "%s && cd %s && %s bootRun --debug-jvm",
            env_prefix,
            vim.fn.shellescape(root),
            env.gradle_bin
          )
        or string.format(
          "%s && cd %s && %s spring-boot:run -Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005'",
          env_prefix,
          vim.fn.shellescape(root),
          env.maven_bin
        )
    end
  else
    local capitalized_type = env.type:gsub("^%l", string.upper)
    table.insert(menu_options, string.format("1. %s: Build & Run Main Class", capitalized_type))
    actions[1] = function()
      local target_class = has_main_method() and get_fqcn_from_file(file) or find_main_class(src_dir)
      if not target_class then
        vim.notify("No main class detected.", vim.log.levels.WARN)
        return nil
      end

      return env.type == "gradle"
          and string.format("%s && cd %s && %s run", env_prefix, vim.fn.shellescape(root), env.gradle_bin)
        or string.format(
          '%s && cd %s && %s compile exec:java -Dexec.mainClass="%s"',
          env_prefix,
          vim.fn.shellescape(root),
          env.maven_bin,
          target_class
        )
    end

    table.insert(menu_options, string.format("2. %s: Debug Main Class (Port 5005)", capitalized_type))
    actions[2] = function()
      local target_class = has_main_method() and get_fqcn_from_file(file) or find_main_class(src_dir)
      if not target_class then
        vim.notify("No main class detected.", vim.log.levels.WARN)
        return nil
      end

      return env.type == "gradle"
          and string.format("%s && cd %s && %s run --debug-jvm", env_prefix, vim.fn.shellescape(root), env.gradle_bin)
        or string.format(
          '%s && export MAVEN_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005" && cd %s && %s compile exec:java -Dexec.mainClass="%s"',
          env_prefix,
          vim.fn.shellescape(root),
          env.maven_bin,
          target_class
        )
    end
  end

  local test_idx = #menu_options + 1
  table.insert(menu_options, string.format("%d. Run Unit Tests", test_idx))
  actions[test_idx] = function()
    return env.type == "gradle"
        and string.format("%s && cd %s && %s test", env_prefix, vim.fn.shellescape(root), env.gradle_bin)
      or string.format("%s && cd %s && %s test", env_prefix, vim.fn.shellescape(root), env.maven_bin)
  end

  vim.ui.select(menu_options, { prompt = CONFIG_TEXTS.menu_prompt }, function(_, idx)
    if idx and actions[idx] then
      local cmd = actions[idx]()
      if cmd then
        execute_in_kitty(cmd)
      end
    end
  end)
end

local function run_pure_java_flow(java_ver, root, file, src_dir, env_prefix, env)
  local target_class = has_main_method() and get_fqcn_from_file(file) or find_main_class(src_dir)
  if not target_class then
    vim.notify("No class with main() method found.", vim.log.levels.WARN)
    return
  end

  local ver_num = tonumber(java_ver) or 21
  local javac_flags = ""
  local java_flags = ""

  if ver_num >= 12 and ver_num <= 26 then
    javac_flags = string.format(" --release %d --enable-preview", ver_num)
    java_flags = " --enable-preview"
  elseif ver_num >= 9 and ver_num < 12 then
    javac_flags = string.format(" --release %d", ver_num)
  end

  local menu_options = { CONFIG_TEXTS.pure_run, CONFIG_TEXTS.pure_debug }

  -- Si hay build.gradle pero no gradlew ni gradle global, ofrecemos la opción de generar el wrapper
  if env.has_gradle_file and not env.has_gradlew then
    table.insert(menu_options, "3. Gradle: Generate Wrapper (gradle wrapper)")
  end

  vim.ui.select(menu_options, { prompt = CONFIG_TEXTS.menu_prompt }, function(_, idx)
    if not idx then
      return
    end

    if idx == 3 then
      local cmd = string.format("%s && cd %s && gradle wrapper", env_prefix, vim.fn.shellescape(root))
      execute_in_kitty(cmd)
      return
    end

    local debug_flags = (idx == 2) and " -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005" or ""
    local cmd = string.format(
      "%s && cd %s && mkdir -p out && javac%s -d out $(find %s -name '*.java' ! -path '*/test/*') && java%s%s -cp out %s",
      env_prefix,
      vim.fn.shellescape(root),
      javac_flags,
      vim.fn.shellescape(src_dir),
      java_flags,
      debug_flags,
      target_class
    )

    execute_in_kitty(cmd)
  end)
end

-- ----------------------------------------------------------------------------
-- MAIN ENTRY POINTS
-- ----------------------------------------------------------------------------
function M.run()
  local file = vim.fn.expand("%:p")
  if file == "" or not file:match("%.java$") then
    vim.notify("Please open a valid .java file.", vim.log.levels.WARN)
    return
  end

  local root = vim.fs.root(0, {
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "mvnw",
    "gradlew",
    "settings.gradle",
    "settings.gradle.kts",
    ".java-version",
    ".git",
  }) or vim.fn.getcwd()

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

  local env = detect_build_environment(root, src_dir)

  if env.type ~= "pure" then
    run_build_tool_flow(env, root, file, src_dir, env_prefix)
  else
    run_pure_java_flow(java_ver, root, file, src_dir, env_prefix, env)
  end
end

function M.setup(_, mason_path)
  local ok_jdtls_dap, jdtls_dap = pcall(require, "jdtls.dap")
  if ok_jdtls_dap then
    pcall(jdtls_dap.setup_dap, { hotcodereplace = "auto", config_overrides = {} })
  end
end

return M
