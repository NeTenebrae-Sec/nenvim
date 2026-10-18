-- =========================================================
-- Git signs propio (reemplaza gitsigns.nvim — tarea 012 Fase 2)
-- diff en tiempo real buffer-vs-HEAD vía `vim.diff` (en proceso,
-- síncrono) sobre un baseline de HEAD cacheado. signs vía
-- extmarks en la signcolumn, preview/reset de hunk y blame.
-- API compatible con los keymaps previos: reset_hunk(range),
-- preview_hunk(), blame_line(), stats(bufnr) para la statusline.
-- =========================================================

local api = vim.api

local M = {}

local ns = api.nvim_create_namespace("nete.gitsigns")
local preview_ns = api.nvim_create_namespace("nete.gitsigns.preview")

local MAX_LINES = 10000
local UNTRACKED_MAX = 3000
local DEBOUNCE = 250

-- bufnr -> { root, rel, hunks, stats = { add, change, del } }
local state = {}
local timers = {}

-- =========================================================
-- Highlight groups (paridad con los signs previos)
-- =========================================================
api.nvim_set_hl(0, "GitSignsAdd", { link = "DiagnosticOk", default = true })
api.nvim_set_hl(0, "GitSignsChange", { link = "DiagnosticWarn", default = true })
api.nvim_set_hl(0, "GitSignsDelete", { link = "DiagnosticError", default = true })
api.nvim_set_hl(0, "GitSignsChangedelete", { link = "DiagnosticWarn", default = true })
api.nvim_set_hl(0, "GitSignsUntracked", { link = "Comment", default = true })
api.nvim_set_hl(0, "GitSignsPreviewAdd", { link = "DiagnosticOk", default = true })
api.nvim_set_hl(0, "GitSignsPreviewDel", { link = "DiagnosticError", default = true })

-- =========================================================
-- Glyphs de sign (box-drawing Unicode vía nr2char)
-- ASCII puro en el fuente (no se pierden al escribir) y
-- renderizan en cualquier font monoespaciada, sin Nerd Font.
-- =========================================================
local GLYPH_ADD = vim.fn.nr2char(0x2503)        -- ┃
local GLYPH_CHANGE = vim.fn.nr2char(0x2503)     -- ┃ (color lo distingue)
local GLYPH_DELETE = vim.fn.nr2char(0x2581)     -- ▁
local GLYPH_CHANGEDELETE = vim.fn.nr2char(0x2503) -- ┃
local GLYPH_UNTRACKED = vim.fn.nr2char(0x2506)  -- ┆

