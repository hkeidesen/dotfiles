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
local HL = {
  branch = { "DiagnosticOk", icons.branch },
  file = { "NonText", icons.node },
  fileinfo = { "Function", icons.document },
  nomodifiable = { "DiagnosticWarn", icons.bullet },
  modified = { "DiagnosticError", icons.bullet },
  readonly = { "DiagnosticWarn", icons.lock },
  error = { "DiagnosticError", icons.error },
  warn = { "DiagnosticWarn", icons.warning },
  visual = { "DiagnosticInfo", "‹› " },
}

local ICON = {}
for k, v in pairs(HL) do
  ICON[k] = tools.hl_str(v[1], v[2])
end

local ORDER = {
  "pad",
  "path",
  "venv",
  "mod",
  "ro",
  "sep",
  "diag",
  "fileinfo",
  "pad",
  "scrollbar",
  "pad",
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
  return table.concat(out, " ")
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
  return icons.node, "NonText"
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

  return repo_info .. ICON.file .. " " .. dir_path .. path .. " "
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
    "%s %s  %s %s  ",
    ICON.error,
    tools.hl_str("DiagnosticError", err),
    ICON.warn,
    tools.hl_str("DiagnosticWarn", warn)
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
      "%3s lines %3s words  %3s chars",
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
    return tools.hl_str("Comment", string.format("[.venv: %s]  ", fn.fnamemodify(env, ":t")))
  end
  env = vim.env.CONDA_DEFAULT_ENV
  if env and env ~= "" then
    return tools.hl_str("Comment", string.format("[conda: %s]  ", env))
  end
  return tools.hl_str("Comment", "[no venv]")
end

local function scrollbar_widget()
  local cur = api.nvim_win_get_cursor(0)[1]
  local total = api.nvim_buf_line_count(0)
  local idx = math.floor((cur - 1) / math.max(total, 1) * #SBAR) + 1
  idx = math.min(math.max(idx, 1), #SBAR)
  return tools.hl_str("Substitute", SBAR[idx]:rep(2))
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
    pad = PAD,
    path = path_widget(root, fname),
    venv = venv_widget(),
    mod = get_opt("modifiable", { buf = buf }) and (get_opt("modified", { buf = buf }) and ICON.modified or " ")
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

return M
