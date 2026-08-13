local M = {}

local FILE_TYPES = {
  { label = "Class", template = "class" },
  { label = "Interface", template = "interface" },
  { label = "Enum", template = "enum" },
  { label = "Record", template = "record" },
  { label = "Annotation", template = "annotation" },
}

--- Deduce el paquete relativo escaneando la ruta actual
local function detect_package_name(current_dir)
  local path = current_dir:gsub("\\", "/")

  -- Soporte para código fuente principal y de pruebas
  local match_main = path:match("src/main/java/(.+)$")
  local match_test = path:match("src/test/java/(.+)$")
  local match_pure = path:match("src/(.+)$")

  local rel_path = match_main or match_test or match_pure

  if rel_path and rel_path ~= "" then
    return rel_path:gsub("/", ".")
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

  local detected_package = detect_package_name(cwd)

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

      -- Limpia extensión e espacios accidentales
      file_name = file_name:gsub("%.java$", ""):gsub("%s+", "")

      vim.ui.input({
        prompt = "Package: ",
        default = detected_package,
      }, function(pkg_name)
        pkg_name = pkg_name or ""
        pkg_name = pkg_name:gsub("^%s*(.-)%s*$", "%1") -- trim

        local target_dir = cwd

        -- Si el usuario cambia el paquete a uno distinto, recalculamos la ruta base
        if pkg_name ~= "" and detected_package ~= "" and pkg_name ~= detected_package then
          local base_src = cwd:sub(1, #cwd - #detected_package:gsub("%.", "/"))
          target_dir = base_src .. pkg_name:gsub("%.", "/")
        end

        -- Garantiza que las carpetas destino existan
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

        -- Posicionamiento inteligente del cursor
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
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaNewFile", M.create_file, {
    desc = "Create a new Java File",
  })
end

return M
