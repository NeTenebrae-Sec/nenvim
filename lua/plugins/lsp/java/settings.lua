-- ============================================================================
-- MÓDULO: lua/plugins/lsp/java/settings.lua
-- ============================================================================

local M = {}

local function get_configured_runtimes()
  local runtimes = {}
  local jvm_dir = "/usr/lib/jvm"

  if vim.fn.isdirectory(jvm_dir) == 1 then
    local entries = vim.fn.glob(jvm_dir .. "/*", false, true)
    for _, path in ipairs(entries) do
      local name = vim.fn.fnamemodify(path, ":t")
      if name ~= "default" and name ~= "default-runtime" and name ~= "current" then
        local ver = name:match("(%d+)")
        if ver then
          table.insert(runtimes, {
            name = "JavaSE-" .. (ver == "8" and "1.8" or ver),
            path = path,
          })
        end
      end
    end
  end

  if #runtimes == 0 then
    table.insert(runtimes, {
      name = "JavaSE-21",
      path = "/usr/lib/jvm/default",
      default = true,
    })
  end

  return runtimes
end

function M.get_settings()
  return {
    java = {
      format = format_settings,
      project = {
        sourcePaths = { "src", "src/main/java" },
        outputPath = "out",
      },
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      autobuild = { enabled = true },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        importOrder = { "java", "javax", "org", "com" },
      },
      configuration = {
        runtimes = get_configured_runtimes(),
      },
    },
  }
end

return M
