-- =========================================================
-- rpc.lua
-- Socket RPC con nombre fijo para nvim-mcp (specs/nvim/tasks/000).
-- Permite que el agente se conecte a ESTA instancia (la
-- interactiva) sin ambigüedad con la instancia --embed que
-- OpenCode lanza para su propio LSP.
-- =========================================================

local M = {}

-- Ruta fija: nvim-mcp hace auto-descubrimiento por prefijo "nvim"
-- en $XDG_RUNTIME_DIR, y la config del MCP fija NVIM_ADDRESS a ella.
function M.socket_path()
  local dir = vim.env.XDG_RUNTIME_DIR
  if not dir or dir == "" then
    return nil
  end
  return dir .. "/nvim-mcp.sock"
end

function M.setup()
  local sock = M.socket_path()
  if not sock then
    -- Sin XDG_RUNTIME_DIR: no forzar, nvim sigue con su socket por defecto
    return
  end

  -- Si otra instancia (o esta) ya tomó la ruta, serverstart fallaría;
  -- lo dejamos pasar en silencio: cada instancia igual queda alcanzable
  -- vía su socket anónimo por defecto.
  pcall(vim.fn.serverstart, sock)
end

-- VimEnter para que nvim ya esté completamente inicializado
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("NvimMcpRpc", { clear = true }),
  callback = function()
    M.setup()
  end,
})

return M
