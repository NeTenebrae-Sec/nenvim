-- =========================================================
-- Sticky context propio (reemplaza treesitter-context —
-- tarea 012 Fase 2). Muestra los scopes envolventes del cursor
-- (funciones/clases/loops…) en un float pinned al tope de la
-- ventana, solo cuando su cabecera quedó fuera de pantalla.
-- Versión lite: sin números de columna propios ni queries por
-- lenguaje (heurística de tipos de nodo, máximo 3 scopes).
-- =========================================================

local api = vim.api

local M = {}

local MAX_CONTEXTS = 3
local MAX_FILE_LINES = 3000
local MIN_WIN_HEIGHT = 8
local DEBOUNCE = 50

-- Nota: sin alternación `|` (no existe en Lua patterns) — lista de keywords
local CONTEXT_TYPES = {
  "function", "method", "class", "interface", "struct", "enum",
  "for", "while", "if", "switch", "try", "loop", "match", "impl",
  "component", "arrow",
}

local function is_context_type(t)
  for _, kw in ipairs(CONTEXT_TYPES) do
    if t:find(kw, 1, true) then
      return true
    end
  end
  return false
end

api.nvim_set_hl(0, "NlContext", { fg = "#d0dce5", bg = "#10171c", default = true })
api.nvim_set_hl(0, "NlContextNum", { fg = "#92a7b5", bg = "#10171c", default = true })

-- winid -> { buf, win }
local floats = {}
local timers = {}
local ns = api.nvim_create_namespace("nete.context")

local function close_float(win)
  local f = floats[win]
  if not f then
    return
  end
  floats[win] = nil
  if f.win and api.nvim_win_is_valid(f.win) then
    api.nvim_win_close(f.win, true)
  end
  if f.buf and api.nvim_buf_is_valid(f.buf) then
    api.nvim_buf_delete(f.buf, { force = true })
  end
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function update(win)
  if not api.nvim_win_is_valid(win) then
    close_float(win)
    return
  end

  local buf = api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or api.nvim_buf_line_count(buf) > MAX_FILE_LINES then
    close_float(win)
    return
  end
  if vim.api.nvim_win_get_height(win) < MIN_WIN_HEIGHT then
    close_float(win)
    return
  end

  local ok_parser = pcall(vim.treesitter.get_parser, buf)
  if not ok_parser then
    close_float(win)
    return
  end

  local cursor = api.nvim_win_get_cursor(win)
  local topline = api.nvim_win_call(win, function()
    return vim.fn.line("w0")
  end)

  local ok_node, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { cursor[1] - 1, cursor[2] } })
  if not ok_node or not node then
    close_float(win)
    return
  end

  -- Scopes envolventes (innermost primero), cap de MAX_CONTEXTS
  local contexts = {}
  local cur = node
  while cur and #contexts < MAX_CONTEXTS do
    local t = cur:type()
    if is_context_type(t) then
      local srow, _, erow = cur:range()
      if erow > srow and srow < cursor[1] - 1 then
        contexts[#contexts + 1] = { row = srow, multiline = erow > srow }
      end
    end
    cur = cur:parent()
  end

  -- Solo los que quedaron fuera de pantalla (topline)
  local hidden = {}
  for i = #contexts, 1, -1 do
    if contexts[i].row < topline - 1 then
      table.insert(hidden, contexts[i])
    end
  end
  if #hidden == 0 then
    close_float(win)
    return
  end

  -- Líneas de contexto
  local width = api.nvim_win_get_width(win)
  local lines, marks = {}, {}
  for i, c in ipairs(hidden) do
    local text = trim((api.nvim_buf_get_text(buf, c.row, 0, c.row, -1, {})[1] or ""))
    local suffix = c.multiline and " …" or ""
    local max_text = width - 12
    if vim.fn.strdisplaywidth(text) > max_text then
      text = vim.fn.strcharpart(text, 0, max_text - 1) .. "…"
    end
    lines[i] = ("%4d │ %s%s"):format(c.row + 1, text, suffix)
    marks[i] = { num_end = 6 }
  end

  -- Float (uno por ventana, reutilizado)
  local f = floats[win]
  if not f or not api.nvim_buf_is_valid(f.buf) or not api.nvim_win_is_valid(f.win) then
    local fbuf = api.nvim_create_buf(false, true)
    local fwin = api.nvim_open_win(fbuf, false, {
      relative = "win",
      win = win,
      row = 0,
      col = 0,
      width = width,
      height = #lines,
      style = "minimal",
      focusable = false,
      zindex = 40,
    })
    vim.wo[fwin].winhl = "Normal:NlContext"
    vim.wo[fwin].wrap = false
    f = { buf = fbuf, win = fwin }
    floats[win] = f
  end

  if not api.nvim_win_is_valid(f.win) then
    floats[win] = nil
    return
  end

  api.nvim_win_set_config(f.win, { relative = "win", win = win, row = 0, col = 0, width = width, height = #lines })
  api.nvim_buf_set_option(f.buf, "modifiable", true)
  api.nvim_buf_set_lines(f.buf, 0, -1, false, lines)
  api.nvim_buf_set_option(f.buf, "modifiable", false)

  local ns_ctx = ns
  api.nvim_buf_clear_namespace(f.buf, ns_ctx, 0, -1)
  for i, line in ipairs(lines) do
    pcall(api.nvim_buf_set_extmark, f.buf, ns_ctx, i - 1, 0, { hl_group = "NlContext", hl_eol = true, end_row = i - 1, end_col = #line })
    pcall(api.nvim_buf_set_extmark, f.buf, ns_ctx, i - 1, 0, { hl_group = "NlContextNum", end_row = i - 1, end_col = marks[i].num_end })
  end
end

local function schedule_update(win)
  local old = timers[win]
  timers[win] = nil
  if old and not old:is_closing() then
    old:stop()
    old:close()
  end
  local t = vim.uv.new_timer()
  timers[win] = t
  t:start(DEBOUNCE, 0, vim.schedule_wrap(function()
    timers[win] = nil
    if not t:is_closing() then
      t:stop()
      t:close()
    end
    update(win)
  end))
end

local group = api.nvim_create_augroup("NvimContext", { clear = true })
for _, ev in ipairs({ "CursorMoved", "WinScrolled", "WinEnter", "BufWinEnter", "InsertLeave", "VimResized" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function()
      schedule_update(api.nvim_get_current_win())
    end,
  })
end
api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function(args)
    local win = tonumber(args.match)
    if win then
      close_float(win)
    end
  end,
})
api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    for win, f in pairs(floats) do
      if f.buf == args.buf or (f.win and api.nvim_win_is_valid(f.win) and api.nvim_win_get_buf(f.win) == args.buf) then
        close_float(win)
      end
    end
  end,
})

return M
