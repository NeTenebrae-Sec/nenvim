local M = {}

local API_BASE = "https://search.maven.org/solrsearch/select"

local search_cache = {}
local versions_cache = {}

--- Escapa caracteres especiales para la query Solr
local function escape_query(q)
  return q:gsub("[+\\\"']", " ")
end

--- Fetchea datos desde una URL usando curl + jobstart (async)
--- Sigue el patrón de JavaInit/spring_ui.lua: evita doble callback con guardia
local function fetch_json(url, callback)
  local cmd = string.format("curl -sH 'Accept: application/json' '%s'", url)
  local callback_called = false

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if callback_called or not data or #data == 0 then
        return
      end
      local raw = table.concat(data, "")
      local ok, parsed = pcall(vim.json.decode, raw)
      if ok then
        callback_called = true
        callback(parsed)
      else
        callback_called = true
        callback(nil)
      end
    end,
    on_exit = function(_, code)
      if not callback_called and code ~= 0 then
        vim.notify("Failed to fetch data from Maven Central API", vim.log.levels.ERROR, { title = "Java LSP" })
        callback(nil)
      end
    end,
  })
end

--- Busca artifacts en Maven Central
---@param query string texto de búsqueda
---@param callback function(results: table|nil)
function M.search_artifacts(query, callback)
  local cache_key = query:lower()
  if search_cache[cache_key] then
    callback(search_cache[cache_key])
    return
  end

  local q = escape_query(query)
  local url = string.format("%s?q=%s&rows=20&wt=json", API_BASE, vim.fn.shellescape(q))

  fetch_json(url, function(data)
    if not data or not data.response or not data.response.docs then
      callback(nil)
      return
    end

    local results = {}
    for _, doc in ipairs(data.response.docs) do
      if doc.g and doc.a and doc.latestVersion then
        table.insert(results, {
          group_id = doc.g,
          artifact_id = doc.a,
          latest_version = doc.latestVersion,
          packaging = doc.p or "jar",
          display = string.format("%s:%s", doc.g, doc.a),
          display_short = doc.a,
        })
      end
    end

    search_cache[cache_key] = results
    callback(results)
  end)
end

--- Obtiene las versiones disponibles de un artifact
---@param group_id string
---@param artifact_id string
---@param callback function(versions: table|nil)
function M.get_versions(group_id, artifact_id, callback)
  local cache_key = group_id .. ":" .. artifact_id
  if versions_cache[cache_key] then
    callback(versions_cache[cache_key])
    return
  end

  local q = string.format("g:%s+AND+a:%s", group_id, artifact_id)
  local url = string.format("%s?q=%s&core=gav&rows=20&wt=json", API_BASE, vim.fn.shellescape(q))

  fetch_json(url, function(data)
    if not data or not data.response or not data.response.docs then
      callback(nil)
      return
    end

    local versions = {}
    for _, doc in ipairs(data.response.docs) do
      if doc.v then
        table.insert(versions, doc.v)
      end
    end

    versions_cache[cache_key] = versions
    callback(versions)
  end)
end

--- Limpia el caché
function M.clear_cache()
  search_cache = {}
  versions_cache = {}
end

return M
