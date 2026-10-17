local M = {}

local SECTION_MARKER = "^#%s*%[%w+%]%s*$"

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "nepost",
    callback = function(ev)
      local buf = ev.buf

      vim.api.nvim_buf_set_option(buf, "commentstring", "# %s")

      local ns = vim.api.nvim_create_namespace("nepost_syntax")

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i, line in ipairs(lines) do
        local row = i - 1

        if line:match(SECTION_MARKER) then
          vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "Title",
          })
        elseif line:match("^###") then
          vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "Title",
          })
        elseif line:match("^#") and not line:match("^#%s*%[") then
          vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "Comment",
          })
        else
          local method = line:match("^(GET)%s")
            or line:match("^(POST)%s")
            or line:match("^(PUT)%s")
            or line:match("^(DELETE)%s")
            or line:match("^(PATCH)%s")
            or line:match("^(HEAD)%s")
            or line:match("^(OPTIONS)%s")

          if method then
            vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
              end_row = row,
              end_col = #method,
              hl_group = "Statement",
            })
            local url_start = #method + 1
            local url_end = #line
            if url_end > url_start then
              vim.api.nvim_buf_set_extmark(buf, ns, row, url_start, {
                end_row = row,
                end_col = url_end,
                hl_group = "String",
              })
            end
          else
            local key, _ = line:match("^([^:]+):%s*(.*)")
            if key then
              vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
                end_row = row,
                end_col = #key,
                hl_group = "Identifier",
              })
            end
          end
        end
      end
    end,
  })
end

function M.highlight_request(buf, start_line, end_line)
  local ns = vim.api.nvim_create_namespace("nepost_active")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  vim.api.nvim_buf_set_extmark(buf, ns, start_line - 1, 0, {
    end_row = end_line - 1,
    end_col = 0,
    hl_group = "Visual",
  })
end

return M
