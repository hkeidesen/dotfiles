vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true
vim.o.exrc = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.paste = false

vim.opt.showmode = false
vim.g.python3_host_prog = vim.fn.getcwd() .. "/.venv/bin/python"

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Unified transparency handling for all gutter-related highlight groups.
-- We include sign column, line numbers, fold column, window separators, and diagnostic/git signs.
local function make_gutters_transparent()
  local function clear_bg(group)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group })
    if ok then
      hl.bg = "NONE"
      -- If the group is a link we need to break it by setting attributes explicitly.
      hl.link = nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end

  -- Explicit groups we always want transparent.
  local explicit = {
    "SignColumn",
    "LineNr",
    "CursorLineNr",
    "FoldColumn",
    "StatusColumn", -- if provided by plugins (statuscol etc.)
    "WinSeparator",
    "EndOfBuffer",
    "StatusLine",
    "StatusLineNC",
  }
  for _, g in ipairs(explicit) do
    clear_bg(g)
  end

  -- Iterate all highlight groups to catch dynamic ones (GitSigns*, DiagnosticSign*, Snacks*, etc.).
  local all = vim.fn.getcompletion("", "highlight")
  for _, g in ipairs(all) do
    if g:match("^GitSigns") or g:match("^DiagnosticSign") or g:match("^Snacks.*Sign") then
      clear_bg(g)
    end
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
  group = vim.api.nvim_create_augroup("transparent-gutters", { clear = true }),
  callback = function()
    make_gutters_transparent()
  end,
})

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes:2"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- reselects the text of the last edit
vim.keymap.set(
  "n",
  "gV",
  "`[v`]",
  { noremap = true, silent = true, desc = "Visually select the last changed or inserted text" }
)
vim.keymap.set(
  "x",
  "g/",
  "<Esc>/\\%V",
  { noremap = true, silent = true, desc = "Allows searching in visual selection" }
)

-- Cycle keymaps
vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>", { noremap = true, silent = true, desc = "Cycle next" })
vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>", { noremap = true, silent = true, desc = "Cycle previous" })

-- Put the current relative file path into clipboard
vim.keymap.set(
  "n",
  "<leader>y",
  "<cmd>:let @+ = expand('%')<CR>",
  { noremap = true, silent = true, desc = "Will put the path of the buffer to the clipboard" }
)

-- Open TODO in telescope
vim.keymap.set(
  "n",
  "<leader>td",
  "<cmd>TodoTelescope<CR>",
  { noremap = true, silent = true, desc = "Open TODOs in telescope" }
)

-- Open TODOs in QuickFix list
vim.keymap.set(
  "n",
  "<leader>tq",
  "<cmd>TodoQuickFix<CR>",
  { noremap = true, silent = true, desc = "Open all TODS in the project in the quickfix list" }
)

vim.keymap.set("n", "<leader>tn", function()
  -- Toggle line numbers
  vim.wo.number = not vim.wo.number
  vim.wo.relativenumber = not vim.wo.relativenumber

  -- Toggle indentation guides (if `ibl` is loaded)
  local ok, ibl = pcall(require, "ibl")
  if ok then
    local current_enabled = ibl.config.indent.char ~= ""
    ibl.setup({ indent = { char = current_enabled and "" or "▏" } })
  end
end, { desc = "Toggle number/relativenumber and indent guides" })

-- Center screen on C-d and C-u
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-f>", "<C-d>zz")
vim.keymap.set("n", "<C-b>", "<C-d>zz")

--Close all buffers but keep current
vim.keymap.set(
  "n",
  "<leader>o",
  ":%bd|e#",
  { noremap = true, silent = true, desc = "Close all buffers but keep current" }
)

-- Buffer management
vim.keymap.set("n", "<leader>bb", "<cmd>b#<CR>", { desc = "Previous buffer" })

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })

