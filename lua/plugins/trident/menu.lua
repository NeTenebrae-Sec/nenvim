local editor = require("plugins.trident.editor")
local M = {}

local ns_id = vim.api.nvim_create_namespace("trident_ui")
local hl_ns_id = vim.api.nvim_create_namespace("trident_match_hl")

function M.open_selection_menu(results, filter_label, word)
  local total_width = math.floor(vim.o.columns * 0.70)
  local total_height = 10
  local row = math.floor((vim.o.lines - total_height) / 2)

  local list_width = math.floor(total_width * 0.35)
  local preview_width = total_width - list_width - 2

  local list_col = math.floor((vim.o.columns - total_width) / 2)
  local preview_col = list_col + list_width + 2

  -- 1. PANEL IZQUIERDO (LISTA)
  local list_buf = vim.api.nvim_create_buf(false, true)
  local list_lines = {}
  local max_fname_len = 0

  for _, r in ipairs(results) do
    local fn = vim.fn.fnamemodify(r.file, ":t")
    if #fn > max_fname_len then
      max_fname_len = #fn
    end
  end

  for _, r in ipairs(results) do
    local fname = vim.fn.fnamemodify(r.file, ":t")
    local pos_str = string.format("%d:%d", r.lnum, r.col + 1)
    table.insert(list_lines, string.format(" %-" .. max_fname_len .. "s  %s", fname, pos_str))
  end

  vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, list_lines)

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

  for i, _ in ipairs(results) do
    local l_idx = i - 1
    vim.api.nvim_buf_add_highlight(list_buf, ns_id, "Directory", l_idx, 1, 1 + max_fname_len)
    vim.api.nvim_buf_add_highlight(list_buf, ns_id, "LineNr", l_idx, 1 + max_fname_len, -1)
  end

  vim.wo[list_win].cursorline = true
  vim.bo[list_buf].modifiable = false
  vim.bo[list_buf].bufhidden = "wipe"

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

  local function update_preview()
    if not vim.api.nvim_win_is_valid(list_win) then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(list_win)
    local item = results[cursor[1]]
    if not item then
      return
    end

    if active_preview_buf and vim.api.nvim_buf_is_valid(active_preview_buf) then
      vim.api.nvim_buf_clear_namespace(active_preview_buf, hl_ns_id, 0, -1)
    end

    local abs_path = vim.fn.fnamemodify(item.file, ":p")
    local p_buf = vim.fn.bufadd(abs_path)
    vim.fn.bufload(p_buf)

    -- Asegura que la vista previa no marque modificados falsos
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
      title = string.format(" Preview: %s ", item.file),
      title_pos = "center",
    })
  end

  local augroup = vim.api.nvim_create_augroup("TridentPreviewSync", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    buffer = list_buf,
    callback = update_preview,
  })

  update_preview()

  -- Cierre limpio sin preguntas de paranoia al previsualizar
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
    local item = results[cursor[1]]
    cleanup_and_close()
    if item then
      editor.open_floating_editor(item.file, item.lnum, item.col, filter_label)
    end
  end

  local opts = { buffer = list_buf, silent = true }
  vim.keymap.set("n", "<CR>", confirm, opts)
  vim.keymap.set("n", "q", cleanup_and_close, opts)
  vim.keymap.set("n", "<Esc>", cleanup_and_close, opts)
end

return M
