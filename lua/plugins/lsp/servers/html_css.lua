local status_ok, html_css = pcall(require, "html-css")
if not status_ok then
  return
end

html_css.setup({
  enable_on = {
    "html",
    "css",
    "javascriptreact",
    "typescriptreact",
    "javascript",
    "typescript",
  },
  file_extensions = {
    "css",
    "scss",
    "sass",
    "less",
  },

  -- Vacío para que escanee automáticamente únicamente los <link> del HTML activo
  style_sheets = {},

  handlers = {
    definition = {
      bind = "gd",
    },
    hover = {
      wrap = true,
      border = "rounded",
      position = "cursor",
    },
  },

  documentation = {
    auto_show = true,
  },
})
