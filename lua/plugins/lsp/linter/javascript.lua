local lint = require("lint")

local oxlint_fts = {
  "javascript",
  "typescript",
  "javascriptreact",
  "typescriptreact",
}

for _, ft in ipairs(oxlint_fts) do
  lint.linters_by_ft[ft] = { "oxlint" }
end
