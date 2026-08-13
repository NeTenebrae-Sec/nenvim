local M = {}

local LOMBOK_OPTIONS = {
  { label = "@Data (Getters, Setters, toString, equals, hashCode)", annotations = { "Data" } },
  { label = "@Getter & @Setter", annotations = { "Getter", "Setter" } },
  { label = "@NoArgsConstructor", annotations = { "NoArgsConstructor" } },
  { label = "@AllArgsConstructor", annotations = { "AllArgsConstructor" } },
  { label = "@RequiredArgsConstructor", annotations = { "RequiredArgsConstructor" } },
  { label = "@Builder (Patrón Builder)", annotations = { "Builder" } },
  { label = "@Slf4j (Logger)", annotations = { "extern.slf4j.Slf4j" } },
  { label = "@Value (Clase Inmutable)", annotations = { "Value" } },
  {
    label = "Combo Spring/Entity (@Data + @NoArgsConstructor + @AllArgsConstructor + @Builder)",
    annotations = { "Data", "NoArgsConstructor", "AllArgsConstructor", "Builder" },
  },
}

--- Añade una o varias anotaciones a la clase actual en el buffer
local function add_lombok_annotations(annotations)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- 1. Localizar la línea donde se declara la clase, interface o record
  local class_line_idx = nil
  for i, line in ipairs(lines) do
    if
      line:match("public%s+class")
      or line:match("^class%s+")
      or line:match("public%s+enum")
      or line:match("public%s+record")
    then
      class_line_idx = i - 1
      break
    end
  end

  if not class_line_idx then
    vim.notify("No class declaration found in current buffer", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  -- 2. Procesar cada anotación elegida
  for _, item in ipairs(annotations) do
    local simple_name = item:match("%.([^%.]+)$") or item
    local full_import = item:find("%.") and ("import lombok." .. item .. ";")
      or ("import lombok." .. simple_name .. ";")
    local annotation_str = "@" .. simple_name

    -- Verificar si el import ya existe en el archivo
    local has_import = false
    for _, line in ipairs(lines) do
      if line:find(full_import, 1, true) then
        has_import = true
        break
      end
    end

    -- Insertar el import si hace falta (justo debajo de la sentencia package o arriba de todo)
    if not has_import then
      local package_line_idx = nil
      for i, line in ipairs(lines) do
        if line:match("^package%s+") then
          package_line_idx = i
          break
        end
      end

      if package_line_idx then
        vim.api.nvim_buf_set_lines(buf, package_line_idx, package_line_idx, false, { full_import })
        class_line_idx = class_line_idx + 1
      else
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, { full_import })
        class_line_idx = class_line_idx + 1
      end
      -- Actualizamos la referencia de las líneas tras la modificación
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end

    -- Verificar si la anotación ya está presente sobre la clase
    local has_annotation = false
    for i = math.max(0, class_line_idx - 10), class_line_idx do
      if lines[i + 1] and lines[i + 1]:find("@" .. simple_name, 1, true) then
        has_annotation = true
        break
      end
    end

    -- Insertar la anotación arriba de la declaración de la clase
    if not has_annotation then
      vim.api.nvim_buf_set_lines(buf, class_line_idx, class_line_idx, false, { annotation_str })
      class_line_idx = class_line_idx + 1
      lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    end
  end

  -- Guardar o disparar formateo sutil para dejar el archivo limpio
  vim.notify("Lombok annotations added successfully", vim.log.levels.INFO, { title = "Java LSP" })
end

function M.execute()
  if vim.bo.filetype ~= "java" then
    vim.notify("This command can only be used in Java files", vim.log.levels.WARN, { title = "Java LSP" })
    return
  end

  vim.ui.select(LOMBOK_OPTIONS, {
    prompt = "Select Lombok Annotations to Add:",
    format_item = function(item)
      return item.label
    end,
  }, function(selected)
    if not selected then
      return
    end

    add_lombok_annotations(selected.annotations)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("JavaAddLombok", function()
    M.execute()
  end, { desc = "Add Lombok annotations and imports to current Java class" })
end

return M
