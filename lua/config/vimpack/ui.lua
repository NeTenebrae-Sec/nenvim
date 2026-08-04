-- ==========================================================================
-- vimpack: ui.lua (Concurrency Mapping & Floating Window)
-- ==========================================================================
local UI = {}

-- ==========================================================================
-- USER-CONFIGURABLE MESSAGES (Localization)
-- ==========================================================================
UI.messages = {
    title = " Pack Sync ",
    preparing = "Preparing subprocesses...",
    progress_format = "Progress: [%d/%d] %d%%",
    errors_detected = "Errors detected during synchronization:",
    sync_success = "PackUpdate: Completed without errors.",
}

function UI.run_concurrent_pool(tasks, max_concurrency, on_complete)
    if #tasks == 0 then
        on_complete()
        return
    end
    local current_index, active_tasks = 0, 0
    local function run_next()
        if current_index >= #tasks then
            if active_tasks == 0 then
                on_complete()
            end
            return
        end
        current_index = current_index + 1
        active_tasks = active_tasks + 1
        tasks[current_index](function()
            active_tasks = active_tasks - 1
            run_next()
        end)
    end
    local initial_spawn = math.min(max_concurrency, #tasks)
    for _ = 1, initial_spawn do
        run_next()
    end
end

function UI.open(total_tasks)
    local width = math.floor(vim.o.columns * 0.5)
    local height = 11
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = UI.messages.title,
        title_pos = "center",
    })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        UI.messages.preparing,
        string.format(UI.messages.progress_format, 0, total_tasks, 0),
        string.rep("─", width),
        "",
    })
    return { buf = buf, win = win, total = total_tasks, completed = 0, logs = {} }
end

function UI.update_progress(ui, log_line)
    ui.completed = ui.completed + 1
    local percent = math.floor((ui.completed / ui.total) * 100)
    table.insert(ui.logs, log_line)
    if #ui.logs > 7 then
        table.remove(ui.logs, 1)
    end
    vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ui.buf) then
            vim.api.nvim_buf_set_lines(ui.buf, 1, 2, false, {
                string.format(UI.messages.progress_format, ui.completed, ui.total, percent),
            })
            local lines = {}
            for i = 1, 7 do
                lines[i] = ui.logs[i] or ""
            end
            vim.api.nvim_buf_set_lines(ui.buf, 3, -1, false, lines)
        end
    end)
end

function UI.close(ui, errors)
    vim.schedule(function()
        if #errors > 0 then
            local error_lines = { UI.messages.errors_detected, string.rep("═", 40) }
            for _, err in ipairs(errors) do
                table.insert(error_lines, string.format("• %s: %s", err.name, err.msg))
            end
            if vim.api.nvim_buf_is_valid(ui.buf) then
                vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, error_lines)
            end
        else
            if vim.api.nvim_win_is_valid(ui.win) then
                vim.api.nvim_win_close(ui.win, true)
            end
            vim.notify(UI.messages.sync_success, vim.log.levels.INFO)
        end
    end)
end

return UI