--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- action on entire buffer
vim.keymap.set("n", "dae", "ggVGd", { noremap = true, silent = true, desc = "Delete entire file" })
vim.keymap.set("n", "yae", "ggVGy", { noremap = true, silent = true, desc = "Yank entire file" })
vim.keymap.set("n", "cae", 'ggVG"_c', { noremap = true, silent = true, desc = "Change entire file" })
vim.keymap.set("n", "vae", "ggVG", { noremap = true, silent = true, desc = "Select entire file" })

-- Diagnostic keymaps
vim.keymap.set("n", "<C-q>", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Opening new terminals
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("custom-term-open", { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

local job_id = 0
local function create_small_terminal()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 10)
  job_id = vim.bo.channel
end

vim.keymap.set("n", "<space>st", function()
  create_small_terminal()
end, { desc = "Crete a new small terminal" })

vim.keymap.set("n", "<leader>test", function()
  if job_id == 0 then
    create_small_terminal()
  end
  vim.fn.chansend(job_id, { "echo 'run tests!'\r\n" })
end, { desc = "Find and run tests in current directory" })

vim.keymap.set("t", "<esc><esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<C-w><", ":vertical resize -10<CR>", { silent = true })
vim.keymap.set("n", "<C-w>>", ":vertical resize +10<CR>", { silent = true })
vim.keymap.set("n", "<C-w>-", ":resize -5<CR>", { silent = true })
vim.keymap.set("n", "<C-w>+", ":resize +5<CR>", { silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local client = vim.lsp.get_clients({ bufnr = 0 })[1]
    if not client then
      return
    end

    local params = vim.lsp.util.make_range_params(nil, client.offset_encoding)
    params.context = { only = { "source.organizeImports" } }

    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)

    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end

    vim.lsp.buf.format({ async = false })
  end,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

local function toggle_diffview(cmd)
  if next(require("diffview.lib").views) == nil then
    vim.cmd(cmd)
  else
    vim.cmd("DiffviewClose")
  end
end

require("lazy").setup({
  { import = "custom/plugins" },
  { import = "kickstart/plugins" },
  "tpope/vim-sleuth",
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = "<Up> ",
          Down = "<Down> ",
          Left = "<Left> ",
          Right = "<Right> ",
          C = "<C-…> ",
          M = "<M-…> ",
          D = "<D-…> ",
          S = "<S-…> ",
          CR = "<CR> ",
          Esc = "<Esc> ",
          ScrollWheelDown = "<ScrollWheelDown> ",
          ScrollWheelUp = "<ScrollWheelUp> ",
          NL = "<NL> ",
          BS = "<BS> ",
          Space = "<Space> ",
          Tab = "<Tab> ",
          F1 = "<F1>",
          F2 = "<F2>",
          F3 = "<F3>",
          F4 = "<F4>",
          F5 = "<F5>",
          F6 = "<F6>",
          F7 = "<F7>",
          F8 = "<F8>",
          F9 = "<F9>",
          F10 = "<F10>",
          F11 = "<F11>",
          F12 = "<F12>",
        },
      },

      -- Document existing key chains
      spec = {
        { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
        { "<leader>d", group = "[D]ocument" },
        { "<leader>r", group = "[R]ename" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
        { "<leader>t", group = "[T]oggle" },
        { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
      },
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
      preview = {
        win_config = {
          border = { "", "", "", "", "", "", "", "" }, -- No border
          winblend = 10, -- Transparency
          maxheight = 20, -- Maximum height of the preview window
          maxwidth = 80, -- Maximum width of the preview window
        },
        mappings = {
          scrollU = "<C-u>", -- Scroll up in the preview
          scrollD = "<C-d>", -- Scroll down in the preview
        },
      },
    },
  },
  {
    "declancm/maximize.nvim",
    opts = {},
    keys = {
      {
        "<leader>z",
        function()
          require("maximize").toggle()
        end,
        mode = { "n" },
        desc = "Maximize current window",
      },
    },
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup({
        max_lines = 2,
      })
    end,
  },
  { "Bilal2453/luvit-meta", lazy = true },
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = { -- set to setup table
    },
  },
  { "wakatime/vim-wakatime", lazy = false },

  {
    "folke/todo-comments.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash",
        "diff",
        "go",
        "html",
        "json",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "scss",
        "typescript",
        "vim",
        "vimdoc",
        "vue",
      },
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {

            -- select functions
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",

            -- select classes
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter" },
  },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})

local minimal_diagnostics = {
  virtual_text = {
    current_line = true,
    source = true,
  },
  virtual_lines = false,
  underline = true,
  update_in_insert = false,
}

local detailed_diagnostics = {
  virtual_text = {
    current_line = true,
    source = "if_many",
    severity = {
      max = vim.diagnostic.severity.WARN,
    },
  },
  virtual_lines = {
    current_line = true,
    severity = {
      min = vim.diagnostic.severity.ERROR,
    },
  },
  underline = {
    severity = {
      min = vim.diagnostic.severity.HINT,
    },
  },
  update_in_insert = false,
}

vim.diagnostic.config(detailed_diagnostics)

local is_minimal = false
vim.keymap.set("n", "gK", function()
  is_minimal = not is_minimal
  vim.diagnostic.config(is_minimal and minimal_diagnostics or detailed_diagnostics)
  print(is_minimal and "Diagnostics: minimal view" or "Diagnostics: detailed view")
end, { desc = "Toggle diagnostic virtual_lines" })

require("ui.statusline")
require("ui.glanceClaudePlan")
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.cmd([[
      highlight StatusLine guibg=NONE ctermbg=NONE
      highlight StatusLineNC guibg=NONE ctermbg=NONE
      highlight DiagnosticUnderlineError guisp=#994444 gui=undercurl cterm=underline
      highlight DiagnosticUnderlineWarn guisp=Orange gui=undercurl cterm=underline
      highlight DiagnosticUnderlineInfo guisp=Blue gui=undercurl cterm=underline
      highlight DiagnosticUnderlineHint guisp=Grey gui=undercurl cterm=underline
      highlight DiagnosticUnnecessary guisp=#994444 gui=undercurl cterm=underline
    ]])
  end,
})

