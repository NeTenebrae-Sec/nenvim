local M = {}

-- Lista global de patrones/extensiones a ignorar en búsquedas de código
local CODE_IGNORE_PATTERNS = {
    "!.md",
    "!.txt",
    "!.log",
    "!.json",
    "!.yaml",
    "!.yml",
    "!.toml",
    "!.lock",
    "!.svg",
    "!package-lock.json",
    "!yarn.lock",
}

function M.normalize_path(path)
    if not path or path == "" then
        return ""
    end
    local abs = vim.fn.fnamemodify(path, ":p")
    return (vim.uv or vim.loop).fs_realpath(abs) or abs
end

function M.get_target_word()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1

    local start_col = col
    while start_col > 1 and line:sub(start_col - 1, start_col - 1):match("[%w_%-%.]") do
        start_col = start_col - 1
    end

    local end_col = col
    while end_col <= #line and line:sub(end_col, end_col):match("[%w_%-%.]") do
        end_col = end_col + 1
    end

    if start_col >= end_col then
        return nil
    end

    local raw_word = line:sub(start_col, end_col - 1)
    return raw_word:gsub("^%.+", "")
end

function M.get_mode_filter_label(mode)
    local cur_file = vim.fn.expand("%:t")
    local cur_ext = vim.fn.expand("%:e")

    if mode == "exclude_file" then
        return cur_file ~= "" and string.format("EXCLUDE: %s", cur_file) or "EXCLUDE CURRENT FILE"
    elseif mode == "exclude_ext" then
        return cur_ext ~= "" and string.format("EXCLUDE ALL: .%s", cur_ext) or "EXCLUDE EXTENSION"
    else
        return "ALL CODE FILES"
    end
end

function M.run_ripgrep(word, mode)
    local current_file_rel = vim.fn.expand("%:.")
    local current_file_abs = M.normalize_path(vim.api.nvim_buf_get_name(0))
    local current_ext = vim.fn.expand("%:e")

    local escaped_word = word:gsub("([%^%$%(%)%%%.%[%]%*%+\\%-%?])", "\\%1")
    local regex_pattern = string.format("(?<![\\w_-])%s(?![\\w_-])", escaped_word)

    local cmd_parts = { "rg", "--vimgrep", "-P" }

    -- 1. Aplicar filtros globales para omitir archivos que no son de código
    for _, pattern in ipairs(CODE_IGNORE_PATTERNS) do
        table.insert(cmd_parts, string.format("-g '%s'", pattern))
    end

    -- 2. Filtros dinámicos según el modo
    if mode == "exclude_file" and current_file_rel ~= "" then
        table.insert(cmd_parts, string.format("-g '!%s'", current_file_rel))
    elseif mode == "exclude_ext" and current_ext ~= "" then
        table.insert(cmd_parts, string.format("-g '!*.%s'", current_ext))
    end

    table.insert(cmd_parts, vim.fn.shellescape(regex_pattern))
    table.insert(cmd_parts, "2>/dev/null")
    local cmd = table.concat(cmd_parts, " ")

    local handle = io.popen(cmd)
    if not handle then
        return {}
    end

    local results = {}
    for line in handle:lines() do
        local parts = vim.split(line, ":")
        if #parts >= 4 then
            local match_file = M.normalize_path(parts[1])
            local is_same_file = (match_file == current_file_abs)

            local include_match = true
            if (mode == "exclude_file" or mode == "exclude_ext") and is_same_file then
                include_match = false
            end

            if include_match then
                local text_content = table.concat({ select(4, unpack(parts)) }, ":")
                table.insert(results, {
                    file = parts[1],
                    lnum = tonumber(parts[2]),
                    col = tonumber(parts[3]) - 1,
                    text_trim = vim.trim(text_content),
                })
            end
        end
    end
    handle:close()
    return results
end

return M
