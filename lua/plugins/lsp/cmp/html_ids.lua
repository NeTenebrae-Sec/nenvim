local M = {}

function M.setup()
  local ok_cmp, cmp = pcall(require, "cmp")
  if not ok_cmp then
    return
  end

  -- CACHE
  local cache_items = {}

  local function refresh_html_ids_cache()
    vim.schedule(function()
      local items = {}
      local seen = {}
      local cwd = vim.fn.getcwd()

      local glob_patterns = {
        "**/*.html",
        "**/*.astro",
        "**/*.vue",
        "**/*.svelte",
        "**/*.jsx",
        "**/*.tsx",
        "**/*.php",
      }

      local web_files = {}
      for _, pattern in ipairs(glob_patterns) do
        local found = vim.fn.globpath(cwd, pattern, false, true)
        vim.list_extend(web_files, found)
      end

      for _, filepath in ipairs(web_files) do
        -- Excluir directorios pesados / no deseados
        if
          not filepath:find("node_modules")
          and not filepath:find("%.git")
          and not filepath:find("%.astro")
          and not filepath:find("dist")
          and not filepath:find("build")
          and not filepath:find("%.next")
          and not filepath:find("%.nuxt")
        then
          local file = io.open(filepath, "r")
          if file then
            local content = file:read("*a")
            file:close()

            -- Regex compatible con HTML clásico, JSX y plantillas de Frameworks
            for tag, full_tag, id in content:gmatch("<([%w%-]+)([^>]*%sid=[\"']([^\"']+)[\"'][^>]*)>") do
              if not seen[id] then
                seen[id] = true
                local rel_path = vim.fn.fnamemodify(filepath, ":.")
                local ext = vim.fn.fnamemodify(filepath, ":e")

                local doc_text = table.concat({
                  "HTML ID: #" .. id,
                  "",
                  "Tag:  <" .. tag .. ">",
                  "File: " .. rel_path,
                  "",
                  "```" .. (ext ~= "" and ext or "html"),
                  "<" .. tag .. full_tag .. ">",
                  "```",
                }, "\n")

                table.insert(items, {
                  label = id,
                  kind = cmp.lsp.CompletionItemKind.Value,
                  detail = "<" .. tag .. "> (" .. ext .. ")",
                  documentation = {
                    kind = cmp.lsp.MarkupKind.Markdown,
                    value = doc_text,
                  },
                  insertText = id,
                })
              end
            end
          end
        end
      end

      cache_items = items
    end)
  end

  refresh_html_ids_cache()

  -- AUTOCOMANDO MULTI-FRAMEWORK
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("CmpHtmlIdsCache", { clear = true }),
    pattern = {
      "*.html",
      "*.astro",
      "*.vue",
      "*.svelte",
      "*.jsx",
      "*.tsx",
      "*.php",
    },
    callback = refresh_html_ids_cache,
  })

  -- =========================================================================
  -- FUENTE DE CMP
  -- =========================================================================
  local html_ids_source = {}

  function html_ids_source:new()
    return setmetatable({}, { __index = self })
  end

  function html_ids_source:get_trigger_characters()
    return { '"', "'", "`", "#" }
  end

  function html_ids_source:complete(params, callback)
    local ft = vim.bo[params.context.bufnr].filetype

    -- 3. ACTIVACIÓN EXTENDIDA (Incluye hojas de estilo y frameworks web)
    local valid_fts = {
      html = true,
      javascript = true,
      typescript = true,
      javascriptreact = true,
      typescriptreact = true,
      astro = true,
      vue = true,
      svelte = true,
      css = true,
      scss = true,
      php = true,
    }

    if not valid_fts[ft] then
      return callback({ items = {}, isIncomplete = false })
    end

    -- Devuelve la caché de la memoria RAM al instante
    callback({ items = cache_items, isIncomplete = false })
  end

  cmp.register_source("html_ids", html_ids_source:new())
end

return M