-- Texto del buffer tal como git lo vería (líneas + \n final)
local function buf_text(bufnr)
  return table.concat(api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
end

-- =========================================================
-- Diff parsing
-- =========================================================
local function parse_hunks(stdout)
  local hunks = {}
  for line in (stdout or ""):gmatch("[^\n]+") do
    local old_s, old_c, new_s, new_c = line:match("^@@ %-(%d+)%,?(%d*) %+(%d+)%,?(%d*) @@")
    if old_s then
      hunks[#hunks + 1] = {
        header = line,
        old_s = tonumber(old_s),
        old_c = tonumber(old_c) or 1,
        new_s = tonumber(new_s),
        new_c = tonumber(new_c) or 1,
        body = {},
      }
    elseif #hunks > 0 then
      local c = line:sub(1, 1)
      if c == "+" or c == "-" or line:sub(1, 3) == "\\ No" then
        table.insert(hunks[#hunks].body, line)
      end
    end
  end
  return hunks
end

-- =========================================================
-- Sign placement
-- =========================================================
local function place(bufnr, row, glyph, hl)
  local line_count = api.nvim_buf_line_count(bufnr)
  row = math.max(1, math.min(row, line_count))
  pcall(api.nvim_buf_set_extmark, bufnr, ns, row - 1, 0, {
    sign_text = glyph,
    sign_hl_group = hl,
    priority = 9,
    hl_mode = "combine",
  })
end

local function clear(bufnr)
  pcall(api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
  state[bufnr] = nil
end

local function apply(bufnr, root, rel, diff_text, untracked, baseline)
  clear(bufnr)
  local hunks = parse_hunks(diff_text)

  local stats = { add = 0, change = 0, del = 0 }

  for _, h in ipairs(hunks) do
    if h.old_c == 0 then
      -- Adición pura
      for i = 0, h.new_c - 1 do
        place(bufnr, h.new_s + i, GLYPH_ADD, "GitSignsAdd")
      end
      stats.add = stats.add + h.new_c
    elseif h.new_c == 0 then
      -- Borrado: sign en la línea donde ocurrió
      if h.new_s == 0 then
        place(bufnr, 1, GLYPH_DELETE, "GitSignsDelete")
      else
        place(bufnr, h.new_s, GLYPH_DELETE, "GitSignsDelete")
      end
      stats.del = stats.del + h.old_c
    else
      -- Cambio (posiblemente changedelete)
      local hl = (h.old_c > h.new_c) and "GitSignsChangedelete" or "GitSignsChange"
      local glyph = (hl == "GitSignsChangedelete") and GLYPH_CHANGEDELETE or GLYPH_CHANGE
      for i = 0, h.new_c - 1 do
        place(bufnr, h.new_s + i, glyph, hl)
      end
      stats.change = stats.change + h.new_c
      if h.old_c > h.new_c then
        stats.del = stats.del + (h.old_c - h.new_c)
      end
    end
  end

  if untracked and #hunks == 0 then
    local count = math.min(api.nvim_buf_line_count(bufnr), UNTRACKED_MAX)
    for i = 1, count do
      place(bufnr, i, GLYPH_UNTRACKED, "GitSignsUntracked")
    end
    stats.add = count
  end

  state[bufnr] = { root = root, rel = rel, hunks = hunks, stats = stats, untracked = untracked, baseline = baseline }

  api.nvim_exec_autocmds("User", { pattern = "NvimGitSignsUpdate", modeline = false })
end

-- =========================================================
-- Update (en tiempo real, con baseline HEAD cacheado)
-- =========================================================
-- Vía rápida (sync): si ya hay baseline de HEAD para este root/rel,
-- diff buffer-vs-HEAD con vim.diff en proceso — instantáneo al editar.
-- Vía fetch (async): si no hay baseline (primer load, o force), obtiene
-- `git show HEAD:<rel>` + `git status` y cachea; luego aplica.
local function run_update(bufnr, force)
  if not api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.bo[bufnr].buftype ~= "" then
    return
  end
  local file = api.nvim_buf_get_name(bufnr)
  if file == "" then
    return
  end
  if api.nvim_buf_line_count(bufnr) > MAX_LINES then
    return
  end

  local dir = vim.fs.dirname(file)
  local git_dir = vim.fs.find(".git", { path = dir, upward = true })[1]
  if not git_dir then
    clear(bufnr)
    return
  end
  local root = vim.fs.dirname(git_dir)
  local rel = file:sub(#root + 2)

  local s = state[bufnr]
  if not force and s and s.root == root and s.rel == rel and s.baseline ~= nil then
    -- Vía rápida: sync contra baseline cacheado
    local ok, diff = pcall(vim.diff, s.baseline, buf_text(bufnr), { result_type = "unified", ctxlen = 0 })
    apply(bufnr, root, rel, ok and diff or nil, s.untracked, s.baseline)
    return
  end

  -- Vía fetch: baseline HEAD + untracked (async)
  local pending = 2
  local baseline, untracked
  local function finish()
    pending = pending - 1
    if pending > 0 then
      return
    end
    if not api.nvim_buf_is_valid(bufnr) then
      return
    end
    local diff
    if baseline then
      local ok
      ok, diff = pcall(vim.diff, baseline, buf_text(bufnr), { result_type = "unified", ctxlen = 0 })
      if not ok then
        diff = nil
      end
    end
    apply(bufnr, root, rel, diff, untracked, baseline)
  end

  local ok1 = pcall(vim.system, { "git", "-C", root, "show", "HEAD:" .. rel }, { text = true }, function(out)
    if out.code == 0 then
      baseline = out.stdout
    end
    vim.schedule(finish)
  end)
  local ok2 = pcall(vim.system, { "git", "-C", root, "status", "--porcelain=v1", "--", rel }, { text = true }, function(out)
    untracked = out.stdout and out.stdout:sub(1, 2) == "??"
    vim.schedule(finish)
  end)
  if not (ok1 and ok2) then
    clear(bufnr)
  end
end

function M.update(bufnr, force)
  run_update(bufnr or api.nvim_get_current_buf(), force)
end

local function schedule_update(bufnr, force)
  local old = timers[bufnr]
  timers[bufnr] = nil
  if old and not old:is_closing() then
    old:stop()
    old:close()
  end
  local t = vim.uv.new_timer()
  timers[bufnr] = t
  t:start(DEBOUNCE, 0, vim.schedule_wrap(function()
    timers[bufnr] = nil
    if not t:is_closing() then
      t:stop()
      t:close()
    end
    run_update(bufnr, force)
  end))
end

-- =========================================================
-- API pública
-- =========================================================
function M.stats(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = api.nvim_get_current_buf()
  end
  local s = state[bufnr]
  return s and s.stats or nil
end

local function hunk_at_cursor(bufnr)
  local s = state[bufnr]
  if not s then
    return nil
  end
  local line = api.nvim_win_get_cursor(0)[1]
  for _, h in ipairs(s.hunks) do
    local hs = h.new_s
    local he = h.new_s + math.max(h.new_c, 1) - 1
    if line >= hs and line <= he then
      return h
    end
  end
  return nil
end

function M.preview_hunk()
  local bufnr = api.nvim_get_current_buf()
  local h = hunk_at_cursor(bufnr)
  if not h then
    vim.notify("GitSigns: no hunk under cursor", vim.log.levels.INFO)
    return
  end

  local lines = { h.header }
  for _, l in ipairs(h.body) do
    lines[#lines + 1] = l
  end

  local pbuf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(pbuf, 0, -1, false, lines)
  api.nvim_buf_set_option(pbuf, "modifiable", false)

  for i, l in ipairs(lines) do
    local hl = "Comment"
    if i > 1 then
      local c = l:sub(1, 1)
      if c == "+" then
        hl = "GitSignsPreviewAdd"
      elseif c == "-" then
        hl = "GitSignsPreviewDel"
      end
    end
    pcall(api.nvim_buf_set_extmark, pbuf, preview_ns, i - 1, 0, {
      end_row = i,
      end_col = 0,
      hl_group = hl,
      hl_eol = true,
    })
  end

  local width = 20
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width, vim.o.columns - 4)

  local pwin = api.nvim_open_win(pbuf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 60,
  })
  vim.wo[pwin].winhl = "Normal:NormalFloat,BorderFloat:FloatBorder"

  local group = api.nvim_create_augroup("NvimGitSignsPreview" .. bufnr, { clear = true })
  local function close()
    if api.nvim_win_is_valid(pwin) then
      api.nvim_win_close(pwin, true)
    end
    if api.nvim_buf_is_valid(pbuf) then
      api.nvim_buf_delete(pbuf, { force = true })
    end
    api.nvim_del_augroup_by_id(group)
  end
  for _, ev in ipairs({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufWinLeave" }) do
    api.nvim_create_autocmd(ev, { group = group, once = true, callback = close })
  end
end

function M.reset_hunk(range)
  local bufnr = api.nvim_get_current_buf()
  local s = state[bufnr]
  if not s or #s.hunks == 0 then
    return
  end

  local targets = {}
  if range then
    for _, h in ipairs(s.hunks) do
      local hs = h.new_s
      local he = h.new_s + math.max(h.new_c, 1) - 1
      if he >= range[1] and hs <= range[2] then
        targets[#targets + 1] = h
      end
    end
  else
    local h = hunk_at_cursor(bufnr)
    if h then
      targets[1] = h
    end
  end

  if #targets == 0 then
    vim.notify("GitSigns: no hunk to reset", vim.log.levels.INFO)
    return
  end

  -- Revertir en el buffer contra HEAD (no en disco): para cada hunk de
  -- abajo hacia arriba (evita desplazar posiciones), reemplazar las
  -- líneas del hunk por las del baseline (las líneas '-' del body).
  table.sort(targets, function(a, b)
    return a.new_s > b.new_s
  end)
  for _, h in ipairs(targets) do
    local old = {}
    for _, l in ipairs(h.body) do
      if l:sub(1, 1) == "-" then
        old[#old + 1] = l:sub(2)
      end
    end
    pcall(api.nvim_buf_set_lines, bufnr, h.new_s - 1, h.new_s - 1 + h.new_c, false, old)
  end

  run_update(bufnr, false)
end

function M.blame_line()
  local bufnr = api.nvim_get_current_buf()
  local s = state[bufnr]
  if not s then
    return
  end
  local row = api.nvim_win_get_cursor(0)[1]

  local ok = pcall(vim.system, { "git", "-C", s.root, "blame", "-L", row .. "," .. row, "--porcelain", "HEAD", "--", s.rel }, { text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify("GitSigns: blame failed — " .. (out.stderr or "unknown error"), vim.log.levels.WARN)
        return
      end
      local sha, author, when, summary = "", "", "", ""
      for line in (out.stdout or ""):gmatch("[^\n]+") do
        if sha == "" then
          sha = line:match("^(%x+)")
        elseif line:match("^author ") then
          author = line:match("^author (.+)$") or ""
        elseif line:match("^author%-time ") then
          when = os.date("%Y-%m-%d", tonumber(line:match("^author%-time (%d+)") or "0") or 0)
        elseif line:match("^summary ") then
          summary = line:match("^summary (.+)$") or ""
        end
      end
      local text = ("%s  %s  %s  —  %s"):format((sha or ""):sub(1, 8), author, when, summary)
      local width = math.min(vim.fn.strdisplaywidth(text) + 2, vim.o.columns - 4)

      local bbuf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_lines(bbuf, 0, -1, false, { text })
      api.nvim_buf_set_option(bbuf, "modifiable", false)
      local bwin = api.nvim_open_win(bbuf, false, {
        relative = "cursor",
        row = 1,
        col = 0,
        width = width,
        height = 1,
        style = "minimal",
        border = "rounded",
        focusable = false,
        zindex = 60,
      })
      vim.wo[bwin].winhl = "Normal:NormalFloat,BorderFloat:FloatBorder"

      local group = api.nvim_create_augroup("NvimGitSignsBlame" .. bufnr, { clear = true })
      local function close()
        if api.nvim_win_is_valid(bwin) then
          api.nvim_win_close(bwin, true)
        end
        if api.nvim_buf_is_valid(bbuf) then
          api.nvim_buf_delete(bbuf, { force = true })
        end
        api.nvim_del_augroup_by_id(group)
      end
      for _, ev in ipairs({ "CursorMoved", "CursorMovedI", "InsertEnter", "BufWinLeave" }) do
        api.nvim_create_autocmd(ev, { group = group, once = true, callback = close })
      end
    end)
  end)
  if not ok then
    vim.notify("GitSigns: git not available", vim.log.levels.WARN)
  end
end

-- =========================================================
-- Setup: autocmds de actualización
-- =========================================================
local group = api.nvim_create_augroup("NvimGitSigns", { clear = true })

-- Tier 1: refetch baseline de HEAD (puede haber cambiado) + refresh
for _, ev in ipairs({ "BufEnter", "BufWritePost", "FileType", "DirChanged" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function(args)
      schedule_update(args.buf, true)
    end,
  })
end

-- Tier 2: edición en tiempo real — refresh síncrono contra baseline cacheado
for _, ev in ipairs({ "InsertLeave", "TextChanged", "TextChangedI" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function(args)
      schedule_update(args.buf, false)
    end,
  })
end

api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(args)
    clear(args.buf)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    schedule_update(api.nvim_get_current_buf(), true)
  end,
})

return M
