#!/usr/bin/env -S nvim -l

-- Generator for various vimdoc and Lua type files

local util = require('gen.util')
local api_type = require('gen.api_types')
local fmt = string.format

local DEP_API_METADATA = arg[1]
local TAGS_FILE = arg[2]
local TEXT_WIDTH = 78

--- @class vim.api.metadata
--- @field name string
--- @field parameters [string,string][]
--- @field return_type string
--- @field deprecated_since integer
--- @field eval boolean
--- @field fast boolean
--- @field handler_id integer
--- @field impl_name string
--- @field lua boolean
--- @field method boolean
--- @field remote boolean
--- @field since integer

local LUA_META_HEADER = {
  '--- @meta _',
  '-- THIS FILE IS GENERATED',
  '-- DO NOT EDIT',
  "error('Cannot require a meta file')",
}

local LUA_API_META_HEADER = {
  '--- @meta _',
  '-- THIS FILE IS GENERATED',
  '-- DO NOT EDIT',
  "error('Cannot require a meta file')",
  '',
  '--- This file embeds vimdoc as the function descriptions',
  '--- so ignore any doc related errors.',
  '--- @diagnostic disable: undefined-doc-name,luadoc-miss-symbol',
  '',
  'vim.api = {}',
}

local LUA_OPTION_META_HEADER = {
  '--- @meta _',
  '-- THIS FILE IS GENERATED',
  '-- DO NOT EDIT',
  "error('Cannot require a meta file')",
  '',
  '---@class vim.bo',
  '---@field [integer] vim.bo',
  'vim.bo = vim.bo',
  '',
  '---@class vim.wo',
  '---@field [integer] vim.wo',
  'vim.wo = vim.wo',
}

local LUA_VVAR_META_HEADER = {
  '--- @meta _',
  '-- THIS FILE IS GENERATED',
  '-- DO NOT EDIT',
  "error('Cannot require a meta file')",
  '',
  '--- @class vim.v',
  'vim.v = ...',
}

local LUA_KEYWORDS = {
  ['and'] = true,
  ['end'] = true,
  ['function'] = true,
  ['or'] = true,
  ['if'] = true,
  ['while'] = true,
  ['repeat'] = true,
  ['true'] = true,
  ['false'] = true,
}

local OPTION_TYPES = {
  boolean = 'boolean',
  number = 'integer',
  string = 'string',
}

--- @param s string
--- @return string
local function luaescape(s)
  if LUA_KEYWORDS[s] then
    return s .. '_'
  end
  return s
end

--- @param x string
--- @param sep? string
--- @return string[]
local function split(x, sep)
  return vim.split(x, sep or '\n', { plain = true })
end

--- @param f string
--- @param params [string,string][]|true
--- @return string
local function render_fun_sig(f, params)
  local param_str --- @type string
  if params == true then
    param_str = '...'
  else
    param_str = table.concat(
      vim.tbl_map(
        --- @param v [string,string]
        --- @return string
        function(v)
          return luaescape(v[1])
        end,
        params
      ),
      ', '
    )
  end

  if LUA_KEYWORDS[f] then
    return fmt("vim.fn['%s'] = function(%s) end", f, param_str)
  else
    return fmt('function vim.fn.%s(%s) end', f, param_str)
  end
end

--- Uniquify names
--- @param params [string,string,string][]
--- @return [string,string,string][]
local function process_params(params)
  local seen = {} --- @type table<string,true>
  local sfx = 1

  for _, p in ipairs(params) do
    if seen[p[1]] then
      p[1] = p[1] .. sfx
      sfx = sfx + 1
    else
      seen[p[1]] = true
    end
  end

  return params
end

