-- =========================================================
-- Tools engine: own binary manager (npm / pip / github recipes)
-- =================================================--------
-- Installs the tools declared by language cards into
-- stdpath("data")/tools on demand. No network at startup: everything
-- runs from the commands below, plus a one-shot notification when a
-- buffer's language is missing tools.

local install = require("core.tools.install")

local M = {}

vim.env.PATH = install.bin .. ":" .. vim.env.PATH

-- Installs run one at a time: parallel npm/curl storms are slow and
-- their interleaved output is unreadable.
local queue = {}
local running = false

local function drain()
  if running then
    return
  end
  local job = table.remove(queue, 1)
  if not job then
    return
  end
  running = true
  vim.notify("Installing " .. job.tool .. " ...", vim.log.levels.INFO)
  install.install(job.tool, { force = job.force }, function(ok, err)
    running = false
    if ok then
      vim.notify(job.tool .. " installed", vim.log.levels.INFO)
    else
      vim.notify("Failed to install " .. job.tool .. ": " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
    drain()
  end)
end

local function enqueue(tools, force)
  for _, tool in ipairs(tools) do
    table.insert(queue, { tool = tool, force = force })
  end
  drain()
end

local function card_names()
  local ok, languages = pcall(require, "languages")
  if not ok then
    return {}
  end
  local names = {}
  for _, ficha in ipairs(languages.all()) do
    table.insert(names, ficha.name or "?")
  end
  table.sort(names)
  return names
end

--- "all" or "" -> every tool; otherwise the tools of one language card.
local function resolve_arg(arg)
  arg = vim.trim(arg or "")
  local ok, languages = pcall(require, "languages")
  if not ok then
    return nil, "language scanner unavailable"
  end

  local seen, out = {}, {}
  for _, ficha in ipairs(languages.all()) do
    if arg == "" or arg == "all" or ficha.name == arg then
      for _, tool in ipairs(ficha.tools or {}) do
        if not seen[tool] then
          seen[tool] = true
          table.insert(out, tool)
        end
      end
    end
  end

  if arg ~= "" and arg ~= "all" and #out == 0 then
    return nil, "unknown language: " .. arg
  end
  return out
end

local function complete_langs()
  return vim.tbl_extend("force", card_names(), { "all" })
end

vim.api.nvim_create_user_command("ToolsInstall", function(cmd)
  local tools, err = resolve_arg(cmd.args)
  if not tools then
    return vim.notify(err, vim.log.levels.WARN)
  end
  enqueue(install.missing(tools), false)
end, { nargs = "?", complete = complete_langs, desc = "Install missing tools (one language or all)" })

vim.api.nvim_create_user_command("ToolsUpdate", function(cmd)
  local tools, err = resolve_arg(cmd.args)
  if not tools then
    return vim.notify(err, vim.log.levels.WARN)
  end
  -- Reinstall from the pinned registry version (bump pins by hand)
  enqueue(tools, true)
end, { nargs = "?", complete = complete_langs, desc = "Reinstall tools from the registry pins" })

vim.api.nvim_create_user_command("ToolsRemove", function(cmd)
  local tools, err = resolve_arg(cmd.args)
  if not tools then
    return vim.notify(err, vim.log.levels.WARN)
  end
  for _, tool in ipairs(tools) do
    local ok, rerr = install.remove(tool, false)
    if ok then
      vim.notify(tool .. " removed", vim.log.levels.INFO)
    else
      vim.notify(rerr, vim.log.levels.WARN)
    end
  end
end, { nargs = "?", complete = complete_langs, desc = "Remove a language's tools (ref-counted between cards)" })

-- One-shot heads-up when a buffer's language has missing tools.
local notified = {}
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("ToolsMissingNotify", { clear = true }),
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    local ok, languages = pcall(require, "languages")
    if not ok then
      return
    end
    for _, ficha in ipairs(languages.all()) do
      if not notified[ficha.name] and vim.tbl_contains(ficha.filetypes or {}, ft) then
        local missing = install.missing(ficha.tools or {})
        if #missing > 0 then
          notified[ficha.name] = true
          vim.notify(
            "Missing tools for " .. ficha.name .. ": " .. table.concat(missing, ", ")
              .. " — run :ToolsInstall " .. ficha.name,
            vim.log.levels.WARN
          )
        end
      end
    end
  end,
})

return M
