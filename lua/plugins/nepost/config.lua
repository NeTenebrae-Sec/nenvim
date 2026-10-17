local M = {}

M.defaults = {
  ui = {
    width = 0.85,
    height = 0.80,
    border = "rounded",
    split_ratio = 0.40,
  },
  response = {
    show_headers = false,
    indent = 2,
    separator = "─",
    separator_width = 50,
  },
  curl = {
    default_flags = {},
  },
  history = {
    max_entries = 50,
    dir = ".nepost/history",
  },
  env = {
    default = "default",
    file = ".nepost/env.json",
  },
  collections = {
    dir = ".nepost/collections",
  },
  methods = { "GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS" },
  headers = {
    "Content-Type",
    "Authorization",
    "Accept",
    "User-Agent",
    "Cache-Control",
    "X-Requested-With",
    "Cookie",
    "Host",
    "Referer",
    "Origin",
  },
  content_types = {
    "application/json",
    "application/xml",
    "application/x-www-form-urlencoded",
    "multipart/form-data",
    "text/plain",
    "text/html",
  },
  snippets = {
    json = '{\n  \n}',
    jsonarr = '[\n  \n]',
    keyv = '"key": "value"',
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get()
  return M.options
end

return M
