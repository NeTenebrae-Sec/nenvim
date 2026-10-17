local lint = require("lint")

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/markuplint"
local tmp_config = vim.fn.stdpath("state") .. "/markuplintrc_fallback.json"

-- Si no existe, creamos una configuración con REGLAS VÁLIDAS de Markuplint
if vim.fn.filereadable(tmp_config) == 0 then
  local f = io.open(tmp_config, "w")
  if f then
    f:write([[
{
  "rules": {
    "doctype": "always",
    "permitted-contents": true,
    "required-element": true,
    "invalid-attr": true,
    "character-reference": true,
    "end-tag": "always"
  }
}
]])
    f:close()
  end
end

lint.linters_by_ft.html = { "markuplint" }

local markuplint_configs = {
  ".markuplintrc",
  ".markuplintrc.json",
  ".markuplintrc.yaml",
  ".markuplintrc.yml",
  ".markuplintrc.js",
  ".markuplintrc.cjs",
  "markuplint.config.js",
  "markuplint.config.cjs",
}

lint.linters.markuplint.cmd = mason_bin

lint.linters.markuplint.args = {
  "--format",
  "JSON",
  "--config",
  function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local buf_dir = vim.fs.dirname(buf_name)

    if buf_dir and buf_dir ~= "" then
      local project_config = vim.fs.find(markuplint_configs, {
        upward = true,
        path = buf_dir,
      })[1]

      if project_config then
        return project_config
      end
    end

    return tmp_config
  end,
  function()
    return vim.api.nvim_buf_get_name(0)
  end,
}
