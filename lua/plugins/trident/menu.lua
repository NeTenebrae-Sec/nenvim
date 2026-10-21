local editor = require("plugins.trident.editor")
local M = {}

local ns_id = vim.api.nvim_create_namespace("trident_ui")
local hl_ns_id = vim.api.nvim_create_namespace("trident_match_hl")

local function get_short_path(filepath)
  local fname = vim.fn.fnamemodify(filepath, ":t")
  local parent1 = vim.fn.fnamemodify(filepath, ":h:t")
  local parent2 = vim.fn.fnamemodify(filepath, ":h:h:t")

  if parent2 ~= "" and parent2 ~= "." and parent2 ~= "/" then
    return string.format("%s/%s/%s", parent2, parent1, fname)
  elseif parent1 ~= "" and parent1 ~= "." then
    return string.format("%s/%s", parent1, fname)
  end

  return fname
end

function M.open_selection_menu(results, filter_label, word)
  local total_width = math.floor(vim.o.columns * 0.75)
  local total_height = 12
  local row = math.floor((vim.o.lines - total_height) / 2)

  local list_width = math.floor(total_width * 0.40)
  local preview_width = total_width - list_width - 2

  local list_col = math.floor((vim.o.columns - total_width) / 2)
  local preview_col = list_col + list_width + 2

  -- Agrupar resultados por archivo manteniendo el orden
  local grouped_results = {}
  local file_order = {}
  for _, r in ipairs(results) do
    if not grouped_results[r.file] then
      grouped_results[r.file] = {}
      table.insert(file_order, r.file)
    end
    table.insert(grouped_results[r.file], r)
  end

  local single_file_mode = (#file_order == 1)
  local current_level = single_file_mode and "matches" or "files"
  local active_file = single_file_mode and file_order[1] or nil

  -- 1. PANEL IZQUIERDO (LISTA)
  local list_buf = vim.api.nvim_create_buf(false, true)
  local list_win = vim.api.nvim_open_win(list_buf, true, {
    relative = "editor",
    width = list_width,
    height = total_height,
    row = row,
    col = list_col,
    style = "minimal",
    border = "rounded",
    title = string.format(" Trident: %s ", word or ""),
    title_pos = "center",
    footer = string.format(" %s ", filter_label),
    footer_pos = "center",
  })

  vim.wo[list_win].cursorline = true

  -- 2. PANEL DERECHO (PREVIEW)
  local preview_buf = vim.api.nvim_create_buf(false, true)
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    width = preview_width,
    height = total_height,
    row = row,
    col = preview_col,
    style = "minimal",
    border = "rounded",
    title = " Preview ",
    title_pos = "center",
  })

  local active_preview_buf = nil
  local update_preview

  -- Renderizar la lista del panel izquierdo
  local function render_list()
    vim.bo[list_buf].modifiable = true
    vim.api.nvim_buf_clear_namespace(list_buf, ns_id, 0, -1)
    local lines = {}

    if current_level == "files" then
      for _, fname in ipairs(file_order) do
        local count = #grouped_results[fname]
        local display_name = get_short_path(fname)
        table.insert(lines, string.format(" %s  (%d)", display_name, count))
      end
      vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)

      for i, fname in ipairs(file_order) do
        local display_name = get_short_path(fname)
        -- Buscar el ÚLTIMO '/' para separar toda la ruta del nombre del archivo
        local last_slash_idx = display_name:match(".*()/")

        if last_slash_idx then
          -- 1. Pinta las carpetas (ej: "plugins/trident/") en gris/comentario
          vim.api.nvim_buf_add_highlight(list_buf, ns_id, "Comment", i - 1, 1, 1 + last_slash_idx)
          -- 2. Pinta el nombre del archivo (ej: "menu.lua") destacado con el color de Directory
          vim.api.nvim_buf_add_highlight(list_buf, ns_id, "Directory", i - 1, 1 + last_slash_idx, 1 + #display_name)
        else
          vim.api.nvim_buf_add_highlight(list_buf, ns_id, "Directory", i - 1, 1, 1 + #display_name)
        end

        -- Pinta el contador de coincidencias "(X)"
        vim.api.nvim_buf_add_highlight(list_buf, ns_id, "Number", i - 1, 1 + #display_name, -1)
      end
    else
      local matches = grouped_results[active_file] or {}
      for _, r in ipairs(matches) do
        local pos_str = string.format("%d:%d", r.lnum, r.col + 1)
        table.insert(lines, string.format(" %-7s %s", pos_str, r.text_trim or ""))
      end
      vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)

      for i, _ in ipairs(matches) do
        vim.api.nvim_buf_add_highlight(list_buf, ns_id, "LineNr", i - 1, 1, 8)
      end
    end

    vim.bo[list_buf].modifiable = false
  end
  local function load_preview_buffer(filepath)
    if active_preview_buf and vim.api.nvim_buf_is_valid(active_preview_buf) then
      vim.api.nvim_buf_clear_namespace(active_preview_buf, hl_ns_id, 0, -1)
    end

    local abs_path = vim.fn.fnamemodify(filepath, ":p")
    local p_buf = vim.fn.bufadd(abs_path)
    vim.fn.bufload(p_buf)
    vim.bo[p_buf].modified = false
    active_preview_buf = p_buf

    local ft = vim.filetype.match({ filename = abs_path, buf = p_buf })
    if ft then
      vim.bo[p_buf].filetype = ft
      pcall(vim.treesitter.start, p_buf, ft)
    end
    vim.bo[p_buf].modified = false

    vim.api.nvim_win_set_buf(preview_win, p_buf)
    vim.wo[preview_win].number = true
    vim.wo[preview_win].cursorline = true
    vim.wo[preview_win].wrap = false

    return p_buf
  end

  update_preview = function()
    if not vim.api.nvim_win_is_valid(list_win) then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(list_win)
    local idx = cursor[1]

    if current_level == "files" then
      local target_file = file_order[idx]
      if not target_file then
        return
      end

      local p_buf = load_preview_buffer(target_file)
      local file_matches = grouped_results[target_file] or {}

      for _, m in ipairs(file_matches) do
        if m.lnum and m.lnum > 0 then
          vim.api.nvim_buf_add_highlight(p_buf, hl_ns_id, "Search", m.lnum - 1, m.col, m.col + #word)
        end
      end

      if file_matches[1] then
        local line_cnt = vim.api.nvim_buf_line_count(p_buf)
        local target = math.min(file_matches[1].lnum, line_cnt)
        vim.api.nvim_win_set_cursor(preview_win, { target, file_matches[1].col or 0 })
        vim.api.nvim_win_call(preview_win, function()
          vim.cmd("normal! zz")
        end)
      end

      vim.api.nvim_win_set_config(preview_win, {
        relative = "editor",
        width = preview_width,
        height = total_height,
        row = row,
        col = preview_col,
        title = string.format(" Preview: %s (%d matches) ", get_short_path(target_file), #file_matches),
        title_pos = "center",
      })
    elseif current_level == "matches" then
      local matches = grouped_results[active_file] or {}
      local item = matches[idx]
      if not item then
        return
      end

      local p_buf = load_preview_buffer(item.file)

      if item.lnum and item.lnum > 0 then
        local line_cnt = vim.api.nvim_buf_line_count(p_buf)
        local target = math.min(item.lnum, line_cnt)
        local target_col = math.max(0, item.col or 0)

        vim.api.nvim_win_set_cursor(preview_win, { target, target_col })
        vim.api.nvim_win_call(preview_win, function()
          vim.cmd("normal! zz")
        end)

        if word and #word > 0 then
          vim.api.nvim_buf_add_highlight(p_buf, hl_ns_id, "Search", target - 1, target_col, target_col + #word)
        end
      end

      vim.api.nvim_win_set_config(preview_win, {
        relative = "editor",
        width = preview_width,
        height = total_height,
        row = row,
        col = preview_col,
        title = string.format(" Preview: %s ", get_short_path(item.file)),
        title_pos = "center",
      })
    end
  end

  local augroup = vim.api.nvim_create_augroup("TridentPreviewSync", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    buffer = list_buf,
    callback = update_preview,
  })

  render_list()
  update_preview()

  local function cleanup_and_close()
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
    if active_preview_buf and vim.api.nvim_buf_is_valid(active_preview_buf) then
      vim.api.nvim_buf_clear_namespace(active_preview_buf, hl_ns_id, 0, -1)
    end
    if vim.api.nvim_win_is_valid(list_win) then
      vim.api.nvim_win_close(list_win, true)
    end
    if vim.api.nvim_win_is_valid(preview_win) then
      vim.api.nvim_win_close(preview_win, true)
    end
    return true
  end

  local function confirm()
    local cursor = vim.api.nvim_win_get_cursor(list_win)
    local idx = cursor[1]

    if current_level == "files" then
      active_file = file_order[idx]
      local matches = grouped_results[active_file] or {}

      -- Si el archivo seleccionado tiene solo 1 coincidencia, abre el editor directamente
      if #matches == 1 then
        local item = matches[1]
        cleanup_and_close()
        if item then
          editor.open_floating_editor(item.file, item.lnum, item.col, filter_label)
        end
      else
        -- Si tiene 2 o más coincidencias, entra al nivel de selección de línea
        current_level = "matches"
        render_list()
        vim.api.nvim_win_set_cursor(list_win, { 1, 0 })
        update_preview()
      end
    else
      local matches = grouped_results[active_file] or {}
      local item = matches[idx]
      cleanup_and_close()
      if item then
        editor.open_floating_editor(item.file, item.lnum, item.col, filter_label)
      end
    end
  end
  local function go_back()
    if current_level == "matches" and not single_file_mode then
      current_level = "files"
      render_list()
      vim.api.nvim_win_set_cursor(list_win, { 1, 0 })
      update_preview()
    else
      cleanup_and_close()
    end
  end

  local opts = { buffer = list_buf, silent = true }
  vim.keymap.set("n", "<CR>", confirm, opts)
  vim.keymap.set("n", "<BS>", go_back, opts)
  vim.keymap.set("n", "-", go_back, opts)
  vim.keymap.set("n", "q", cleanup_and_close, opts)
  vim.keymap.set("n", "<Esc>", cleanup_and_close, opts)
end

return M
