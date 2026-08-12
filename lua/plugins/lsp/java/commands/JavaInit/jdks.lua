local M = {}

function M.get_installed_jdks()
  local jvm_dir = "/usr/lib/jvm"
  local detected = {}
  local set = {}

  if vim.fn.isdirectory(jvm_dir) == 1 then
    local entries = vim.fn.glob(jvm_dir .. "/*", false, true)
    for _, path in ipairs(entries) do
      local name = vim.fn.fnamemodify(path, ":t")
      if name ~= "default" and name ~= "default-runtime" and name ~= "current" then
        local ver = name:match("(%d+)")
        if ver and not set[ver] then
          set[ver] = true
          table.insert(detected, ver)
        end
      end
    end
  end

  table.sort(detected, function(a, b)
    return tonumber(a) > tonumber(b)
  end)

  return #detected > 0 and detected or { "26", "21", "17", "8" }
end

return M
