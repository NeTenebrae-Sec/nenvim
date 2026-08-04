-- ==========================================================================
-- vimpack: config.lua | Load configs files
-- ==========================================================================
local M = {}

-- ==========================================================================
-- USER-CONFIGURABLE MESSAGES (Localization)
-- ==========================================================================
M.messages = {
  load_error = "Error loading [%s]: %s",
}

-- ==========================================================================
-- LOAD PLUGINS CONFIG IN LOAD ORDER!
-- ==========================================================================

M.modules = {
  -- UI (lua/plugins/UI/)
  "plugins.UI.lualine",
  "plugins.UI.devicons",
  "plugins.UI.smear_cursor",
  "plugins.UI.bufferline",
  "plugins.UI.gitsigns",
  "plugins.UI.noice",
  "plugins.UI.rainbow",
  "plugins.UI.render-markdown",
  "plugins.UI.ccc",

  -- Core Utilities (lua/plugins/)
  "plugins.treesitter",
  "plugins.mini",
  "plugins.snacks",
  "plugins.flash",
  "plugins.live-server",
  "plugins.multi_cursor",
  "plugins.trident",
  "plugins.perf_monitor",

  -- Entorno LSP / Configs de Desarrollo (En lua/plugins/lsp/)
  "plugins.lsp.lazydev",
  "plugins.lsp.init",
  "plugins.lsp.otter",
  "plugins.lsp.linter",
  "plugins.lsp.cmp",
  "plugins.lsp.linter",
  "plugins.lsp.formatters",
  "plugins.lsp.dap.init",
}

M.load_all = function()
  for _, module in ipairs(M.modules) do
    local ok, err = pcall(require, module)
    if not ok then
      vim.schedule(function()
        vim.notify(string.format(M.messages.load_error, module, err), vim.log.levels.ERROR)
      end)
    end
  end
end

return M
