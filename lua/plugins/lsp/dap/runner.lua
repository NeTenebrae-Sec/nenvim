local M = {}

-- Alias map for equivalent filetypes
local ft_aliases = {
  sh = "bash",
  cpp = "c",
  typescript = "js",
  javascript = "js",
  javascriptreact = "js",
  typescriptreact = "js",
}

function M.run_current_file()
  local ft = vim.bo.filetype
  ft = ft_aliases[ft] or ft

  local ok, module = pcall(require, "plugins.lsp.dap." .. ft)

  if ok and type(module.run) == "function" then
    module.run()
  else
    vim.notify("No M.run() function configured for filetype: " .. ft, vim.log.levels.WARN)
  end
end

return M
