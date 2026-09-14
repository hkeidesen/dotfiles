-- Zoom the current window into its own tab instead of Snacks.zen's floating
-- copy: a real window on the same buffer, so LSP/diagnostics/signcolumn work
-- exactly as normal, there's no cursor-sync-to-parent needed, and every other
-- window (including the Claude terminal split) is untouched -- no more
-- reaching into claudecode.nvim's terminal state at all.
local function toggle_zoom()
  if vim.t.zoomed then
    vim.cmd("tabclose")
  else
    vim.cmd("tab split")
    vim.t.zoomed = true
  end
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    dashboard = { enabled = false },
    input = { enabled = true },
    terminal = { enabled = true, win = { style = "terminal", position = "float", bo = { bufhidden = "hide" } } },
    words = { enabled = true },
    scratch = { enabled = true },
    lazygit = { enabled = true },
    gitbrowse = { enabled = true },
    bufdelete = { enabled = true },
    picker = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
  },
  keys = {
    { "<leader>tt", function() Snacks.terminal.toggle() end, mode = { "n", "t" }, desc = "Toggle Terminal" },
    { "<leader>lg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
    { "<leader>z", toggle_zoom, desc = "Zoom Window" },
    { "<leader>.", function() Snacks.scratch() end, desc = "Scratch Buffer" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "]w", function() Snacks.words.jump(1, true) end, desc = "Next Word Reference" },
    { "[w", function() Snacks.words.jump(-1, true) end, desc = "Prev Word Reference" },
  },
}
