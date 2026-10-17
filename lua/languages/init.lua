-- =========================================================
-- languages: scanner de fichas (único módulo que lee languages/*/)
-- =========================================================
-- Devuelve la lista de fichas (datos puros, cacheada). Los motores de
-- core/ la consumen vía require("languages").all(). R0: una ficha rota
-- es un notify, nunca un error de arranque.

local M = {}
local cache

function M.all()
  if cache then
    return cache
  end
  cache = {}

  -- Directorio propio vía source (funciona aunque la config esté en otro lado)
  local src = debug.getinfo(1, "S").source:sub(2)
  local dir = src:match("^(.*)/init%.lua$")
  local handle = dir and vim.uv.fs_scandir(dir) or nil
  if not handle then
    return cache
  end

  while true do
    local name, ftype = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if ftype == "directory" then
      local ok, ficha = pcall(require, "languages." .. name)
      if ok and type(ficha) == "table" then
        table.insert(cache, ficha)
      else
        vim.schedule(function()
          vim.notify("Ficha de lenguaje inválida: " .. name, vim.log.levels.WARN)
        end)
      end
    end
  end

  return cache
end

return M
