-- Omarchy theme support for this kickstart-based (vim.pack) Neovim setup.
--
-- On an Omarchy system Neovim follows `omarchy theme set <name>`. Omarchy
-- writes the current theme as ~/.local/state/omarchy/current/theme/neovim.lua,
-- a LazyVim plugin spec: themes ship their own spec pointing at their
-- colorscheme plugin, while template-generated themes (ethereal, vantablack,
-- white, ...) are built on top of aether.nvim with the full palette already
-- baked into the spec's `opts.colors`. This module consumes that same spec
-- directly -- no colors.toml parsing, no palette re-derivation:
--
--   * themes whose spec names a colorscheme plugin (tokyo-night, catppuccin,
--     nord, ...) are applied with that plugin;
--   * aether-based themes reuse the palette Omarchy itself baked in.
--
-- The spec is evaluated with an empty environment (it is pure data) and any
-- plugin it names is installed on demand through vim.pack, so the first use of
-- a new theme needs network access. On hosts without Omarchy the state
-- directory does not exist and apply() returns false, leaving the regular
-- colorscheme setup in init.lua in charge.
local M = {}

local pack_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'site', 'pack', 'core', 'opt')
local state_dir = vim.fs.joinpath(vim.env.HOME or '', '.local', 'state', 'omarchy', 'current')
local theme_dir = vim.fs.joinpath(state_dir, 'theme')
local theme_name_file = vim.fs.joinpath(state_dir, 'theme.name')

local watched_snapshot

---@return string|nil
function M.theme_name()
  local file = io.open(theme_name_file, 'r')
  if not file then
    return nil
  end
  local name = file:read 'l'
  file:close()
  return name
end

---@return string|nil
function M.theme_dir()
  if vim.fn.isdirectory(theme_dir) ~= 1 then
    return nil
  end
  return theme_dir
end

---@return string|nil
function M.state_dir()
  if vim.fn.isdirectory(state_dir) ~= 1 then
    return nil
  end
  return state_dir
end

---@return boolean
function M.is_omarchy()
  return M.theme_dir() ~= nil
end

---Infer light/dark from the theme background, as no mode is carried in the spec.
---@param bg string|nil
---@return string
local function mode_from_bg(bg)
  if bg and #bg == 7 and bg:sub(1, 1) == '#' and bg:find('^[0-9a-fA-F]+$', 2) then
    local r = tonumber(bg:sub(2, 3), 16)
    local g = tonumber(bg:sub(4, 5), 16)
    local b = tonumber(bg:sub(6, 7), 16)
    return r + g + b > 382 and 'light' or 'dark'
  end
  return 'dark'
end

---Load a theme's neovim.lua (a LazyVim plugin spec) in an empty environment.
---@param path string
---@return table[]|nil
local function load_spec(path)
  local file = io.open(path, 'rb')
  if not file then
    return nil
  end
  local chunk = file:read 'a'
  file:close()
  local fn, err = load(chunk, '@' .. path, 't', {})
  if not fn then
    return nil
  end
  local ok, spec = pcall(fn)
  if not ok or type(spec) ~= 'table' then
    vim.notify('Omarchy theme: ignoring invalid ' .. path .. (ok and ' (not a table)' or ': ' .. tostring(spec)), vim.log.levels.WARN)
    return nil
  end
  return spec
end

---Extract the parts of the LazyVim spec this setup can act on.
---@param spec table[]
---@return { src?: string, name?: string, branch?: string, dependencies?: any, colorscheme?: string, background?: string, colors?: table[] }
local function parse_spec(spec)
  local parsed = {}
  for _, entry in ipairs(spec or {}) do
    if type(entry) == 'table' then
      local src = entry[1]
      local is_lazyvim = src == 'LazyVim/LazyVim'
      if is_lazyvim and type(entry.opts) == 'table' then
        parsed.colorscheme = entry.opts.colorscheme
        parsed.background = entry.opts.background
      elseif not is_lazyvim and type(src) == 'string' and not parsed.src then
        parsed.src = src
        parsed.name = entry.name
        parsed.branch = entry.branch
        parsed.dependencies = entry.dependencies
        if type(entry.opts) == 'table' and type(entry.opts.colors) == 'table' then
          parsed.colors = entry.opts.colors
        end
      end
    end
  end
  return parsed
end

---Directory a plugin ends up in, mirroring vim.pack's naming.
---@param src string
---@param name string|nil
---@return string
local function plugin_dir_for(src, name)
  return vim.fs.joinpath(pack_dir, name or src:match '[^/]+$')
end

---Add an installed plugin to the runtimepath (packadd) so both its colors/ and
---lua/ directories are visible; a freshly installed opt plugin would otherwise
---only be found via packpath, and requiring it inside a colorscheme would fail.
---@param dir string
local function packadd_plugin(dir)
  local name = dir:match '[^/]+$'
  if name then
    pcall(vim.cmd.packadd, name)
  end
end

---Install a plugin through vim.pack on demand (no-op when already present).
---@param src string
---@param opts? { name?: string, branch?: string }
---@return string|nil
local function ensure_plugin(src, opts)
  if vim.fn.executable 'git' ~= 1 then
    return nil
  end
  local dir = plugin_dir_for(src, opts and opts.name)
  if vim.fn.isdirectory(dir) == 1 then
    packadd_plugin(dir)
    return dir
  end
  local spec = { src = 'https://github.com/' .. src }
  if opts and opts.name then
    spec.name = opts.name
  end
  if opts and opts.branch then
    spec.version = opts.branch
  end
  vim.pack.add { spec }
  packadd_plugin(dir)
  return dir
