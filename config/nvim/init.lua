vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.paste = false

vim.opt.showmode = false
vim.g.python3_host_prog = vim.fn.getcwd() .. "/.venv/bin/python"

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

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

vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    local qf = vim.fn.getqflist()
    if not qf or #qf == 0 then
      return
    end -- No need to update an empty qflist

    for i, item in ipairs(qf) do
      if item.bufnr and vim.api.nvim_buf_is_loaded(item.bufnr) then
        local lines = vim.api.nvim_buf_get_lines(item.bufnr, item.lnum - 1, item.lnum, false)
        if lines[1] then
          qf[i].text = lines[1] -- Update quickfix entry
        end
      end
    end
    vim.fn.setqflist(qf, "r") -- Replace quickfix list with updated results
  end,
})

local function yank_after_colon()
  local line = vim.fn.getline(".")
  local text = string.match(line, ":%s*([^,]+)")
  if text then
    vim.fn.setreg('"', text)
    print("Yanked: " .. text)
  else
    print("No match found")
  end
end

vim.keymap.set("n", "ya:", yank_after_colon, { desc = "Yank text after ':' until the first comma" })

local function select_after_colon()
  -- Get the current line number and text.
  local lnum = vim.fn.line(".")
  local line = vim.fn.getline(".")

  local colon_start, colon_end = string.find(line, ":%s*")
  if colon_start then
    local start_col = colon_end + 1
    local comma_start = string.find(line, ",", start_col)
    local end_col = comma_start and (comma_start - 1) or #line

    vim.fn.setpos("'<", { 0, lnum, start_col, 0 })
    vim.fn.setpos("'>", { 0, lnum, end_col, 0 })
    -- Reselect the visual area.
    vim.cmd("normal! gv")
  else
    print("No colon found on this line")
  end
end

-- Map the function to "va:" in normal mode.
vim.keymap.set("n", "va:", select_after_colon, { desc = "Visually select text after ':' until the first comma" })
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
  "tpope/vim-sleuth",
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "x" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        on_attach = function(bufnr)
          -- Actions
          vim.keymap.set(
            "n",
            "<leader>gb",
            '<cmd>lua require"gitsigns".blame_line{full=true}<CR>',
            { desc = "Blame line" }
          )
          vim.keymap.set(
            "n",
            "<leader>gB",
            '<cmd>lua require"gitsigns".toggle_current_line_blame()<CR>',
            { desc = "Toggle blame line" }
          )
          vim.keymap.set("n", "<leader>gd", '<cmd>lua require"gitsigns".diffthis()<CR>', { desc = "Diff against HEAD" })
        end,
      })
    end,
  },
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
      vim.o.foldlevelstart = 999
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
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {
      settings = {
        separate_diagnostic_server = false,
        publish_diagnostic_on = "insert_leave",
        tsserver_max_memory = "auto",
        expose_as_code_action = { "fix_all", "add_missing_imports" },
      },
    },
  },
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
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      {
        "sindrets/diffview.nvim",
        config = function()
          vim.keymap.set("n", "<leader>gd", function()
            toggle_diffview("DiffviewOpen")
          end, { desc = "Diff Index" })
          vim.keymap.set("n", "<leader>gD", function()
            toggle_diffview("DiffviewOpen master..HEAD")
          end, { desc = "Diff master" })
          vim.keymap.set("n", "<leader>gf", function()
            toggle_diffview("DiffviewFileHistory %")
          end, { desc = "Open diffs for current File" })
        end,
      },
      "nvim-telescope/telescope.nvim", -- optional
    },
    config = true,
  },
  {
    "numToStr/Comment.nvim",
    opts = {
      padding = true,
      extra = {
        ---Add comment on the line above
        above = "gcO",
        ---Add comment on the line below
        below = "gco",
        ---Add comment at the end of line
        eol = "gcA",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash",
        "c",
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

vim.cmd([[
  highlight DiffviewNormal guibg=#1e1e2e
  highlight DiffviewCursorLine guibg=#313244
]])
vim.cmd([[
  if &term =~# 'wezterm'
    " start undercurl (CSI 4:3 m), end undercurl (CSI 4:0 m)
    set t_Cs=\e[4:3m
    set t_Ce=\e[4:0m
  endif
]])
-- Squiggly line
vim.cmd([[highlight DiagnosticUnderlineError        gui=undercurl guisp=#FF0000]])
vim.cmd([[highlight DiagnosticUnderlineWarn         gui=undercurl guisp=#FFA500]])
vim.cmd([[highlight DiagnosticUnderlineUnnecessary gui=undercurl guisp=#FFA500]])
vim.cmd([[highlight DiagnosticUnderlineInfo         gui=undercurl guisp=#0000FF]])
vim.cmd([[highlight DiagnosticUnderlineHint         gui=undercurl guisp=#808080]])

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
  underline = true,
  update_in_insert = false,
}

vim.diagnostic.config(detailed_diagnostics)

local is_minimal = false
vim.keymap.set("n", "gK", function()
  is_minimal = not is_minimal
  vim.diagnostic.config(is_minimal and minimal_diagnostics or detailed_diagnostics)
  print(is_minimal and "Diagnostics: minimal view" or "Diagnostics: detailed view")
end, { desc = "Toggle diagnostic virtual_lines" })
