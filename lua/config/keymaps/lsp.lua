-- =========================================================
-- keymaps/lsp.lua
-- Formateo, hover, diagnosticas, rename, code action.
-- =========================================================

-- === FORMATO ===
nmap("<leader>f", function()
  local ok_conform, conform = pcall(require, "conform")
  if ok_conform then
    conform.format({ async = true, lsp_fallback = true })
  else
    vim.lsp.buf.format({ async = true })
  end
end, "Format: File")

-- === HOVER UNIVERSAL (combina multiples LSPs) ===
nmap("K", function()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  vim.lsp.buf_request_all(0, "textDocument/hover", params, function(responses)
    local combined_markdown = {}

    for client_id, resp in pairs(responses or {}) do
      local client = vim.lsp.get_client_by_id(client_id)
      if not resp.err and resp.result and resp.result.contents then
        local lines = vim.lsp.util.convert_input_to_markdown_lines(resp.result.contents)

        lines = vim.tbl_filter(function(line)
          return line and line:match("%S") ~= nil
        end, lines)

        if not vim.tbl_isempty(lines) then
          if #combined_markdown > 0 then
            table.insert(combined_markdown, "---")
          end
          for _, line in ipairs(lines) do
            table.insert(combined_markdown, line)
          end
        end
      end
    end

    if vim.tbl_isempty(combined_markdown) then
      vim.notify("No hay documentacion disponible en esta posicion", vim.log.levels.INFO)
      return
    end

    local screen_width = vim.o.columns
    local screen_height = vim.o.lines

    local is_long_doc = #combined_markdown > 5

    local min_width = 25
    local max_width = is_long_doc and math.floor(screen_width * 0.55) or math.floor(screen_width * 0.40)
    local max_height = is_long_doc and math.floor(screen_height * 0.45) or 15

    local max_line_len = 0
    for _, line in ipairs(combined_markdown) do
      local clean_line = line:gsub("```%w*", ""):gsub("[%*`_]", "")
      local len = vim.fn.strdisplaywidth(clean_line)
      if len > max_width then
        len = max_width
      end
      if len > max_line_len then
        max_line_len = len
      end
    end

    local final_width = math.max(min_width, math.min(max_line_len + 4, max_width))

    local ok_noice, noice_handlers = pcall(require, "noice.lsp.handlers")
    if ok_noice and noice_handlers and noice_handlers.hover then
      local synthetic_result = { contents = combined_markdown }
      noice_handlers.hover(nil, synthetic_result, {
        method = "textDocument/hover",
        opts = {
          size = { max_width = final_width, max_height = max_height },
          win_options = { wrap = true },
        },
      }, {})
      return
    end

    local opts = {
      border = "rounded",
      focusable = true,
      max_height = max_height,
      wrap = true,
    }

    local bufnr, winnr = vim.lsp.util.open_floating_preview(combined_markdown, "markdown", opts)

    if winnr and vim.api.nvim_win_is_valid(winnr) then
      local config = vim.api.nvim_win_get_config(winnr)
      config.width = final_width
      vim.api.nvim_win_set_config(winnr, config)
      pcall(vim.diagnostic.enable, false, { bufnr = bufnr })
      vim.wo[winnr].number = false
      vim.wo[winnr].relativenumber = false
    end
  end)
end, "Universal Safe LSP Hover")

-- === REFERENCIAS Y DIAGNOSTICAS ===
nmap("gr", vim.lsp.buf.references, "LSP: References")
nmap("GD", vim.diagnostic.open_float, "LSP: Show diagnostic float")
nmap("GR", vim.diagnostic.setloclist, "LSP: Open Loclist")

nmap("gn", function()
  vim.diagnostic.jump({ count = 1 })
end, "LSP: Next diagnostic")

nmap("gN", function()
  vim.diagnostic.jump({ count = -1 })
end, "LSP: Prev diagnostic")

-- === RENAME ===
nmap("<leader>rn", function()
  local ok_otter, otter = pcall(require, "otter")
  if ok_otter and type(otter.rename) == "function" then
    local status = pcall(otter.rename)
    if status then
      return
    end
  end
  vim.lsp.buf.rename()
end, "LSP / Otter: Rename")

-- === CODE ACTION ===
nmap("<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")

-- === INSPECT HIGHLIGHTS ===
nmap("GI", function()
  local items = vim.inspect_pos()
  local lines = {}

  if #items.treesitter > 0 then
    table.insert(lines, "Treesitter:")
    for _, capture in ipairs(items.treesitter) do
      table.insert(lines, string.format("  - @%s -> %s", capture.capture, capture.hl_group))
    end
  end

  if #items.syntax > 0 then
    if #lines > 0 then
      table.insert(lines, "")
    end
    table.insert(lines, "Syntax:")
    for _, syn in ipairs(items.syntax) do
      table.insert(lines, string.format("  - %s -> %s", syn.hl_group, syn.hl_group))
    end
  end

  if #lines == 0 then
    lines = { "No highlight information found here." }
  end

  vim.lsp.util.open_floating_preview(lines, "markdown", {
    border = "rounded",
    focusable = true,
    focus = true,
  })
end, "Inspect highlights in floating window")
