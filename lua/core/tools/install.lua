-- =========================================================
-- Tools engine > install: recipes -> packages + bin links
-- =========================================================
-- Layout: stdpath("data")/tools/{bin,packages}. Every tool lives in
-- its own package dir (npm prefix, pip venv or extracted release);
-- exposed bins are symlinked into tools/bin with relative targets so
-- the tree survives moves. Installs run async via vim.system and never
-- touch the network outside an explicit command.

local registry = require("core.tools.registry")

local M = {}

local ROOT = vim.fn.stdpath("data") .. "/tools"
M.root = ROOT
M.packages = ROOT .. "/packages"
M.bin = ROOT .. "/bin"

function M.package_dir(tool)
  return M.packages .. "/" .. tool
end

function M.is_installed(tool)
  return vim.uv.fs_stat(M.package_dir(tool)) ~= nil
end

--- Run shell steps sequentially; on_done(ok, err). Callbacks land in
--- the main loop (vim.system exits fire in a fast event).
local function run_steps(steps, on_done)
  local i = 0
  local function next_step()
    i = i + 1
    local cmd = steps[i]
    if not cmd then
      return on_done(true)
    end
    vim.system(cmd, { text = true }, function(out)
      vim.schedule(function()
        if out.code ~= 0 then
          local err = (out.stderr and out.stderr ~= "") and out.stderr or (out.stdout or "")
          return on_done(false, table.concat({ cmd[1] or "?", "exited " .. out.code, err }, ":\n"))
        end
        next_step()
      end)
    end)
  end
  next_step()
end

--- Collapse a single top-level dir (release archives usually wrap
--- their content in one); keeps the package dir layout flat and stable.
local function strip_single_dir(pkgdir)
  local entries = vim.fn.readdir(pkgdir)
  if #entries ~= 1 then
    return
  end
  local only = pkgdir .. "/" .. entries[1]
  if vim.uv.fs_stat(only).type ~= "directory" then
    return
  end
  for _, child in ipairs(vim.fn.readdir(only)) do
    vim.fn.rename(only .. "/" .. child, pkgdir .. "/" .. child)
  end
  vim.fn.delete(only, "d")
end

--- Wrapper scripts need absolute targets; regenerate on every install.
local function write_wrappers(pkgdir, wrappers)
  for name, spec in pairs(wrappers or {}) do
    local interp, target = spec[1], pkgdir .. "/" .. spec[2]
    local path = pkgdir .. "/" .. name
    local f = assert(io.open(path, "w"))
    f:write("#!/usr/bin/env bash\nexec " .. interp .. ' "' .. target .. '" "$@"\n')
    f:close()
    vim.uv.fs_chmod(path, 493) -- 0755
  end
end

--- Symlink exposed bins into tools/bin using relative targets so the
--- tree stays valid if it ever gets moved.
local function link_bins(tool, recipe)
  for _, bin in ipairs(recipe.bins or {}) do
    local rel = "packages/" .. tool .. "/"
    if recipe.method == "npm" then
      rel = rel .. "node_modules/.bin/" .. bin
    elseif recipe.method == "pip" then
      rel = rel .. "venv/bin/" .. bin
    else
      rel = rel .. (recipe.links and recipe.links[bin] or bin)
      vim.uv.fs_chmod(M.package_dir(tool) .. "/" .. (recipe.links and recipe.links[bin] or bin), 493)
    end
    local link = M.bin .. "/" .. bin
    pcall(vim.uv.fs_unlink, link)
    vim.uv.fs_symlink("../" .. rel, link)
  end
end

