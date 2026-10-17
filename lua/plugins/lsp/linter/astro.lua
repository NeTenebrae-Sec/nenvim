local lint = require("lint")

-- eslint local del proyecto (node_modules/.bin, ver nvim-lint/eslint).
-- Requiere eslint-plugin-astro en el eslint.config del proyecto para .astro.
lint.linters_by_ft.astro = { "eslint" }
