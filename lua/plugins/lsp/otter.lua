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

-- Mapeo de filetypes e idiomas inyectados
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

    -- 1. Ignorar buffers especiales (undotree, noice, popups, etc.)
    if vim.bo[buf].buftype ~= "" then
      return
    end

    -- 2. Ignorar si la opción modifiable está apagada
    if not vim.bo[buf].modifiable then
      return
    end

    -- 3. Ignorar archivos grandes (+5MB)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
    if ok and stats and stats.size > 5 * 1024 * 1024 then
      return
    end

    -- 4. Evitar re-activación en buffers virtuales de Otter (.otter.js, etc.)
    if vim.b[buf].otter_activated then
      return
    end

    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end

      -- 5. VERIFICACIÓN DE TREESITTER: Solo activar Otter si hay un parser válido instalado
      local ft = vim.bo[buf].filetype
      local has_parser = pcall(vim.treesitter.get_parser, buf, ft)

      if not has_parser then
        return -- Sale en silencio si no hay parser cargado/instalado
      end

      vim.b[buf].otter_activated = true
      local langs = injected_languages[ft]

      if langs then
        pcall(otter.activate, langs, true, true, nil)
      end
    end)
  end,
})