local function build_steps(tool, recipe, pkgdir, staging)
  if recipe.method == "npm" then
    -- pkg holds one or more space-separated specs (extra deps a tool
    -- needs but does not declare, e.g. typescript for the tsdk)
    local steps = { { "npm", "install", "--prefix", pkgdir, "--no-audit", "--no-fund", "--loglevel=error" } }
    for _, spec in ipairs(vim.split(recipe.pkg, "%s+")) do
      table.insert(steps[1], spec)
    end
    return steps
  end

  if recipe.method == "pip" then
    return {
      { "python3", "-m", "venv", "--system-site-packages", pkgdir .. "/venv" },
      { pkgdir .. "/venv/bin/pip", "install", "--no-cache-dir", "--quiet", recipe.pkg },
    }
  end

  -- github: download once into staging, then extract into the package dir
  local file = staging .. "/download"
  local steps = { { "curl", "-fL", "--retry", "3", "--connect-timeout", "15", "-o", file, recipe.url or "" } }
  -- gz/raw archives carry a single file: name it after the link target
  local asset = tool
  if recipe.links then
    local _, v = next(recipe.links)
    asset = v
  end
  if recipe.extract == "tar.gz" then
    table.insert(steps, { "tar", "xzf", file, "-C", pkgdir })
  elseif recipe.extract == "zip" then
    table.insert(steps, { "unzip", "-q", file, "-d", pkgdir })
  elseif recipe.extract == "gz" then
    -- single gzipped binary: decompress into the expected asset name
    table.insert(steps, { "bash", "-c", 'gunzip -c "$1" > "$2"', "gunzip", file, pkgdir .. "/" .. asset })
  else -- raw binary, no archive
    table.insert(steps, { "mv", file, pkgdir .. "/" .. asset })
  end
  return steps
end

--- Resolve recipes declared with a dir + latest.txt (eclipse-style).
--- Returns ok, url_or_err via callback (async: it hits the network).
local function resolve_url(recipe, on_done)
  if recipe.url then
    return on_done(true, recipe.url)
  end
  if not recipe.dir then
    -- npm/pip recipes download nothing themselves
    return on_done(true, nil)
  end
  vim.system({ "curl", "-fsSL", "--connect-timeout", "15", recipe.dir .. "latest.txt" }, { text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        return on_done(false, "latest.txt fetch failed for " .. recipe.dir)
      end
      local name = (out.stdout or ""):gsub("%s+$", "")
      if name == "" then
        return on_done(false, "latest.txt is empty for " .. recipe.dir)
      end
      on_done(true, recipe.dir .. name)
    end)
  end)
end

--- Install a tool (opts.force = reinstall over an existing package).
--- cb(ok, err).
function M.install(tool, opts, cb)
  opts = opts or {}
  local recipe = registry.recipes[tool]
  if not recipe then
    return cb(false, "no recipe for " .. tool)
  end

  local pkgdir = M.package_dir(tool)
  if vim.uv.fs_stat(pkgdir) then
    if not opts.force then
      return cb(false, tool .. " already installed")
    end
    vim.fn.delete(pkgdir, "rf")
  end

  vim.fn.mkdir(pkgdir, "p")
  vim.fn.mkdir(M.bin, "p")
  local staging = ROOT .. "/.staging/" .. tool
  vim.fn.mkdir(staging, "p")

  resolve_url(recipe, function(ok, url_or_err)
    if not ok then
      vim.fn.delete(pkgdir, "rf")
      return cb(false, url_or_err)
    end
    local recipe2 = vim.tbl_extend("force", {}, recipe, { url = url_or_err })
    run_steps(build_steps(tool, recipe2, pkgdir, staging), function(ok2, err)
      vim.fn.delete(staging, "rf")
      if not ok2 then
        vim.fn.delete(pkgdir, "rf")
        return cb(false, err)
      end
      if recipe2.strip then
        strip_single_dir(pkgdir)
      end
      write_wrappers(pkgdir, recipe2.pkg_wrappers)
      link_bins(tool, recipe2)
      cb(true)
    end)
  end)
end

--- Uninstall: refuses when any language card still lists the tool
--- (ref-count between cards) unless force is set.
function M.remove(tool, force)
  local ok_langs, languages = pcall(require, "languages")
  if ok_langs then
    local users = {}
    for _, ficha in ipairs(languages.all()) do
      for _, t in ipairs(ficha.tools or {}) do
        if t == tool then
          table.insert(users, ficha.name or "?")
        end
      end
    end
    if #users > 0 and not force then
      return false, tool .. " is still required by: " .. table.concat(users, ", ")
    end
  end

  local recipe = registry.recipes[tool] or {}
  for _, bin in ipairs(recipe.bins or {}) do
    pcall(vim.uv.fs_unlink, M.bin .. "/" .. bin)
  end
  vim.fn.delete(M.package_dir(tool), "rf")
  return true
end

--- Missing tools for a list of tool names.
function M.missing(tools)
  local out = {}
  for _, tool in ipairs(tools or {}) do
    if not M.is_installed(tool) then
      table.insert(out, tool)
    end
  end
  return out
end

return M
