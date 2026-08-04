-- ==========================================================================
-- Web Language Servers Configuration
-- ==========================================================================

-- JS / TS (Vtsls)
vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  settings = {
    typescript = {
      suggest = {
        completeFunctionCalls = true,
      },
      preferences = {
        importModuleSpecifier = "shortest",
        includeCompletionsForModuleExports = true,
        includeCompletionsWithInsertText = true,
      },
    },
    javascript = {
      suggest = {
        completeFunctionCalls = true,
      },
      preferences = {
        importModuleSpecifier = "shortest",
        includeCompletionsForModuleExports = true,
        includeCompletionsWithInsertText = true,
      },
    },
    vtsls = {
      autoUseWorkspaceTsdk = true,
      -- AGREGAR ESTE BLOQUE:
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
  },
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})
-- Astro
vim.lsp.config("astro", {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = { "astro.config.mjs", "astro.config.ts", "package.json", ".git" },
  init_options = {
    typescript = {
      tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
    },
  },
})

-- Svelte
vim.lsp.config("svelte", {
  cmd = { "svelteserver", "--stdio" },
  filetypes = { "svelte" },
  root_markers = { "svelte.config.js", "svelte.config.ts", "package.json", ".git" },
})

-- Vue (Volar)
vim.lsp.config("volar", {
  cmd = { "vue-language-server", "--stdio" },
  filetypes = { "vue" },
  root_markers = { "vue.config.js", "vue.config.ts", "vite.config.js", "vite.config.ts", "package.json", ".git" },
})

-- HTML
vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html", "templ" },
  root_markers = { ".git", "package.json", "index.html" },
  init_options = {
    provideFormatter = true,
    embeddedLanguages = {
      css = true,
      javascript = true,
    },
    configurationSection = { "html", "css", "javascript" },
  },
  settings = {
    html = {
      suggest = {
        html5 = true,
      },
    },
  },
})

-- CSS
vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { ".git", "package.json" },
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = "ignore",
      },
    },
  },
})

-- TailwindCSS
vim.lsp.config("tailwindcss", {
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
  root_markers = {
    "tailwind.config.js",
    "tailwind.config.ts",
    "postcss.config.js",
    "postcss.config.ts",
    "package.json",
    ".git",
  },
})

-- Emmet
vim.lsp.config("emmet_language_server", {
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
})

-- JSON
vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git", "package.json" },
})

-- Habilitar todos los servidores activos de este módulo
vim.lsp.enable({
  "vtsls",
  "astro",
  "svelte",
  "volar",
  "html",
  "cssls",
  "tailwindcss",
  "emmet_language_server",
  "jsonls",
})

-- ==========================================================================
-- Comando :Jsconfig (Genera jsconfig.json en la raíz del proyecto)
-- ==========================================================================

local default_jsconfig = {
  compilerOptions = {
    moduleResolution = "node",
    target = "ES2022",
    checkJs = true,
  },
  include = {
    "**/*.js",
    "**/*.jsx",
    "**/*.ts",
    "**/*.tsx",
  },
}

vim.api.nvim_create_user_command("Jsconfig", function()
  local root = vim.fs.root(0, { "package.json", ".git" }) or vim.fn.getcwd()
  local jsconfig_path = root .. "/jsconfig.json"
  local tsconfig_path = root .. "/tsconfig.json"

  if vim.fn.filereadable(jsconfig_path) == 1 or vim.fn.filereadable(tsconfig_path) == 1 then
    vim.notify("Ya existe un archivo de configuración JS/TS en la raíz.", vim.log.levels.WARN, { title = "Jsconfig" })
    return
  end

  local formatted_json = vim.fn.json_encode(default_jsconfig)

  local file = io.open(jsconfig_path, "w")
  if file then
    file:write(formatted_json)
    file:close()
    vim.notify("jsconfig.json creado en: " .. root, vim.log.levels.INFO, { title = "Jsconfig" })

    -- Disparar el evento FileType del buffer actual para refrescar sin tocar nada de LSP
    vim.bo.filetype = vim.bo.filetype
  else
    vim.notify("Error al intentar crear jsconfig.json", vim.log.levels.ERROR, { title = "Jsconfig" })
  end
end, {
  desc = "Genera un archivo jsconfig.json básico en la raíz del proyecto",
})
