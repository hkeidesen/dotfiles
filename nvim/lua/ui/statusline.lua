-- lua/ui/statusline.lua
local M = {}

local api, fn, bo = vim.api, vim.fn, vim.bo
local get_opt = api.nvim_get_option_value

-- bring in the tiny tools module you made earlier
local tools = require("custom.tools")

-- icons
local ok_mini, mini_icons = pcall(require, "mini.icons")
if ok_mini then
  pcall(mini_icons.setup)
end

local icons = tools.ui.icons

-- ───────────────────────────────────────────────────────────
-- HL + ICON setup
-- ───────────────────────────────────────────────────────────

-- Define custom highlight groups for better visibility with transparent backgrounds
local function setup_statusline_highlights()
  -- Custom subtle but visible colors for statusline components
  vim.api.nvim_set_hl(0, "StatuslineBranch", { fg = "#7aa2f7", bold = true, bg = "NONE", force = true }) -- soft blue
  vim.api.nvim_set_hl(0, "StatuslineFile", { fg = "#c0caf5", bold = true, bg = "NONE", force = true }) -- soft white
  vim.api.nvim_set_hl(0, "StatuslineFileinfo", { fg = "#9ece6a", bold = true, bg = "NONE", force = true }) -- soft green
  vim.api.nvim_set_hl(0, "StatuslineModified", { fg = "#f7768e", bold = true, bg = "NONE", force = true }) -- soft red
  vim.api.nvim_set_hl(0, "StatuslineWarn", { fg = "#e0af68", bold = true, bg = "NONE", force = true }) -- soft yellow
  vim.api.nvim_set_hl(0, "StatuslineError", { fg = "#f7768e", bold = true, bg = "NONE", force = true }) -- soft red
  vim.api.nvim_set_hl(0, "StatuslineInfo", { fg = "#7dcfff", bold = true, bg = "NONE", force = true }) -- soft cyan
  vim.api.nvim_set_hl(0, "StatuslineComment", { fg = "#9aa5ce", bold = true, bg = "NONE", force = true }) -- soft gray
  vim.api.nvim_set_hl(0, "StatuslineScrollbar", { fg = "#bb9af7", bold = true, bg = "NONE", force = true }) -- soft purple
end

-- Set up highlights on load
setup_statusline_highlights()

-- Force refresh highlights after a short delay to ensure they take effect
vim.defer_fn(function()
  setup_statusline_highlights()
  vim.cmd("redrawstatus")
end, 100)

-- Add a command to manually refresh statusline highlights
vim.api.nvim_create_user_command("StatuslineRefresh", function()
  setup_statusline_highlights()
  vim.cmd("redrawstatus")
  print("Statusline highlights refreshed")
end, {})

-- Add a command to reload the entire Neovim configuration
vim.api.nvim_create_user_command("Reload", function()
  -- Clear all Lua modules from cache (more comprehensive approach)
  for name, _ in pairs(package.loaded) do
    if name:match("^custom") or name:match("^ui") or name:match("^kickstart") then
      package.loaded[name] = nil
    end
  end
  
  -- Clear any autocommands we might have created to avoid duplicates
  pcall(vim.api.nvim_del_augroup_by_name, "StatuslineGit")
  
  -- Re-source the init.lua file
  dofile(vim.fn.stdpath("config") .. "/init.lua")
  
  -- Force a full redraw
  vim.cmd("redraw!")
  
  print("Configuration reloaded!")
end, { desc = "Reload Neovim configuration" })

local HL = {
  branch = { "StatuslineBranch", icons.branch },
  file = { "StatuslineFile", icons.node },
  fileinfo = { "StatuslineFileinfo", icons.document },
  nomodifiable = { "StatuslineWarn", icons.bullet },
  modified = { "StatuslineModified", icons.bullet },
  readonly = { "StatuslineWarn", icons.lock },
  error = { "StatuslineError", icons.error },
  warn = { "StatuslineWarn", icons.warning },
  visual = { "StatuslineInfo", "‹› " },
}

