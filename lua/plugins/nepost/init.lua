local ok, config = pcall(require, "plugins.nepost.config")
if not ok then
  return
end

local ui = require("plugins.nepost.ui")
local syntax = require("plugins.nepost.syntax")
local completion = require("plugins.nepost.completion")
local history = require("plugins.nepost.history")
local env = require("plugins.nepost.env")
local collections = require("plugins.nepost.collections")
local from_file = require("plugins.nepost.from_file")

local M = {}

function M.setup(opts)
  config.setup(opts)
  syntax.setup()
  completion.setup()

  vim.api.nvim_create_user_command("Nepost", function()
    ui.toggle()
  end, { desc = "Nepost: Toggle HTTP client" })

  vim.api.nvim_create_user_command("NepostHistory", function()
    local entries = history.list()
    if #entries == 0 then
      vim.notify("Nepost: No history entries", vim.log.levels.INFO)
      return
    end
    local items = {}
    for _, entry in ipairs(entries) do
      table.insert(items, string.format("[%s] %s %s -> %d",
        entry.timestamp,
        entry.request.method,
        entry.request.url,
        entry.response.status
      ))
    end
    vim.ui.select(items, { prompt = "Nepost History" }, function(choice, idx)
      if not choice then
        return
      end
      local entry = entries[idx]

      if not (ui.state.req_win and vim.api.nvim_win_is_valid(ui.state.req_win)) then
        ui.open()
      end

      local req_lines = { entry.request.method .. " " .. entry.request.url }
      if entry.request.headers then
        for key, value in pairs(entry.request.headers) do
          table.insert(req_lines, key .. ": " .. value)
        end
      end
      table.insert(req_lines, "")
      if entry.request.body and entry.request.body ~= "" then
        for line in entry.request.body:gmatch("[^\n]+") do
          table.insert(req_lines, line)
        end
      end

      vim.bo[ui.state.req_buf].modifiable = true
      vim.api.nvim_buf_set_lines(ui.state.req_buf, 0, -1, false, req_lines)
      vim.bo[ui.state.req_buf].modifiable = false

      local client_mod = require("plugins.nepost.client")
      local cfg = require("plugins.nepost.config").get()
      local res_lines, status_text = client_mod.format_response({
        status = entry.response.status,
        headers = entry.response.headers,
        body = entry.response.body,
      }, {
        show_headers = cfg.response.show_headers,
        indent = cfg.response.indent,
        separator = cfg.response.separator,
        separator_width = cfg.response.separator_width,
      })
      ui.set_response(res_lines, entry.response.status, entry.response.headers)

      vim.api.nvim_set_current_win(ui.state.req_win)
    end)
  end, { desc = "Nepost: Show request history" })

  vim.api.nvim_create_user_command("NepostEnv", function(args)
    if args.args and args.args ~= "" then
      env.switch_env(args.args)
    else
      local envs = env.list_envs()
      vim.ui.select(envs, { prompt = "Switch Environment" }, function(choice)
        if choice then
          env.switch_env(choice)
        end
      end)
    end
  end, { nargs = "?", desc = "Nepost: Switch environment" })

  vim.api.nvim_create_user_command("NepostCollections", function()
    collections.open_picker()
  end, { desc = "Nepost: Browse collections" })

  vim.api.nvim_create_user_command("NepostSend", function()
    if not (ui.state.req_win and vim.api.nvim_win_is_valid(ui.state.req_win)) then
      vim.notify("Nepost: No open request buffer", vim.log.levels.WARN)
      return
    end
    vim.api.nvim_set_current_win(ui.state.req_win)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
  end, { desc = "Nepost: Send current request" })

  vim.api.nvim_create_user_command("NepostFromFile", function()
    from_file.send_from_file()
  end, { desc = "Nepost: Send current buffer as HTTP request body" })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "json",
    callback = function(ev)
      vim.keymap.set("n", "<leader>nf", function()
        from_file.send_from_file(ev.buf)
      end, { buffer = ev.buf, silent = true, desc = "Nepost: Send JSON as request" })
    end,
  })
end

M.setup()

return M
