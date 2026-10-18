-- =========================================================
-- Tabline propia (reemplaza bufferline — tarea 012 Fase 2)
-- Lista los buffers listados con indicador de modificado;
-- grupos TabLine/TabLineSel/TabLineFill del tema.
-- =========================================================

local api = vim.api

local M = {}

local function esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

-- Icono vía mini.icons (opcional, sin él se muestra solo el nombre)
local function icon_for(name)
  local ok, icons = pcall(require, "mini.icons")
  if not ok then
    return ""
  end
  local ext = name:match("%.(%w+)$")
  if ext then
    local okg, glyph = pcall(icons.get, "extension", ext)
    if okg and glyph and glyph ~= "" then
      return glyph .. " "
    end
  end
  local ft = vim.filetype.match({ filename = name })
  if ft then
    local okg, glyph = pcall(icons.get, "filetype", ft)
    if okg and glyph and glyph ~= "" then
      return glyph .. " "
    end
  end
  return ""
end

function M.render()
  local current = api.nvim_get_current_buf()
  local parts = {}

  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted and vim.bo[b].buftype == "" then
      local full = api.nvim_buf_get_name(b)
      local name = vim.fn.fnamemodify(full, ":t")
      if name == "" then
        name = "[No Name]"
      end
      local flags = ""
      if vim.bo[b].modified then
        flags = flags .. " ●"
      end
      if vim.bo[b].readonly then
        flags = flags .. " "
      end
      local icon = icon_for(name)
      if b == current then
        parts[#parts + 1] = "%#TabLineSel# " .. icon .. esc(name) .. flags .. " "
      else
        parts[#parts + 1] = "%#TabLine# " .. icon .. esc(name) .. flags .. " "
      end
    end
  end

  return table.concat(parts) .. "%#TabLineFill#%="
end

vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.require'plugins.tabline'.render()"

local group = api.nvim_create_augroup("NvimTabline", { clear = true })
for _, ev in ipairs({ "BufEnter", "BufModifiedSet", "BufDelete", "FileType" }) do
  api.nvim_create_autocmd(ev, {
    group = group,
    callback = function()
      vim.cmd("redrawtabline")
    end,
  })
end

return M
