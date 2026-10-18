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

function M.render()
  local current = api.nvim_get_current_buf()
  local parts = {}

  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted and vim.bo[b].buftype == "" then
      local name = vim.fn.fnamemodify(api.nvim_buf_get_name(b), ":t")
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
      if b == current then
        parts[#parts + 1] = "%#TabLineSel# " .. esc(name) .. flags .. " "
      else
        parts[#parts + 1] = "%#TabLine# " .. esc(name) .. flags .. " "
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