vim.cmd([[
  highlight DiagnosticUnderlineError guisp=#994444 gui=undercurl cterm=underline
  highlight DiagnosticUnderlineWarn guisp=Orange gui=undercurl cterm=underline
  highlight DiagnosticUnderlineInfo guisp=Blue gui=undercurl cterm=underline
  highlight DiagnosticUnderlineHint guisp=Grey gui=undercurl cterm=underline
  highlight DiagnosticUnnecessary guisp=#994444 gui=undercurl cterm=underline
]])

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.INFO] = "󰋽",
      [vim.diagnostic.severity.HINT] = "󰌶",
    },
  },
})

vim.api.nvim_set_hl(0, "DiagnosticSignError", { fg = "#eb6f92", bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { fg = "#f6c177", bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { fg = "#9ccfd8", bg = "NONE" })
vim.api.nvim_set_hl(0, "DiagnosticSignHint", { fg = "#c4a7e7", bg = "NONE" })

-- Claude review: configure per-project instructions, then set up keymaps
require("claude-review").setup({})

-- Claude review: sends git diff to Claude CLI, shows feedback as diagnostics
vim.keymap.set("n", "<leader>cr", function()
  require("claude-review").review_buffer()
end, { desc = "[C]laude: [R]eview current file changes" })

vim.keymap.set("n", "<leader>cD", function()
  require("claude-review").diagnose_buffer()
end, { desc = "[C]laude: [D]iagnose full file" })

vim.keymap.set("n", "<leader>cA", function()
  require("claude-review").toggle_auto()
end, { desc = "[C]laude: toggle [A]uto diagnostics" })

vim.keymap.set("n", "<leader>cc", function()
  require("claude-review").clear()
end, { desc = "[C]laude: [C]lear diagnostics" })