end

---Apply a colorscheme named by the theme spec, trying the plugin's own name
---and finally any colorscheme the plugin ships.
---@param parsed omarchy_theme.Parsed
---@return boolean
local function apply_colorscheme(parsed)
  local dir = plugin_dir_for(parsed.src, parsed.name)
  packadd_plugin(dir)
  local tried = {}
  for _, candidate in ipairs { parsed.colorscheme, parsed.name } do
    if candidate and not tried[candidate] then
      tried[candidate] = true
      local lua = vim.fs.joinpath(dir, 'colors', candidate .. '.lua')
      local vim_script = vim.fs.joinpath(dir, 'colors', candidate .. '.vim')
      if vim.fn.filereadable(lua) == 1 or vim.fn.filereadable(vim_script) == 1 then
        vim.cmd.colorscheme(candidate)
        return true
      end
      if pcall(vim.cmd.colorscheme, candidate) then
        return true
      end
    end
  end
  for _, file in ipairs(vim.fn.glob(vim.fs.joinpath(dir, 'colors', '*'), false, true)) do
    local base = vim.fn.fnamemodify(file, ':t:r')
    if not tried[base] then
      pcall(vim.cmd.colorscheme, base)
      return true
    end
  end
  return false
end

---Apply a template-generated theme through aether.nvim, using the palette that
---Omarchy already baked into the generated spec's `opts.colors`.
---@param colors table|nil
---@param mode string
---@return boolean
local function apply_aether(colors, mode)
  if not ensure_plugin('bjarneo/aether.nvim', { name = 'aether', branch = 'v3' }) then
    return false
  end
  vim.o.background = mode
  local ok = pcall(function()
    require('aether').setup {
      colors = colors or {},
      styles = { comments = { italic = false } },
    }
    vim.cmd.colorscheme 'aether'
  end)
  if not ok then
    vim.notify('Omarchy theme: aether failed to apply', vim.log.levels.WARN)
  end
  return ok
end

---Apply the current Omarchy theme to Neovim. Returns false when Omarchy is not
---available (so callers fall back to their default colorscheme).
---@return boolean
function M.apply()
  local dir = M.theme_dir()
  if not dir then
    return false
  end
  local spec_path = vim.fs.joinpath(dir, 'neovim.lua')
  if vim.fn.filereadable(spec_path) ~= 1 then
    return false
  end

  local spec = load_spec(spec_path)
  if not spec then
    return false
  end
  local parsed = parse_spec(spec)

  -- Clear stale highlights before (re)applying the theme.
  vim.cmd 'highlight clear'
  if vim.fn.exists 'syntax_on' == 1 then
    vim.cmd 'syntax reset'
  end
  vim.o.background = 'dark'

  -- Template-generated themes are built on aether and carry their own palette.
  if parsed.src == 'bjarneo/aether.nvim' then
    return apply_aether(parsed.colors, mode_from_bg(parsed.colors and parsed.colors.bg))
  end

  if not parsed.src then
    return false
  end

  ensure_plugin(parsed.src, { name = parsed.name, branch = parsed.branch })
  if parsed.dependencies then
    for _, dep in ipairs(parsed.dependencies) do
      if type(dep) == 'string' then
        ensure_plugin(dep)
      elseif type(dep) == 'table' then
        ensure_plugin(dep[1], { name = dep.name, branch = dep.branch })
      end
    end
  end

  vim.o.background = (parsed.background == 'light' or parsed.background == 'dark') and parsed.background or 'dark'
  return parsed.colorscheme and apply_colorscheme(parsed) == true
end

---@return string
local function current_snapshot()
  local name = M.theme_name() or ''
  local dir = M.theme_dir()
  if not dir then
    return name
  end
  local function stamp(path)
    local stat = vim.uv.fs_stat(vim.fs.joinpath(dir, path))
    return (stat and stat.mtime and stat.mtime.sec) or 0
  end
  return string.format('%s|%s|%s', name, stamp 'neovim.lua', stamp 'colors.toml')
end

---Watch the Omarchy state directory and re-apply the theme when it changes
---(including live switching with `omarchy theme set`).
function M.watch()
  if M._watcher or not state_dir or vim.fn.isdirectory(state_dir) ~= 1 then
    return
  end
  local handle = vim.uv.new_fs_event()
  local timer = vim.uv.new_timer()
  watched_snapshot = current_snapshot()
  local started = pcall(function()
    handle:start(
      state_dir,
      {},
      vim.schedule_wrap(function()
        timer:start(
          1000,
          0,
          vim.schedule_wrap(function()
            local snapshot = current_snapshot()
            if snapshot ~= watched_snapshot then
              watched_snapshot = snapshot
              if M.apply() then
                vim.cmd 'redraw!'
              end
            end
          end)
        )
      end)
    )
  end)
  if started then
    M._watcher = { handle = handle, timer = timer }
  end
end

---Register user-facing helpers. Called once after apply() succeeds.
function M.setup()
  vim.api.nvim_create_user_command('OmarchyTheme', function()
    if M.apply() then
      vim.cmd 'redraw!'
    end
  end, { desc = 'Re-apply the current Omarchy theme to Neovim' })
  M.watch()
end

return M
