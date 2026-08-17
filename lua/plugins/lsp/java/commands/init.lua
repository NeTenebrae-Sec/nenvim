local M = {}

function M.setup()
  local base_module = "plugins.lsp.java.commands"
  local commands_dir = vim.fn.stdpath("config") .. "/lua/plugins/lsp/java/commands"

  local handle = vim.uv.fs_scandir(commands_dir)
  if not handle then
    return
  end

  while true do
    local name, type_flag = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    local module_name = nil

    if type_flag == "file" and name:match("%.lua$") and name ~= "init.lua" then
      module_name = name:gsub("%.lua$", "")
    elseif type_flag == "directory" then
      local init_path = commands_dir .. "/" .. name .. "/init.lua"
      if vim.uv.fs_stat(init_path) then
        module_name = name
      end
    end

    if module_name then
      local ok, cmd_module = pcall(require, base_module .. "." .. module_name)
      if ok and type(cmd_module) == "table" and type(cmd_module.setup) == "function" then
        cmd_module.setup()
      end
    end
  end
end

return M
