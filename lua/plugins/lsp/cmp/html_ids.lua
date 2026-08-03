local M = {}

function M.setup()
    local ok_cmp, cmp = pcall(require, "cmp")
    if not ok_cmp then
        return
    end

    local html_ids_source = {}

    function html_ids_source:new()
        return setmetatable({}, { __index = self })
    end

    function html_ids_source:get_trigger_characters()
        return { '"', "'", "`", "#" }
    end

    function html_ids_source:complete(params, callback)
        local ft = vim.bo[params.context.bufnr].filetype
        local valid_fts = {
            javascript = true,
            typescript = true,
            javascriptreact = true,
            typescriptreact = true,
            html = true,
        }

        if not valid_fts[ft] then
            return callback({ items = {}, isIncomplete = false })
        end

        local items = {}
        local seen = {}
        local html_files = vim.fn.globpath(vim.fn.getcwd(), "**/*.html", false, true)

        for _, filepath in ipairs(html_files) do
            if not filepath:find("node_modules") and not filepath:find("dist") and not filepath:find("build") then
                local file = io.open(filepath, "r")
                if file then
                    local content = file:read("*a")
                    file:close()

                    for id in content:gmatch("id=[\"']([^\"']+)[\"']") do
                        if not seen[id] then
                            seen[id] = true
                            table.insert(items, {
                                label = id,
                                kind = cmp.lsp.CompletionItemKind.Value,
                                detail = "HTML ID (" .. vim.fs.basename(filepath) .. ")",
                                insertText = id,
                            })
                        end
                    end
                end
            end
        end

        callback({ items = items, isIncomplete = false })
    end

    -- Registra la fuente en cmp
    cmp.register_source("html_ids", html_ids_source:new())
end

return M