--- @return table<string, vim.EvalFn>
local function get_api_meta()
  local ret = {} --- @type table<string, vim.EvalFn>

  local cdoc_parser = require('gen.cdoc_parser')

  local f = 'src/nvim/api'

  local function include(fun)
    if not vim.startswith(fun.name, 'nvim_') then
      return false
    end
    if vim.tbl_contains(fun.attrs or {}, 'lua_only') then
      return true
    end
    if vim.tbl_contains(fun.attrs or {}, 'remote_only') then
      return false
    end
    return true
  end

  --- @type table<string,nvim.cdoc.parser.fun>
  local functions = {}
  for path, ty in vim.fs.dir(f) do
    if ty == 'file' then
      local filename = vim.fs.joinpath(f, path)
      local _, funs = cdoc_parser.parse(filename)
      for _, fn in ipairs(funs) do
        if include(fn) then
          functions[fn.name] = fn
        end
      end
    end
  end

  for _, fun in pairs(functions) do
    local deprecated = fun.deprecated_since ~= nil

    local notes = {} --- @type string[]
    for _, note in ipairs(fun.notes or {}) do
      notes[#notes + 1] = note.desc
    end

    local sees = {} --- @type string[]
    for _, see in ipairs(fun.see or {}) do
      sees[#sees + 1] = see.desc
    end

    local params = {} --- @type [string,string][]
    for _, p in ipairs(fun.params) do
      params[#params + 1] = {
        p.name,
        p.type,
        not deprecated and p.desc or nil,
      }
    end

    local r = {
      signature = 'NA',
      name = fun.name,
      params = params,
      notes = notes,
      see = sees,
      returns = fun.returns[1].type,
      deprecated = deprecated,
    }

    if not deprecated then
      r.desc = fun.desc
      r.returns_desc = fun.returns[1].desc
    end

    ret[fun.name] = r
  end
  return ret
end

--- Convert vimdoc references to markdown literals
--- Convert vimdoc codeblocks to markdown codeblocks
---
--- Ensure code blocks have one empty line before the start fence and after the closing fence.
---
--- @param x string
--- @param special string?
---                | 'see-api-meta' Normalize `@see` for API meta docstrings.
--- @return string
local function norm_text(x, special)
  if special == 'see-api-meta' then
    -- Try to guess a symbol that actually works in @see.
    -- "nvim_xx()" => "vim.api.nvim_xx"
    x = x:gsub([=[%|?(nvim_[^.()| ]+)%(?%)?%|?]=], 'vim.api.%1')
    -- TODO: Remove backticks when LuaLS resolves: https://github.com/LuaLS/lua-language-server/issues/2889
    -- "|foo|" => "`:help foo`"
    x = x:gsub([=[|([^%s|]+)|]=], '`:help %1`')
  end

  return (
    x:gsub('|([^%s|]+)|', '`%1`')
      :gsub('\n*>lua', '\n\n```lua')
      :gsub('\n*>vim', '\n\n```vim')
      :gsub('\n+<$', '\n```')
      :gsub('\n+<\n+', '\n```\n\n')
      :gsub('%s+>\n+', '\n```\n')
      :gsub('\n+<%s+\n?', '\n```\n')
  )
end

--- Generates LuaLS docstring for an API function.
--- @param _f string
--- @param fun vim.EvalFn
--- @param write fun(line: string)
local function render_api_meta(_f, fun, write)
  write('')

  if fun.deprecated then
    write('--- @deprecated')
  end

  local desc = fun.desc
  if desc then
    write(util.prefix_lines('--- ', norm_text(desc)))
  end

  -- LuaLS doesn't support @note. Render @note items as a markdown list.
  if fun.notes and #fun.notes > 0 then
    write('--- Note:')
    write(util.prefix_lines('--- ', table.concat(fun.notes, '\n')))
    write('---')
  end

  for _, see in ipairs(fun.see or {}) do
    write(util.prefix_lines('--- @see ', norm_text(see, 'see-api-meta')))
  end

  local param_names = {} --- @type string[]
  local params = process_params(fun.params)
  for _, p in ipairs(params) do
    local pname, ptype, pdesc = luaescape(p[1]), p[2], p[3]
    param_names[#param_names + 1] = pname
    if pdesc then
      local s = '--- @param ' .. pname .. ' ' .. ptype .. ' '
      local pdesc_a = split(vim.trim(norm_text(pdesc)))
      write(s .. pdesc_a[1])
      for i = 2, #pdesc_a do
        if not pdesc_a[i] then
          break
        end
        write('--- ' .. pdesc_a[i])
      end
    else
      write('--- @param ' .. pname .. ' ' .. ptype)
    end
  end

  if fun.returns ~= 'nil' then
    local ret_desc = fun.returns_desc and ' # ' .. fun.returns_desc or ''
    write(util.prefix_lines('--- ', '@return ' .. fun.returns .. ret_desc))
  end
  local param_str = table.concat(param_names, ', ')

  write(fmt('function vim.api.%s(%s) end', fun.name, param_str))
end

--- @return table<string, vim.EvalFn>
local function get_api_keysets_meta()
  local mpack_f = assert(io.open(DEP_API_METADATA, 'rb'))
  local metadata = assert(vim.mpack.decode(mpack_f:read('*all')))

  local ret = {} --- @type table<string, vim.EvalFn>

  --- @type {name: string, keys: string[], types: table<string,string>}[]
  local keysets = metadata.keysets
  local event_type = 'vim.api.keyset.events|vim.api.keyset.events[]'

  for _, k in ipairs(keysets) do
    local params = {}
    for _, key in ipairs(k.keys) do
      local pty = k.types[key] or 'any'
      table.insert(params, {
        key .. '?',
        k.name:find('autocmd') and key == 'event' and event_type or api_type(pty),
      })
    end
    ret[k.name] = {
      signature = 'NA',
      name = k.name,
      params = params,
    }
  end

  return ret
end

--- Generates LuaLS docstring for an API keyset.
--- @param _f string
--- @param fun vim.EvalFn
--- @param write fun(line: string)
local function render_api_keyset_meta(_f, fun, write)
  if string.sub(fun.name, 1, 1) == '_' then
    return -- not exported
  elseif fun.name == 'create_autocmd' then
    local events = vim.deepcopy(require('nvim.auevents'))
    for event in pairs(events.aliases) do
      events.events[event] = true
    end
    write('')
    write('--- @alias vim.api.keyset.events')
    for event in vim.spairs(events.events) do
      write(("--- |'%s'"):format(event))
    end
  end
  write('')
  write('--- @class vim.api.keyset.' .. fun.name)
  for _, p in ipairs(fun.params) do
    write('--- @field ' .. p[1] .. ' ' .. p[2])
  end
end

--- @return table<string, vim.EvalFn>
local function get_eval_meta()
  return require('nvim.eval').funcs
end

--- Generates LuaLS docstring for a Vimscript "eval" function.
--- @param f string
--- @param fun vim.EvalFn
--- @param write fun(line: string)
local function render_eval_meta(f, fun, write)
  if fun.lua == false then
    return
  end

  local funname = fun.name or f
  local params = process_params(fun.params)

  write('')
  if fun.deprecated then
    write('--- @deprecated')
  end

  local desc = fun.desc

  if desc then
    --- @type string
    desc = desc:gsub('\n%s*\n%s*$', '\n')
    for _, l in ipairs(split(desc)) do
      l = l:gsub('^      ', ''):gsub('\t', '  '):gsub('@', '\\@')
      write('--- ' .. l)
    end
  end

  for _, text in ipairs(vim.fn.reverse(fun.generics or {})) do
    write(fmt('--- @generic %s', text))
  end

  local req_args = type(fun.args) == 'table' and fun.args[1] or fun.args or 0

  for i, param in ipairs(params) do
    local pname, ptype = luaescape(param[1]), param[2]
    local optional = (pname ~= '...' and i > req_args) and '?' or ''
    write(fmt('--- @param %s%s %s', pname, optional, ptype))
  end

  if fun.returns ~= false then
    local ret_desc = fun.returns_desc and ' # ' .. fun.returns_desc or ''
    write('--- @return ' .. (fun.returns or 'any') .. ret_desc)
  end

  write(render_fun_sig(funname, params))
end

--- Generates vimdoc heading for a Vimscript "eval" function signature.
--- @param name string
--- @param name_tag boolean
--- @param fun vim.EvalFn
--- @param write fun(line: string)
local function render_sig_and_tag(name, name_tag, fun, write)
  if not fun.signature then
    return
  end

  local tags = name_tag and { '*' .. name .. '()*' } or {}

  if fun.tags then
    for _, t in ipairs(fun.tags) do
      tags[#tags + 1] = '*' .. t .. '*'
    end
  end

  if #tags == 0 then
    write(fun.signature)
    return
  end

  local tag = table.concat(tags, ' ')
  local siglen = #fun.signature
  local conceal_offset = 2 * (#tags - 1)
  local tag_pad_len = math.max(1, 80 - #tag + conceal_offset)

  if siglen + #tag > 80 then
    write(string.rep(' ', tag_pad_len) .. tag)
    write(fun.signature)
  else
    write(fmt('%s%s%s', fun.signature, string.rep(' ', tag_pad_len - siglen), tag))
  end
end

--- Generates vimdoc for a Vimscript "eval" function.
--- @param f string
--- @param fun vim.EvalFn
--- @param write fun(line: string)
local function render_eval_doc(f, fun, write)
  if fun.deprecated or not fun.signature then
    return
  end

  render_sig_and_tag(fun.name or f, not f:find('__%d+$'), fun, write)

  if not fun.desc then
    return
  end

  local params = process_params(fun.params)
  local req_args = type(fun.args) == 'table' and fun.args[1] or fun.args or 0

  local desc_l = split(vim.trim(fun.desc))
  for _, l in ipairs(desc_l) do
    l = l:gsub('^      ', '')
    if vim.startswith(l, '<') and not l:match('^<[^ \t]+>') then
      write('<\t\t' .. l:sub(2))
    elseif l:match('^>[a-z0-9]*$') then
      write(l)
    else
      write('\t\t' .. l)
    end
  end

  if #desc_l > 0 and not desc_l[#desc_l]:match('^<?$') then
    write('')
  end

  if #params > 0 then
    write(util.md_to_vimdoc('Parameters: ~', 16, 16, TEXT_WIDTH))
    for i, param in ipairs(params) do
      local pname, ptype = param[1], param[2]
      local optional = (pname ~= '...' and i > req_args) and '?' or ''
      local s = fmt('- %-14s (`%s%s`)', fmt('{%s}', pname), ptype, optional)
      write(util.md_to_vimdoc(s, 16, 18, TEXT_WIDTH))
    end
    write('')
  end

  if fun.returns ~= false then
    write(util.md_to_vimdoc('Return: ~', 16, 16, TEXT_WIDTH))
    local ret = fmt('(`%s`)', (fun.returns or 'any'))
    ret = ret .. (fun.returns_desc and ' ' .. fun.returns_desc or '')
    ret = util.md_to_vimdoc(ret, 18, 18, TEXT_WIDTH)
    write(ret)
    write('')
  end
end

--- @param d vim.option_defaults
--- @param vimdoc? boolean
--- @return string
local function render_option_default(d, vimdoc)
  local dt --- @type integer|boolean|string|fun(): string
  if d.if_false ~= nil then
    dt = d.if_false
  else
    dt = d.if_true
  end

  if vimdoc then
    if d.doc then
      return d.doc
    end
    if type(dt) == 'boolean' then
      return dt and 'on' or 'off'
    end
  end

  if dt == '' or dt == nil or type(dt) == 'function' then
    dt = d.meta
  end

  local v --- @type string
  if not vimdoc then
    v = vim.inspect(dt) --[[@as string]]
  else
    v = type(dt) == 'string' and '"' .. dt .. '"' or tostring(dt)
  end

  --- @type table<string, string|false>
  local envvars = {
    TMPDIR = false,
    VIMRUNTIME = false,
    XDG_CONFIG_HOME = vim.env.HOME .. '/.local/config',
    XDG_DATA_HOME = vim.env.HOME .. '/.local/share',
    XDG_STATE_HOME = vim.env.HOME .. '/.local/state',
  }

  for name, default in pairs(envvars) do
    local value = vim.env[name] or default
    if value then
      v = v:gsub(vim.pesc(value), '$' .. name)
    end
  end

  return v
end

--- @param _f string
--- @param opt vim.option_meta
--- @param write fun(line: string)
local function render_option_meta(_f, opt, write)
  write('')
  for _, l in ipairs(split(norm_text(opt.desc))) do
    write('--- ' .. l)
  end

  if opt.type == 'string' and not opt.list and opt.values then
    local values = {} --- @type string[]
    for _, e in ipairs(opt.values) do
      values[#values + 1] = fmt("'%s'", e)
    end
    write('--- @type ' .. table.concat(values, '|'))
  else
    write('--- @type ' .. OPTION_TYPES[opt.type])
  end

  write('vim.o.' .. opt.full_name .. ' = ' .. render_option_default(opt.defaults))
  if opt.abbreviation then
    write('vim.o.' .. opt.abbreviation .. ' = vim.o.' .. opt.full_name)
  end

  for _, s in pairs {
    { 'wo', 'win' },
    { 'bo', 'buf' },
    { 'go', 'global' },
  } do
    local id, scope = s[1], s[2]
    if vim.list_contains(opt.scope, scope) or (id == 'go' and #opt.scope > 1) then
      local pfx = 'vim.' .. id .. '.'
      write(pfx .. opt.full_name .. ' = vim.o.' .. opt.full_name)
      if opt.abbreviation then
        write(pfx .. opt.abbreviation .. ' = ' .. pfx .. opt.full_name)
      end
    end
  end
end

--- @param _f string
--- @param opt vim.option_meta
--- @param write fun(line: string)
local function render_vvar_meta(_f, opt, write)
  write('')

  local desc = split(norm_text(opt.desc))
  while desc[#desc]:match('^%s*$') do
    desc[#desc] = nil
  end

  for _, l in ipairs(desc) do
    write('--- ' .. l)
  end

  write('--- @type ' .. (opt.type or 'any'))

  if LUA_KEYWORDS[opt.full_name] then
    write("vim.v['" .. opt.full_name .. "'] = ...")
  else
    write('vim.v.' .. opt.full_name .. ' = ...')
  end
end

--- @param s string[]
--- @return string
local function scope_to_doc(s)
  local m = {
    global = 'global',
    buf = 'local to buffer',
    win = 'local to window',
    tab = 'local to tab page',
  }

  if #s == 1 then
    return m[s[1]]
  end
  assert(s[1] == 'global')
  return 'global or ' .. m[s[2]] .. (s[2] ~= 'tab' and ' |global-local|' or '')
end

-- @param o vim.option_meta
-- @return string
local function scope_more_doc(o)
  if
    vim.list_contains({
      'bufhidden',
      'buftype',
      'filetype',
      'modified',
      'previewwindow',
      'readonly',
      'scroll',
      'syntax',
      'winfixheight',
      'winfixwidth',
    }, o.full_name)
  then
    return '  |local-noglobal|'
  end

  return ''
end

--- @param x string
local function dedent(x)
  return (vim.text.indent(0, (x:gsub('\n%s-([\n]?)$', '\n%1'))))
end

--- @return table<string,vim.option_meta>
local function get_option_meta()
  local opts = require('nvim.options').options
  local optinfo = vim.api.nvim_get_all_options_info()
  local ret = {} --- @type table<string,vim.option_meta>
  for _, o in ipairs(opts) do
    local is_window_option = #o.scope == 1 and o.scope[1] == 'win'
    local is_option_hidden = o.immutable and not o.varname and not is_window_option
    if not is_option_hidden and o.desc then
      if o.full_name == 'cmdheight' then
        table.insert(o.scope, 'tab')
      end
      local r = vim.deepcopy(o) --[[@as vim.option_meta]]
      r.desc = o.desc:gsub('^        ', ''):gsub('\n        ', '\n')
      if o.full_name == 'eventignorewin' then
        local events = require('nvim.auevents').events
        local tags_file = assert(io.open(TAGS_FILE))
        local tags_text = tags_file:read('*a')
        tags_file:close()
        local map_fn = function(event_name, is_window_local)
          if is_window_local then
            return nil -- Don't include in the list of events outside window context.
          end
          local tag_pat = fmt('\n%s\t([^\t]+)\t', event_name)
          local link_text = fmt('|%s|', event_name)
          local tags_match = tags_text:match(tag_pat) --- @type string?
          return tags_match and tags_match ~= 'deprecated.txt' and link_text or nil
        end
        local extra_desc = vim.iter(vim.spairs(events)):map(map_fn):join(',\n\t')
        r.desc = r.desc:gsub('<PLACEHOLDER>', extra_desc)
      end
      r.defaults = r.defaults or {}
      if r.defaults.meta == nil then
        r.defaults.meta = optinfo[o.full_name].default
      end
      ret[o.full_name] = r
    end
  end
  return ret
end

--- @return table<string,vim.option_meta>
local function get_vvar_meta()
  local info = require('nvim.vvars').vars
  local ret = {} --- @type table<string,vim.option_meta>
  for name, o in pairs(info) do
    o.desc = dedent(o.desc)
    o.full_name = name
    ret[name] = o
  end
  return ret
end

--- @param opt vim.option_meta
--- @return string[]
local function build_option_tags(opt)
  --- @type string[]
  local tags = { opt.full_name }

  tags[#tags + 1] = opt.abbreviation
  if opt.type == 'boolean' then
    for i = 1, #tags do
      tags[#tags + 1] = 'no' .. tags[i]
    end
  end

  for i, t in ipairs(tags) do
    tags[i] = "'" .. t .. "'"
  end

  for _, t in ipairs(opt.tags or {}) do
    tags[#tags + 1] = t
  end

  for i, t in ipairs(tags) do
    tags[i] = '*' .. t .. '*'
  end

  return tags
end

--- @param _f string
--- @param opt vim.option_meta
--- @param write fun(line: string)
local function render_option_doc(_f, opt, write)
  local tags = build_option_tags(opt)
  local tag_str = table.concat(tags, ' ')
  local conceal_offset = 2 * (#tags - 1)
  local tag_pad = string.rep('\t', math.ceil((64 - #tag_str + conceal_offset) / 8))
  -- local pad = string.rep(' ', 80 - #tag_str + conceal_offset)
  write(tag_pad .. tag_str)

  local name_str --- @type string
  if opt.abbreviation then
    name_str = fmt("'%s' '%s'", opt.full_name, opt.abbreviation)
  else
    name_str = fmt("'%s'", opt.full_name)
  end

  local otype = opt.type == 'boolean' and 'boolean' or opt.type
  if opt.defaults.doc or opt.defaults.if_true ~= nil or opt.defaults.meta ~= nil then
    local v = render_option_default(opt.defaults, true)
    local pad = string.rep('\t', math.max(1, math.ceil((24 - #name_str) / 8)))
    if opt.defaults.doc then
      local deflen = #fmt('%s%s%s (', name_str, pad, otype)
      --- @type string
      v = v:gsub('\n', '\n' .. string.rep(' ', deflen - 2))
    end
    write(fmt('%s%s%s\t(default %s)', name_str, pad, otype, v))
  else
    write(fmt('%s\t%s', name_str, otype))
  end

  write('\t\t\t' .. scope_to_doc(opt.scope) .. scope_more_doc(opt))
  for _, l in ipairs(split(opt.desc)) do
    if l == '<' or l:match('^<%s') then
      write(l)
    else
      write('\t' .. l:gsub('\\<', '<'))
    end
  end
end

--- @param _f string
--- @param vvar vim.option_meta
--- @param write fun(line: string)
local function render_vvar_doc(_f, vvar, write)
  local name = vvar.full_name

  local tags = { 'v:' .. name, name .. '-variable' }
  if vvar.tags then
    vim.list_extend(tags, vvar.tags)
  end

  for i, t in ipairs(tags) do
    tags[i] = '*' .. t .. '*'
  end

  local tag_str = table.concat(tags, ' ')
  local conceal_offset = 2 * (#tags - 1)

  local tag_pad = string.rep('\t', math.ceil((64 - #tag_str + conceal_offset) / 8))
  write(tag_pad .. tag_str)

  local desc = split(vvar.desc)

  if (#desc == 1 or #desc == 2 and desc[2]:match('^%s*$')) and #name < 10 then
    -- single line
    write('v:' .. name .. '\t' .. desc[1]:gsub('^%s*', ''))
    write('')
  else
    write('v:' .. name)
    for _, l in ipairs(desc) do
      if l == '<' or l:match('^<%s') then
        write(l)
      else
        write('\t\t' .. l:gsub('\\<', '<'))
      end
    end
  end
end

--- @class nvim.gen_eval_files.elem
--- @field path string
--- @field from? string Skip lines in path until this pattern is reached.
--- @field funcs fun(): table<string, table>
--- @field render fun(f:string,obj:table,write:fun(line:string))
--- @field header? string[]
--- @field footer? string[]

--- @type nvim.gen_eval_files.elem[]
local CONFIG = {
  {
    path = 'runtime/lua/vim/_meta/vimfn.lua',
    header = LUA_META_HEADER,
    funcs = get_eval_meta,
    render = render_eval_meta,
  },
  {
    path = 'runtime/lua/vim/_meta/api.lua',
    header = LUA_API_META_HEADER,
    funcs = get_api_meta,
    render = render_api_meta,
  },
  {
    path = 'runtime/lua/vim/_meta/api_keysets.lua',
    header = LUA_META_HEADER,
    funcs = get_api_keysets_meta,
    render = render_api_keyset_meta,
  },
  {
    path = 'runtime/doc/vimfn.txt',
    funcs = get_eval_meta,
    render = render_eval_doc,
    header = {
      '*vimfn.txt*	Nvim',
      '',
      '',
      '\t\t  NVIM REFERENCE MANUAL',
      '',
      '',
      'Vimscript functions\t\t\t*vimscript-functions* *builtin.txt*',
      '',
      'For functions grouped by what they are used for see |function-list|.',
      '',
      '\t\t\t\t      Type |gO| to see the table of contents.',
      '==============================================================================',
      '1. Details					*vimscript-functions-details*',
      '',
    },
    footer = {
      '==============================================================================',
      '2. Matching a pattern in a String			*string-match*',
      '',
      'This is common between several functions. A regexp pattern as explained at',
      '|pattern| is normally used to find a match in the buffer lines.  When a',
      'pattern is used to find a match in a String, almost everything works in the',
      'same way.  The difference is that a String is handled like it is one line.',
      'When it contains a "\\n" character, this is not seen as a line break for the',
      'pattern.  It can be matched with a "\\n" in the pattern, or with ".".  Example:',
      '>vim',
      '\tlet a = "aaaa\\nxxxx"',
      '\techo matchstr(a, "..\\n..")',
      '\t" aa',
      '\t" xx',
      '\techo matchstr(a, "a.x")',
      '\t" a',
      '\t" x',
      '',
      'Don\'t forget that "^" will only match at the first character of the String and',
      '"$" at the last character of the string.  They don\'t match after or before a',
      '"\\n".',
      '',
      ' vim:tw=78:ts=8:noet:ft=help:norl:',
    },
  },
  {
    path = 'runtime/lua/vim/_meta/options.lua',
    header = LUA_OPTION_META_HEADER,
    funcs = get_option_meta,
    render = render_option_meta,
  },
  {
    path = 'runtime/doc/options.txt',
    header = { '' },
    from = 'A jump table for the options with a short description can be found at |Q_op|.',
    footer = {
      ' vim:tw=78:ts=8:noet:ft=help:norl:',
    },
    funcs = get_option_meta,
    render = render_option_doc,
  },
  {
    path = 'runtime/lua/vim/_meta/vvars.lua',
    header = LUA_VVAR_META_HEADER,
    funcs = get_vvar_meta,
    render = render_vvar_meta,
  },
  {
    path = 'runtime/doc/vvars.txt',
    header = { '' },
    from = 'Type |gO| to see the table of contents.',
    footer = {
      ' vim:tw=78:ts=8:noet:ft=help:norl:',
    },
    funcs = get_vvar_meta,
    render = render_vvar_doc,
  },
}

--- @param elem nvim.gen_eval_files.elem
local function render(elem)
  print('Rendering ' .. elem.path)
  local from_lines = {} --- @type string[]
  local from = elem.from
  if from then
    for line in io.lines(elem.path) do
      from_lines[#from_lines + 1] = line
      if line:match(from) then
        break
      end
    end
  end

  local o = assert(io.open(elem.path, 'w'))

  --- @param l string
  local function write(l)
    local l1 = l:gsub('%s+$', '')
    o:write(l1)
    o:write('\n')
  end

  for _, l in ipairs(from_lines) do
    write(l)
  end

  for _, l in ipairs(elem.header or {}) do
    write(l)
  end

  local funcs = elem.funcs()

  --- @type string[]
  local fnames = vim.tbl_keys(funcs)
  table.sort(fnames)

  for _, f in ipairs(fnames) do
    elem.render(f, funcs[f], write)
  end

  for _, l in ipairs(elem.footer or {}) do
    write(l)
  end

  o:close()
end

local function main()
  for _, c in ipairs(CONFIG) do
    render(c)
  end
end

main()
