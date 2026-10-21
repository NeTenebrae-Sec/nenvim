-- =========================================================
-- Ficha HTML/CSS — html + cssls + emmet + tailwind + html-css
-- =========================================================
-- Auxiliares internos con side effects: setup del plugin html-css,
-- args dinámicos de stylelint/markuplint (configs del proyecto o
-- fallback) y la fuente cmp html_ids.
-- prettier para .html/.css/.scss lo aporta el módulo format de node-ts.

local M = {
  name = "html-css",
  filetypes = { "html", "templ", "css", "scss", "sass", "less" },

  lsp = {
    {
      name = "html",
      config = {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html", "templ" },
        root_markers = { ".git", "package.json", "index.html" },
        init_options = {
          provideFormatter = true,
          embeddedLanguages = { css = true, javascript = true },
          configurationSection = { "html", "css", "javascript" },
        },
        settings = { html = { suggest = { html5 = true } } },
      },
    },
    {
      name = "cssls",
      config = {
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = { ".git", "package.json" },
        settings = {
          css = {
            validate = true,
            lint = { unknownAtRules = "ignore" },
          },
        },
      },
    },
    {
      name = "tailwindcss",
      config = {
        cmd = { "tailwindcss-language-server", "--stdio" },
        filetypes = {
          "html",
          "css",
          "scss",
          "sass",
          "javascriptreact",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
        -- Guard anti-rogue (spec 002 F3): solo arranca en proyectos con
        -- tailwind real — config explícita (tailwind/postcss.config.*)
        -- o dependencia "tailwindcss" en package.json. Sin eso no se
        -- hace on_dir y el servidor ni siquiera se spawnea.
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local root = vim.fs.root(fname, {
            "tailwind.config.js",
            "tailwind.config.ts",
            "tailwind.config.mjs",
            "tailwind.config.cjs",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.ts",
          })
          if not root then
            local pkg = vim.fs.root(fname, { "package.json" })
            if pkg then
              local fd = io.open(pkg .. "/package.json", "r")
              if fd then
                local content = fd:read("*a") or ""
                fd:close()
                if content:find('"tailwindcss"', 1, true) then
                  root = pkg
                end
              end
            end
          end
          if root then
            on_dir(root)
          end
        end,
      },
    },
    {
      name = "emmet_language_server",
      config = {
        cmd = { "emmet-language-server", "--stdio" },
        filetypes = {
          "html",
          "css",
          "scss",
          "sass",
          "less",
          "javascriptreact",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
        root_markers = { ".git", "package.json" },
      },
    },
  },

  lint = {
    css = { "stylelint" },
    scss = { "stylelint" },
    html = { "markuplint" },
  },

  parsers = { "html", "css", "scss" },

  tools = {
    "html-lsp",
    "css-lsp",
    "emmet-language-server",
    "tailwindcss-language-server",
    "markuplint",
    "stylelint",
  },

  -- Fuente cmp: IDs HTML del proyecto (prioridad 600, global)
  cmp = { setup = "languages.html-css.html_ids" },
}

-- Side effects: plugin html-css + args dinámicos de stylelint y markuplint
pcall(require, "languages.html-css.html_css")
pcall(require, "languages.html-css.lint_css")
pcall(require, "languages.html-css.lint_html")

return M
