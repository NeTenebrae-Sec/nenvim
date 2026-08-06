local M = {}

local hl_ns = vim.api.nvim_create_namespace("trident_live_rename_hl")
local debug_file = vim.fn.getcwd() .. "/trident_debug.log"

local function log_debug(msg)
  local f = io.open(debug_file, "a")
  if f then
    f:write(string.format("[%s] %s\n", os.date("%H:%M:%S"), msg))
    f:close()
  end
end

vim.api.nvim_set_hl(0, "TridentNeonRed", {
  fg = "#FF0055",
  bold = true,
  ctermfg = 198,
})

vim.api.nvim_set_hl(0, "TridentLineNum", {
  fg = "#5c6370",
  bold = false,
})

local function is_valid_identifier(name)
  if not name or name == "" then
    return false
  end
  return name:match("^[%w%-_]+$") ~= nil
end

function M.rename_live_preview()
  local f = io.open(debug_file, "w")
  if f then
    f:write("=== TRIDENT LIVE RENAME DEBUG LOG ===\n")
    f:close()
  end

  local target_win = vim.api.nvim_get_current_win()
  local target_buf = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(target_buf) then
    vim.notify("Trident: Buffer inválido", vim.log.levels.ERROR)
    log_debug("ERROR: Buffer de trabajo no válido.")
    return
  end

  local current_word = vim.fn.expand("<cword>")
  if current_word == "" then
    vim.notify("Trident: No hay un símbolo válido bajo el cursor", vim.log.levels.WARN)
    log_debug("WARN: Cursor en posición vacía (sin cword).")
    return
  end

  log_debug(string.format("Símbolo original capturado: '%s'", current_word))

  local lines_backup = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)
  local saved_view = vim.fn.winsaveview()

  -- 1. DIMENSIONES Y POSICIONAMIENTO
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines

  local width = math.min(60, math.max(40, math.floor(editor_width * 0.35)))
  local input_height = 1
  local preview_height = math.min(8, math.floor(editor_height * 0.25))

  local margin_right = 2
  local margin_top = 1

  local start_col = editor_width - width - margin_right
  local start_row = margin_top

  -- 2. INPUT WINDOW
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { current_word })

  local input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    row = start_row,
    col = start_col,
    width = width,
    height = input_height,
    style = "minimal",
    border = "rounded",
    title = " Trident Live Rename ",
    title_pos = "center",
  })

  vim.wo[input_win].wrap = false
  vim.wo[input_win].sidescrolloff = 5
  vim.wo[input_win].scrolloff = 0

  -- 3. PREVIEW WINDOW
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local preview_row = start_row + input_height + 2

  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    row = preview_row,
    col = start_col,
    width = width,
    height = preview_height,
    style = "minimal",
    border = "rounded",
    title = " Coincidencias fuera de pantalla ",
    title_pos = "center",
  })

  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].cursorline = true
  vim.wo[preview_win].wrap = false

  -- BÚSQUEDA DE LÍNEAS FUERA DE PANTALLA
  local function get_offscreen_matches(target_word, display_word)
    local top_line = vim.fn.line("w0", target_win)
    local bot_line = vim.fn.line("w$", target_win)
    local target_lines = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)

    local matches = {}
    local pattern = vim.pesc(target_word)
    local max_code_len = width - 12

    for idx, line in ipairs(target_lines) do
      if idx < top_line or idx > bot_line then
        local trimmed_line = line:gsub("^%s+", "")
        local start_col_idx, end_col_idx = trimmed_line:find(pattern, 1)

        if start_col_idx then
          local match_len = end_col_idx - start_col_idx + 1
          local snippet = trimmed_line
          local final_start = start_col_idx - 1
          local final_end = end_col_idx

          if #trimmed_line > max_code_len then
            local context_before = math.floor((max_code_len - match_len) / 2)
            local crop_start = math.max(1, start_col_idx - context_before)
            local crop_end = math.min(#trimmed_line, crop_start + max_code_len - 1)

            snippet = trimmed_line:sub(crop_start, crop_end)

            local prefix_dots = crop_start > 1 and "…" or ""
            local suffix_dots = crop_end < #trimmed_line and "…" or ""

            snippet = prefix_dots .. snippet .. suffix_dots

            final_start = (start_col_idx - crop_start) + #prefix_dots
            final_end = final_start + match_len
          end

          table.insert(matches, {
            lnum = idx,
            line_text = snippet,
            start_col = final_start,
            end_col = final_end,
          })
        end
      end
    end

    log_debug(string.format("Búsqueda off-screen de '%s': %d coincidencias encontradas.", display_word, #matches))
    return matches
  end

  local function update_offscreen_preview(new_word)
    if not (vim.api.nvim_buf_is_valid(preview_buf) and vim.api.nvim_win_is_valid(preview_win)) then
      return
    end

    vim.api.nvim_buf_clear_namespace(preview_buf, hl_ns, 0, -1)
    vim.bo[preview_buf].modifiable = true

    -- Buscamos el término renombrado en el buffer ya reemplazado
    local word_to_search = (new_word and new_word ~= "") and new_word or current_word
    local matches = get_offscreen_matches(word_to_search, word_to_search)

    if #matches == 0 then
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, { " (Sin coincidencia)" })
      vim.bo[preview_buf].modifiable = false
      return
    end

    local preview_lines = {}
    local line_prefixes = {}

    for _, m in ipairs(matches) do
      local prefix = string.format("L%d: ", m.lnum)
      table.insert(line_prefixes, prefix)
      table.insert(preview_lines, prefix .. m.line_text)
    end

    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, preview_lines)

    for i, m in ipairs(matches) do
      local prefix_len = #line_prefixes[i]
      local start_c = prefix_len + math.max(0, m.start_col)
      local end_c = prefix_len + math.max(0, m.end_col)

      vim.api.nvim_buf_add_highlight(preview_buf, hl_ns, "TridentLineNum", i - 1, 0, prefix_len)
      vim.api.nvim_buf_add_highlight(preview_buf, hl_ns, "TridentNeonRed", i - 1, start_c, end_c)
    end

    vim.bo[preview_buf].modifiable = false
  end

  -- LIVE PREVIEW EN EL BUFFER PRINCIPAL
  local function apply_live_preview(new_name)
    log_debug(string.format("Texto en Input: '%s'", new_name))

    if new_name ~= "" and not is_valid_identifier(new_name) then
      log_debug("Identificador inválido. Ignorando cambio temporal.")
      return
    end

    local input_cursor = vim.api.nvim_win_get_cursor(input_win)

    local save_lazy = vim.o.lazyredraw
    vim.o.lazyredraw = true

    -- Restaurar respaldo original antes del reemplazo
    vim.api.nvim_buf_set_lines(target_buf, 0, -1, false, lines_backup)

    if new_name ~= "" and new_name ~= current_word then
      local escaped_old = vim.fn.escape(current_word, "/\\.-")
      -- Solo escapamos barras en el lado de reemplazo (sin guiones)
      local escaped_new = vim.fn.escape(new_name, "/\\")

      local cmd = string.format("keepjumps silent! %%s/\\<\\C%s\\>/%s/g", escaped_old, escaped_new)
      log_debug(string.format("Ejecutando comando Vim: %s", cmd))

      local ok, err = pcall(function()
        vim.api.nvim_buf_call(target_buf, function()
          vim.cmd(cmd)
        end)
      end)

      if not ok then
        log_debug(string.format("ERROR en sustitución: %s", tostring(err)))
      end
    end

    if vim.api.nvim_win_is_valid(target_win) then
      vim.api.nvim_win_call(target_win, function()
        vim.fn.winrestview(saved_view)
      end)
    end

    -- Actualizar preview buscando la nueva palabra sobre el buffer ya reemplazado
    update_offscreen_preview(new_name)

    if vim.api.nvim_win_is_valid(input_win) then
      pcall(vim.api.nvim_win_set_cursor, input_win, input_cursor)
    end

    vim.o.lazyredraw = save_lazy
  end

  update_offscreen_preview(current_word)

  -- CONTROL Y BINDINGS
  local closed = false
  local function close_all()
    if closed then
      return
    end
    closed = true

    if vim.api.nvim_win_is_valid(input_win) then
      vim.api.nvim_win_close(input_win, true)
    end
    if vim.api.nvim_win_is_valid(preview_win) then
      vim.api.nvim_win_close(preview_win, true)
    end

    if vim.api.nvim_win_is_valid(target_win) then
      vim.api.nvim_win_call(target_win, function()
        vim.fn.winrestview(saved_view)
      end)
    end

    vim.cmd("stopinsert")
  end

  local function confirm()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
    local final_name = lines[1] or ""

    if not is_valid_identifier(final_name) and final_name ~= "" then
      vim.api.nvim_buf_set_lines(target_buf, 0, -1, false, lines_backup)
      log_debug(string.format("CONFIRMACIÓN CANCELADA: Nombre '%s' no es válido.", final_name))
      vim.notify("Trident: Cancelado. Formato de variable inválido.", vim.log.levels.ERROR)
    else
      log_debug(string.format("CONFIRMACIÓN EXITOSA: '%s' -> '%s'", current_word, final_name))
      vim.notify(string.format("Trident: '%s' -> '%s'", current_word, final_name), vim.log.levels.INFO)
    end

    close_all()
  end

  local function cancel()
    vim.api.nvim_buf_set_lines(target_buf, 0, -1, false, lines_backup)
    log_debug("RENOMBRADO CANCELADO POR EL USUARIO (ESC)")
    close_all()
    vim.notify("Trident: Renombrado cancelado", vim.log.levels.WARN)
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = input_buf,
    callback = function()
      if closed then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
      apply_live_preview(lines[1] or "")
    end,
  })

  vim.cmd("startinsert!")
  local col_end = #current_word
  vim.api.nvim_win_set_cursor(input_win, { 1, col_end })

  local opts = { noremap = true, silent = true, buffer = input_buf }
  vim.keymap.set({ "i", "n" }, "<CR>", confirm, opts)
  vim.keymap.set({ "i", "n" }, "<Esc>", cancel, opts)
end

return M
