local M = {}

local FILE_TYPES = {
  { label = "Class", template = "class" },
  { label = "Interface", template = "interface" },
  { label = "Enum", template = "enum" },
  { label = "Record", template = "record" },
  { label = "Annotation", template = "annotation" },
}

--- Busca la raíz del proyecto buscando archivos de build
local function find_project_root(start_dir)
  local dir = start_dir
  while dir ~= "/" do
    if
      vim.fn.filereadable(dir .. "/pom.xml") == 1
      or vim.fn.filereadable(dir .. "/build.gradle") == 1
      or vim.fn.filereadable(dir .. "/build.gradle.kts") == 1
    then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return start_dir
end

--- Detecta qué source roots están disponibles en el proyecto
local function detect_source_roots(project_root)
  local roots = {}
  local candidates = {
    { label = "src/main/java", path = project_root .. "/src/main/java" },
    { label = "src/test/java", path = project_root .. "/src/test/java" },
    { label = "src", path = project_root .. "/src" },
  }
  for _, item in ipairs(candidates) do
    if vim.fn.isdirectory(item.path) == 1 then
      table.insert(roots, item)
    end
  end
  return roots
end

--- Detecta el paquete relativo a un source root específico
local function detect_package_from_root(source_root)
  local current_buf = vim.api.nvim_buf_get_name(0)
  local cwd = ""

  if current_buf ~= "" then
    cwd = vim.fn.fnamemodify(current_buf, ":p:h")
  else
    cwd = vim.fn.getcwd()
  end

  local path = cwd:gsub("\\", "/")
  local root_path = source_root:gsub("\\", "/")

  if path:sub(1, #root_path) == root_path then
    local rel = path:sub(#root_path + 2)
    if rel ~= "" then
      return rel:gsub("/", ".")
    end
  end

  return ""
end

function M.create_file()
  local current_buf = vim.api.nvim_buf_get_name(0)
  local cwd = ""

  if current_buf ~= "" then
    cwd = vim.fn.fnamemodify(current_buf, ":p:h")
  else
    cwd = vim.fn.getcwd()
  end

  local project_root = find_project_root(cwd)
  local source_roots = detect_source_roots(project_root)

  if #source_roots == 0 then
    vim.notify("No source root found (src/ or src/main/java/)", vim.log.levels.ERROR)
    return
  end

  vim.ui.select(FILE_TYPES, {
    prompt = "Select Java Type:",
    format_item = function(item)
      return item.label
    end,
  }, function(selected_type)
    if not selected_type then
      return
    end

    vim.ui.input({
      prompt = "File Name (e.g. UserController): ",
    }, function(file_name)
      if not file_name or file_name:match("^%s*$") then
        return
      end

      file_name = file_name:gsub("%.java$", ""):gsub("%s+", "")

      local function ask_package(source_root)
        local detected = detect_package_from_root(source_root)

        vim.ui.input({
          prompt = "Package: ",
          default = detected,
        }, function(pkg_name)
          pkg_name = pkg_name or ""
          pkg_name = pkg_name:gsub("^%s*(.-)%s*$", "%1")

          local target_dir = source_root
          if pkg_name ~= "" then
            target_dir = source_root .. "/" .. pkg_name:gsub("%.", "/")
          end

          if vim.fn.isdirectory(target_dir) == 0 then
            vim.fn.mkdir(target_dir, "p")
          end

          local target_file = target_dir .. "/" .. file_name .. ".java"

          if vim.fn.filereadable(target_file) == 1 then
            vim.notify("File already exists: " .. target_file, vim.log.levels.ERROR)
            return
          end

          local lines = {}
          if pkg_name ~= "" then
            table.insert(lines, "package " .. pkg_name .. ";")
            table.insert(lines, "")
          end

          local kind = selected_type.template
          if kind == "class" then
            table.insert(lines, string.format("public class %s {", file_name))
            table.insert(lines, "    ")
            table.insert(lines, "}")
          elseif kind == "interface" then
            table.insert(lines, string.format("public interface %s {", file_name))
            table.insert(lines, "    ")
            table.insert(lines, "}")
          elseif kind == "enum" then
            table.insert(lines, string.format("public enum %s {", file_name))
            table.insert(lines, "    ")
            table.insert(lines, "}")
          elseif kind == "record" then
            table.insert(lines, string.format("public record %s() {", file_name))
            table.insert(lines, "}")
          elseif kind == "annotation" then
            table.insert(lines, string.format("public @interface %s {", file_name))
            table.insert(lines, "    ")
            table.insert(lines, "}")
          end

          vim.fn.writefile(lines, target_file)
          vim.cmd("edit " .. vim.fn.fnameescape(target_file))

          if kind == "record" then
            local record_line = pkg_name ~= "" and 3 or 1
            local col = #string.format("public record %s(", file_name)
            vim.api.nvim_win_set_cursor(0, { record_line, col })
          else
            local body_line = pkg_name ~= "" and 4 or 2
            vim.api.nvim_win_set_cursor(0, { body_line, 4 })
          end

          vim.notify("Created " .. selected_type.label .. ": " .. file_name .. ".java", vim.log.levels.INFO)
        end)
      end

      if #source_roots == 1 then
        ask_package(source_roots[1].path)
      else
        vim.ui.select(source_roots, {
          prompt = "Source Root:",
          format_item = function(item)
            return item.label
          end,
        }, function(selected_root)
          if not selected_root then
            return
          end
          ask_package(selected_root.path)
        end)
      end
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaNewFile", M.create_file, {
    desc = "Create a new Java File",
  })
end

return M
