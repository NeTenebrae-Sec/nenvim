-- =========================================================
-- Git signs propio (reemplaza gitsigns.nvim — tarea 012 Fase 2)
-- diff async (`git diff --unified=0`) por buffer, signs vía
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

local function apply(bufnr, root, rel, diff_out, status_out)
  clear(bufnr)
  local hunks = parse_hunks(diff_out and diff_out.stdout)
  local untracked = status_out and status_out.stdout and status_out.stdout:sub(1, 2) == "??"

  local stats = { add = 0, change = 0, del = 0 }

  for _, h in ipairs(hunks) do
    if h.old_c == 0 then
      -- Adición pura
      for i = 0, h.new_c - 1 do
        place(bufnr, h.new_s + i, "", "GitSignsAdd")
      end
      stats.add = stats.add + h.new_c
    elseif h.new_c == 0 then
      -- Borrado: sign en la línea donde ocurrió
      if h.new_s == 0 then
        place(bufnr, 1, "", "GitSignsDelete")
      else
        place(bufnr, h.new_s, "", "GitSignsDelete")
      end
      stats.del = stats.del + h.old_c
    else
      -- Cambio (posiblemente changedelete)
      local hl = (h.old_c > h.new_c) and "GitSignsChangedelete" or "GitSignsChange"
      local glyph = (hl == "GitSignsChangedelete") and "" or ""
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
      place(bufnr, i, "", "GitSignsUntracked")
    end
    stats.add = count
  end

  state[bufnr] = { root = root, rel = rel, hunks = hunks, stats = stats }

  api.nvim_exec_autocmds("User", { pattern = "NvimGitSignsUpdate", modeline = false })
end

-- =========================================================
-- Update (async, debounceado)
-- =========================================================
local function run_update(bufnr)
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

  local pending = 2
  local diff_out, status_out
  local function finish()
    pending = pending - 1
    if pending > 0 then
      return
    end
    if not api.nvim_buf_is_valid(bufnr) then
      return
    end
    apply(bufnr, root, rel, diff_out, status_out)
  end

  local ok1 = pcall(vim.system, { "git", "-C", root, "diff", "--unified=0", "--no-color", "--no-ext-diff", "HEAD", "--", rel }, { text = true }, function(out)
    diff_out = out
    vim.schedule(finish)
  end)
  local ok2 = pcall(vim.system, { "git", "-C", root, "status", "--porcelain=v1", "--", rel }, { text = true }, function(out)
    status_out = out
    vim.schedule(finish)
  end)
  if not (ok1 and ok2) then
    clear(bufnr)
  end
end

function M.update(bufnr)
  run_update(bufnr or api.nvim_get_current_buf())
end

local function schedule_update(bufnr)
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
    run_update(bufnr)
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

  local patch = {
    "diff --git a/" .. s.rel .. " b/" .. s.rel,
    "--- a/" .. s.rel,
    "+++ b/" .. s.rel,
  }
  for _, h in ipairs(targets) do
    table.insert(patch, h.header)
    for _, l in ipairs(h.body) do
      table.insert(patch, l)
    end
  end

  local ok = pcall(vim.system, { "git", "-C", s.root, "apply", "--reverse", "--unidiff-zero", "--whitespace=nowarn", "-" }, {
    stdin = table.concat(patch, "\n") .. "\n",
    text = true,
  }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        vim.notify("GitSigns: reset failed — " .. (out.stderr or "unknown error"), vim.log.levels.WARN)
      end
      run_update(bufnr)
    end)
  end)
  if not ok then
    vim.notify("GitSigns: git not available", vim.log.levels.WARN)
  end
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
for _, ev in ipairs({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged", "TextChangedI", "FileType", "DirChanged" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function(args)
      schedule_update(args.buf)
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
    schedule_update(api.nvim_get_current_buf())
  end,
})

return M
