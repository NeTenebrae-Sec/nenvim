local M = {}
local hl_ns_id = vim.api.nvim_create_namespace("trident_match_hl")
M.last_selected = nil

function M.close_floating_editor(win, buf)
  -- Si el buffer no ha sido modificado, cerramos directo
  if not (vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified) then
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    return true
  end

  -- 1. Crear buffer efímero para el diálogo de confirmación
  local confirm_buf = vim.api.nvim_create_buf(false, true)

  -- Línea 0: vacía
  -- Línea 1: "  You have unsaved changes!" (26 chars)
  -- Línea 2: vacía
  -- Línea 3: "  [Y]es, close anyway   |   [N]o, stay" (40 chars)
  local lines = {
    "",
    "  You have unsaved changes!",
    "",
    "  [Y]es, close anyway   |   [N]o, stay",
  }
  vim.api.nvim_buf_set_lines(confirm_buf, 0, -1, false, lines)

  -- 2. Dimensiones
  local width = 44
  local height = 5
  local parent_win_width = vim.api.nvim_win_get_width(win)
  local parent_win_height = vim.api.nvim_win_get_height(win)

  local row = math.max(0, math.floor((parent_win_height - height) / 2))
  local col = math.max(0, math.floor((parent_win_width - width) / 2))

  -- 3. Ventana flotante
  local confirm_win = vim.api.nvim_open_win(confirm_buf, true, {
    relative = "win",
    win = win,
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Unsaved Changes ",
    title_pos = "center",
  })

  vim.bo[confirm_buf].modifiable = false
  vim.bo[confirm_buf].bufhidden = "wipe"
  vim.wo[confirm_win].cursorline = false

  -- 4. Resaltar con extmark (Rangos corregidos 0-indexed)
  local ns = vim.api.nvim_create_namespace("trident_confirm")

  -- Línea index 1 ("  You have unsaved changes!") -> destaca "You have unsaved changes!"
  vim.api.nvim_buf_set_extmark(confirm_buf, ns, 1, 2, {
    end_row = 1,
    end_col = 25,
    hl_group = "WarningMsg",
  })

  -- Línea index 3 ("  [Y]es, close anyway   |   [N]o, stay")
  -- Destaca "[Y]es, close anyway" (col 2 a 21)
  vim.api.nvim_buf_set_extmark(confirm_buf, ns, 3, 2, {
    end_row = 3,
    end_col = 21,
    hl_group = "Keyword",
  })

  -- Destaca "[N]o, stay" (col 28 a 38)
  vim.api.nvim_buf_set_extmark(confirm_buf, ns, 3, 28, {
    end_row = 3,
    end_col = 38,
    hl_group = "Comment",
  })

  local function close_modal()
    if vim.api.nvim_win_is_valid(confirm_win) then
      vim.api.nvim_win_close(confirm_win, true)
    end
  end

  local function on_yes()
    close_modal()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function on_no()
    close_modal()
  end

  -- Mapeos locales
  local opts = { buffer = confirm_buf, silent = true, nowait = true }
  vim.keymap.set("n", "y", on_yes, opts)
  vim.keymap.set("n", "Y", on_yes, opts)
  vim.keymap.set("n", "<CR>", on_yes, opts)

  vim.keymap.set("n", "n", on_no, opts)
  vim.keymap.set("n", "N", on_no, opts)
  vim.keymap.set("n", "q", on_no, opts)
  vim.keymap.set("n", "<Esc>", on_no, opts)
end
function M.open_floating_editor(filepath, lnum, col_idx, filter_label)
  M.last_selected = { file = filepath, lnum = lnum, col = col_idx, label = filter_label }

  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  local buf = vim.fn.bufadd(abs_path)
  vim.fn.bufload(buf)

  -- Limpia estado modificado erróneo generado al cargar el archivo en segundo plano
  vim.bo[buf].modified = false

  vim.api.nvim_buf_clear_namespace(buf, hl_ns_id, 0, -1)

  local width = math.floor(vim.o.columns * 0.60)
  local height = math.floor(vim.o.lines * 0.60)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local fname = vim.fn.fnamemodify(filepath, ":t")

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" %s ", fname),
    title_pos = "center",
    footer = string.format(" %s ", filter_label),
    footer_pos = "center",
  })

  vim.wo[win].number = true
  vim.wo[win].cursorline = true

  local ft = vim.filetype.match({ filename = abs_path, buf = buf })
  if ft then
    vim.bo[buf].filetype = ft
    pcall(vim.treesitter.start, buf, ft)
  end

  -- Restablece modified = false por si la activación del filetype/treesitter lo cambió
  vim.bo[buf].modified = false

  local lnum_num = tonumber(lnum)
  if lnum_num and lnum_num > 0 then
    local line_count = vim.api.nvim_buf_line_count(buf)
    local target_line = math.min(lnum_num, line_count)
    local target_col = math.max(0, tonumber(col_idx) or 0)

    vim.api.nvim_win_set_cursor(win, { target_line, target_col })
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zz")
    end)
  end

  local opts = { buffer = buf, silent = true }
  vim.keymap.set("n", "q", function()
    M.close_floating_editor(win, buf)
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    M.close_floating_editor(win, buf)
  end, opts)
end

return M