local ICON = {}
for k, v in pairs(HL) do
  ICON[k] = tools.hl_str(v[1], v[2])
end

local ORDER = {
  "path",
  "venv",
  "gotest",
  "mod",
  "ro",
  "sep",
  "diag",
  "fileinfo",
  "scrollbar",
}

local PAD, SEP = " ", "%="
local SBAR = { "▔", "🮂", "🬂", "🮃", "▀", "▄", "▃", "🬭", "▂", "▁" }

-- ───────────────────────────────────────────────────────────
-- utils
-- ───────────────────────────────────────────────────────────
local function concat(parts)
  local out, i = {}, 1
  for _, k in ipairs(ORDER) do
    local v = parts[k]
    if v and v ~= "" then
      out[i] = v
      i = i + 1
    end
  end
  return " " .. table.concat(out, "  ") .. " "
end

local function esc_str(str)
  return str:gsub("([%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function stl_width(s)
  s = (s or ""):gsub("%%#.-#", ""):gsub("%%%*", ""):gsub("%%%%", "%%"):gsub("%%[%w%p]", "")
  return api.nvim_strwidth(s)
end

-- ───────────────────────────────────────────────────────────
-- git remote cache (async)
-- ───────────────────────────────────────────────────────────
local git_remote_cache, git_remote_pending = {}, {}
local function git_remote_cached(root)
  if not root then
    return nil
  end
  if git_remote_cache[root] ~= nil then
    return git_remote_cache[root] ~= "" and git_remote_cache[root] or nil
  end
  git_remote_cache[root] = ""
  if git_remote_pending[root] then
    return nil
  end
  git_remote_pending[root] = true
  vim.system({ "git", "-C", root, "remote" }, { text = true }, function(res)
    local name
    if res.code == 0 and res.stdout and res.stdout ~= "" then
      name = res.stdout:match("([^\n]+)") or "origin"
    end
    git_remote_cache[root] = name or "origin"
    git_remote_pending[root] = nil
    vim.schedule(function()
      vim.cmd("redrawstatus")
    end)
  end)
  return nil
end

-- ───────────────────────────────────────────────────────────
-- widgets
-- ───────────────────────────────────────────────────────────
local function file_icon_and_hl(file_name)
  if ok_mini then
    local icon, hl = mini_icons.get("file", file_name)
    return icon, hl
  end
  return icons.node, "StatuslineFile"
end

local function path_widget(root, fname)
  local file_name = fn.fnamemodify(fname, ":t")
  if fname == "" then
    file_name = "[No Name]"
  end
  local icon, hl = file_icon_and_hl(file_name)
  local path = tools.hl_str(hl, icon) .. file_name

  if bo.buftype == "help" then
    return ICON.file .. path
  end

  local dir_path = fn.fnamemodify(fname, ":h") .. "/"
  if dir_path == "./" then
    dir_path = ""
  end

  -- branch from gitsigns (no per-render git exec)
  local gs = vim.b.gitsigns_status_dict
  local branch = (gs and gs.head) or vim.b.gitsigns_head

  -- cached remote (async)
  local remote = git_remote_cached(root)

  local repo_info = ""
  if branch then
    if root then
      dir_path = dir_path:gsub("^" .. esc_str(root) .. "/", "")
    end
    if remote then
      repo_info = string.format("%s %s @ %s ", ICON.branch, remote, branch)
    else
      repo_info = string.format("%s %s ", ICON.branch, branch)
    end
  end

  local win_w = api.nvim_win_get_width(0)
  local need = stl_width(repo_info) + stl_width(path) + api.nvim_strwidth(dir_path)
  if win_w < need + 5 then
    dir_path = ""
  end
  if win_w < need - #dir_path then
    repo_info = ""
  end

  return repo_info .. ICON.file .. " " .. dir_path .. path
end

local function diagnostics_widget()
  if not tools.diagnostics_available() then
    return ""
  end

  local function count_for(sev)
    if type(vim.diagnostic.count) == "function" then
      local ok, t = pcall(vim.diagnostic.count, 0)
      if ok and type(t) == "table" then
        return t[sev] or 0
      end
    end
    return #vim.diagnostic.get(0, { severity = sev })
  end

  local err = string.format("%-3d", count_for(vim.diagnostic.severity.ERROR))
  local warn = string.format("%-3d", count_for(vim.diagnostic.severity.WARN))
  return string.format(
    "%s %s %s %s",
    ICON.error,
    tools.hl_str("StatuslineError", err),
    ICON.warn,
    tools.hl_str("StatuslineWarn", warn)
  )
end

local function fileinfo_widget()
  local ft = get_opt("filetype", {})
  local lines = tools.group_number(api.nvim_buf_line_count(0), ",")
  local str = ICON.fileinfo .. " "

  if not tools.nonprog_modes[ft] then
    return str .. string.format("%3s lines", lines)
  end

  local wc = fn.wordcount()
  if not wc.visual_words then
    return str .. string.format("%3s lines  %3s words", lines, tools.group_number(wc.words, ","))
  end

  local vlines = math.abs(fn.line(".") - fn.line("v")) + 1
  return str
    .. string.format(
      "%3s lines %3s words %3s chars",
      tools.group_number(vlines, ","),
      tools.group_number(wc.visual_words, ","),
      tools.group_number(wc.visual_chars, ",")
    )
end

local function venv_widget()
  if bo.filetype ~= "python" then
    return ""
  end
  local env = vim.env.VIRTUAL_ENV
  if env and env ~= "" then
    return tools.hl_str("StatuslineComment", string.format("[.venv: %s]", fn.fnamemodify(env, ":t")))
  end
  env = vim.env.CONDA_DEFAULT_ENV
  if env and env ~= "" then
    return tools.hl_str("StatuslineComment", string.format("[conda: %s]", env))
  end
  return ""
end

local function go_test_widget()
  if bo.filetype ~= "go" then
    return ""
  end

  local status = vim.g.go_test_status
  if status and status ~= "" then
    return status
  end

  return ""
end

local function scrollbar_widget()
  local cur = api.nvim_win_get_cursor(0)[1]
  local total = api.nvim_buf_line_count(0)
  local idx = math.floor((cur - 1) / math.max(total, 1) * #SBAR) + 1
  idx = math.min(math.max(idx, 1), #SBAR)
  return tools.hl_str("StatuslineScrollbar", SBAR[idx]:rep(2))
end

-- ───────────────────────────────────────────────────────────
-- render
-- ───────────────────────────────────────────────────────────
function M.render()
  local fname = api.nvim_buf_get_name(0)
  local root = (bo.buftype == "" and tools.get_path_root(fname)) or nil
  if bo.buftype ~= "" and bo.buftype ~= "help" then
    fname = bo.ft
  end

  local buf = api.nvim_win_get_buf(vim.g.statusline_winid)

  local parts = {
    path = path_widget(root, fname),
    venv = venv_widget(),
    gotest = go_test_widget(),
    mod = get_opt("modifiable", { buf = buf }) and (get_opt("modified", { buf = buf }) and ICON.modified or "")
      or ICON.nomodifiable,
    ro = get_opt("readonly", { buf = buf }) and ICON.readonly or "",
    sep = SEP,
    diag = diagnostics_widget(),
    fileinfo = fileinfo_widget(),
    scrollbar = scrollbar_widget(),
  }
  return concat(parts)
end

-- set it here (simple) — or do this from your plugin spec
vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.require('ui.statusline').render()"

-- keep it fresh + cheap
local aug = api.nvim_create_augroup("StatuslineGit", { clear = true })
api.nvim_create_autocmd("User", {
  group = aug,
  pattern = "GitsignsStatusUpdated",
  callback = function()
    vim.cmd("redrawstatus")
  end,
})
api.nvim_create_autocmd("DirChanged", {
  group = aug,
  callback = function()
    git_remote_cache = {}
  end,
})

-- Refresh highlights when colorscheme changes
api.nvim_create_autocmd("ColorScheme", {
  group = aug,
  callback = function()
    setup_statusline_highlights()
    vim.cmd("redrawstatus")
  end,
})

return M
