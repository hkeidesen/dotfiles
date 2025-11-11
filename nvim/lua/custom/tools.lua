-- ~/.config/nvim/lua/custom/tools.lua
local M = {}

M.ui = {
  icons = {
    branch = "",
    bullet = "•",
    open_bullet = "○",
    ok = "✔",
    d_chev = "∨",
    ellipses = "…",
    node = "╼",
    document = "≡",
    lock = "",
    r_chev = ">",
    warning = " ",
    error = " ",
    info = "󰌶 ",
  },
  kind_icons = {
    Array = " 󰅪 ",
    BlockMappingPair = " 󰅩 ",
    Boolean = "  ",
    BreakStatement = " 󰙧 ",
    Call = " 󰃷 ",
    CaseStatement = " 󰨚 ",
    Class = "  ",
    Color = "  ",
    Constant = "  ",
    Constructor = " 󰆧 ",
    ContinueStatement = "  ",
    Copilot = "  ",
    Declaration = " 󰙠 ",
    Delete = " 󰩺 ",
    DoStatement = " 󰑖 ",
    Element = " 󰅩 ",
    Enum = "  ",
    EnumMember = "  ",
    Event = "  ",
    Field = "  ",
    File = "  ",
    Folder = "  ",
    ForStatement = "󰑖 ",
    Function = " 󰆧 ",
    GotoStatement = " 󰁔 ",
    Identifier = " 󰀫 ",
    IfStatement = " 󰇉 ",
    Interface = "  ",
    Keyword = "  ",
    List = " 󰅪 ",
    Log = " 󰦪 ",
    Lsp = "  ",
    Macro = " 󰁌 ",
    MarkdownH1 = " 󰉫 ",
    MarkdownH2 = " 󰉬 ",
    MarkdownH3 = " 󰉭 ",
    MarkdownH4 = " 󰉮 ",
    MarkdownH5 = " 󰉯 ",
    MarkdownH6 = " 󰉰 ",
    Method = " 󰆧 ",
    Module = " 󰅩 ",
    Namespace = " 󰅩 ",
    Null = " 󰢤 ",
    Number = " 󰎠 ",
    Object = " 󰅩 ",
    Operator = "  ",
    Package = " 󰆧 ",
    Pair = " 󰅪 ",
    Property = "  ",
    Reference = "  ",
    Regex = "  ",
    Repeat = " 󰑖 ",
    Return = " 󰌑 ",
    RuleSet = " 󰅩 ",
    Scope = " 󰅩 ",
    Section = " 󰅩 ",
    Snippet = "  ",
    Specifier = " 󰦪 ",
    Statement = " 󰅩 ",
    String = "  ",
    Struct = "  ",
    SwitchStatement = " 󰨙 ",
    Table = " 󰅩 ",
    Terminal = "  ",
    Text = " 󰀬 ",
    Type = "  ",
    TypeParameter = "  ",
    Unit = "  ",
    Value = "  ",
    Variable = "  ",
    WhileStatement = " 󰑖 ",
  },
}

-- + “spaced” kind icons like the source does
do
  local spaced = {}
  for k, v in pairs(M.ui.kind_icons) do
    spaced[k] = v .. " "
  end
  M.ui.kind_icons_spaced = spaced
end

M.nonprog_modes = { markdown = true, org = true, orgagenda = true, text = true }

-- highlight wrapper
function M.hl_str(group, s)
  return "%#" .. group .. "#" .. s .. "%*"
end

-- group digits: 12,345
function M.group_number(num, sep)
  sep = sep or ","
  if num < 999 then
    return tostring(num)
  end
  local s = tostring(num)
  return s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse():gsub("^,", "")
end

-- fs.root fallback for Neovim < 0.10
local function fs_root(path, markers)
  if vim.fs.root then
    return vim.fs.root(path, markers)
  end
  local dir = vim.fs.dirname(path)
  local found = vim.fs.find(markers, { upward = true, path = dir })[1]
  return found and vim.fs.dirname(found) or nil
end

-- project root (prefers .git)
function M.get_path_root(path)
  if path == "" then
    return nil
  end
  local root = vim.b.path_root
  if root then
    return root
  end
  root = fs_root(path, { ".git" })
  if root then
    vim.b.path_root = root
  end
  return root
end

-- LSP diagnostics availability
function M.diagnostics_available()
  local diagnostics = vim.lsp.protocol.Methods.textDocument_publishDiagnostics
  for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client:supports_method(diagnostics) then
      return true
    end
  end
  return false
end

-- (Optional) original git helpers — not needed if you use Gitsigns path,
-- but harmless to keep.
local branch_cache = setmetatable({}, { __mode = "k" })
local remote_cache = setmetatable({}, { __mode = "k" })

local function git_cmd(root, ...)
  local job = vim.system({ "git", "-C", root, ... }, { text = true }):wait()
  if job.code ~= 0 then
    return nil
  end
  return vim.trim(job.stdout)
end

function M.get_git_remote_name(root)
  if not root then
    return nil
  end
  if remote_cache[root] then
    return remote_cache[root]
  end
  local out = git_cmd(root, "config", "--get", "remote.origin.url")
  if not out then
    return nil
  end
  out = out:gsub(":", "/"):gsub("%.git$", ""):match("([^/]+/[^/]+)$")
  remote_cache[root] = out
  return out
end

function M.get_git_branch(root)
  if not root then
    return nil
  end
  if branch_cache[root] then
    return branch_cache[root]
  end
  local out = git_cmd(root, "rev-parse", "--abbrev-ref", "HEAD")
  if out == "HEAD" then
    local commit = git_cmd(root, "rev-parse", "--short", "HEAD")
    commit = M.hl_str("Comment", "(" .. commit .. ")")
    out = string.format("%s %s", out, commit)
  end
  branch_cache[root] = out
  return out
end

return M
