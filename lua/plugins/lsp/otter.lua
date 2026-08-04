local ok_otter, otter = pcall(require, "otter")
if not ok_otter then
    return
end

otter.setup({
    buffers = {
        set_filetype = true,
        write_to_disk = false,
    },
    verbose = {
        no_code_found = false,
    },
})

-- Mapeo de filetypes y lenguajes inyectados
local injected_languages = {
    html = { "javascript", "css" },
    astro = { "typescript", "javascript", "css" },
    svelte = { "typescript", "javascript", "css" },
    vue = { "typescript", "javascript", "css" },
    markdown = { "javascript", "typescript", "css", "python", "bash", "json" },
}

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("OtterMultiActivation", { clear = true }),
    pattern = vim.tbl_keys(injected_languages),
    callback = function(args)
        local buf = args.buf

        -- Ignorar buffers que no sean archivos reales
        if vim.bo[buf].buftype ~= "" then
            return
        end

        -- Ignorar archivos demasiado grandes (más de 5MB) para no ahogar el editor
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > 5 * 1024 * 1024 then
            return
        end

        -- Evitar que Otter se vuelva a activar en sus propios buffers virtuales (.otter.js, .otter.css)
        if vim.b[buf].otter_activated then
            return
        end

        -- Marcar como activado para romper cualquier ciclo
        vim.b[buf].otter_activated = true

        -- EJECUCIÓN ASÍNCRONA
        -- 'vim.schedule' permite que Neovim renderice el archivo primero y luego active Otter
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            local ft = vim.bo[buf].filetype
            local langs = injected_languages[ft]

            if langs then
                otter.activate(langs, true, true, nil)
            end
        end)
    end,
})
