local ok_luasnip, luasnip = pcall(require, "luasnip")
if not ok_luasnip then
  return
end

luasnip.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  delete_check_events = "TextChanged,InsertLeave",
  region_check_events = "CursorMoved,CursorHold,InsertEnter",
  enable_autosnippets = false,
})

-- Rutas base de Neovim
local data_path = vim.fn.stdpath("data")
local config_path = vim.fn.stdpath("config")

-- Carga explícita apuntando directamente a las rutas físicas en disco
require("luasnip.loaders.from_vscode").lazy_load({
  paths = {
    data_path .. "/site/pack/plugins/start/friendly-snippets",
    config_path .. "/snippets",
  },
})

-- Mapeo Extendido de Filetypes para Desarrollo Web
luasnip.filetype_extend("html", { "css", "javascript" })
luasnip.filetype_extend("javascript", { "html", "jsdoc" })
luasnip.filetype_extend("typescript", { "html", "tsdoc" })
luasnip.filetype_extend("javascriptreact", { "html", "javascript" })
luasnip.filetype_extend("typescriptreact", { "html", "typescript" })
luasnip.filetype_extend("scss", { "css" })

-- Desvincular snippets al cambiar de modo
local unlink_group = vim.api.nvim_create_augroup("LuaSnipUnlinkOnModeChange", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", {
  group = unlink_group,
  pattern = { "s:n", "i:*" },
  desc = "Forget active LuaSnip snippet when leaving insert/select mode",
  callback = function(evt)
    while true do
      if luasnip.session and luasnip.session.current_nodes[evt.buf] and not luasnip.session.jump_active then
        luasnip.unlink_current()
      else
        break
      end
    end
  end,
})
