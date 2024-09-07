local LazyUtil = require('lazy.core.util')

---@class ergou.util: LazyUtilCore
---@field public buffer ergou.util.buffer
---@field public icons ergou.util.icons
---@field public inject ergou.util.inject
---@field public lazy ergou.util.lazy
---@field public lsp ergou.util.lsp
---@field public neotree ergou.util.neotree
---@field public root ergou.util.root
---@field public snips ergou.util.snips
---@field public ui ergou.util.ui
---@field public git ergou.util.git
---@field public cmp ergou.util.cmp
---@field public tsformat ergou.util.tsformat
---@field public pick ergou.util.pick
---@field public toggle ergou.util.toggle
local M = {}

setmetatable(M, {
  __index = function(t, k)
    if LazyUtil[k] then
      return LazyUtil[k]
    end
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require('ergou.util.' .. k)
    return t[k]
  end,
})
function M.is_win()
  return vim.uv.os_uname().sysname:find('Windows') ~= nil
end

---@param name string
function M.get_plugin(name)
  return require('lazy.core.config').spec.plugins[name]
end

---@param name string
---@param path string?
function M.get_plugin_path(name, path)
  local plugin = M.get_plugin(name)
  path = path and '/' .. path or ''
  return plugin and (plugin.dir .. path)
end

---@param plugin string
function M.has(plugin)
  return M.get_plugin(plugin) ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
  vim.api.nvim_create_autocmd('User', {
    pattern = 'VeryLazy',
    callback = function()
      fn()
    end,
  })
end

---@param name string
function M.opts(name)
  local plugin = require('lazy.core.config').spec.plugins[name]
  if not plugin then
    return {}
  end
  local Plugin = require('lazy.core.plugin')
  return Plugin.values(plugin, 'opts', false)
end

function M.deprecate(old, new)
  M.warn(('`%s` is deprecated. Please use `%s` instead'):format(old, new), {
    title = 'LazyVim',
    once = true,
    stacktrace = true,
    stacklevel = 6,
  })
end

-- delay notifications till vim.notify was replaced or after 500ms
function M.lazy_notify()
  local notifs = {}
  local function temp(...)
    table.insert(notifs, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.uv.new_timer()
  local check = assert(vim.uv.new_check())

  local replay = function()
    timer:stop()
    check:stop()
    if vim.notify == temp then
      vim.notify = orig -- put back the original notify if needed
    end
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(notifs) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- wait till vim.notify has been replaced
  check:start(function()
    if vim.notify ~= temp then
      replay()
    end
  end)
  -- or if it took more than 500ms, then something went wrong
  timer:start(500, 0, replay)
end

---@param name string
---@param fn fun(name:string)
function M.on_load(name, fn)
  local Config = require('lazy.core.config')
  if Config.plugins[name] and Config.plugins[name]._.loaded then
    fn(name)
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'LazyLoad',
      callback = function(event)
        if event.data == name then
          fn(name)
          return true
        end
      end,
    })
  end
end

--- @param table table
--- @param keys string[]
function M.table_walk(table, keys)
  local result = table
  for _, key in ipairs(keys) do
    if type(result) == 'table' then
      result = result[key]
    else
      return nil
    end
  end
  return result
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes('<c-G>u', true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == 'i' then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, 'n', false)
  end
end

M.sql_ft = { 'sql', 'mysql', 'plsql' }

return M