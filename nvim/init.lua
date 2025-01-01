vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'

vim.opt.showmode = false

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

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
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Cycle keymaps
vim.keymap.set('n', '<leader>cn', '<cmd>cnext<CR>', { noremap = true, silent = true, desc = 'Cycle next' })
vim.keymap.set('n', '<leader>cp', '<cmd>cprev<CR>', { noremap = true, silent = true, desc = 'Cycle previous' })

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
vim.keymap.set('v', '<', '<gv', { noremap = true, silent = true })
vim.keymap.set('v', '>', '>gv', { noremap = true, silent = true })

--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- action on entire buffer
vim.keymap.set('n', 'dae', 'ggVGd', { noremap = true, silent = true, desc = 'Delete entire file' })
vim.keymap.set('n', 'yae', 'ggVGy', { noremap = true, silent = true, desc = 'Yank entire file' })
vim.keymap.set('n', 'cae', 'ggVG"_c', { noremap = true, silent = true, desc = 'Change entire file' })
vim.keymap.set('n', 'vae', 'ggVG', { noremap = true, silent = true, desc = 'Select entire file' })

-- Diagnostic keymaps
vim.keymap.set('n', '<C-q>', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Opening new terminals
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

local job_id = 0
local function create_small_terminal()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 10)
  job_id = vim.bo.channel
end

vim.keymap.set('n', '<space>st', function()
  create_small_terminal()
end, { desc = 'Crete a new small terminal' })

vim.keymap.set('n', '<leader>test', function()
  if job_id == 0 then
    create_small_terminal()
  end
  vim.fn.chansend(job_id, { "echo 'run tests!'\r\n" })
end, { desc = 'Find and run tests in current directory' })

vim.keymap.set('t', '<esc><esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { import = 'custom/plugins' },
  'tpope/vim-sleuth',
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup {
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = 'x' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
          -- Actions
          vim.keymap.set('n', '<leader>gb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>', { desc = 'Blame line' })
          vim.keymap.set('n', '<leader>gB', '<cmd>lua require"gitsigns".toggle_current_line_blame()<CR>', { desc = 'Toggle blame line' })
          vim.keymap.set('n', '<leader>gd', '<cmd>lua require"gitsigns".diffthis()<CR>', { desc = 'Diff against HEAD' })
        end,
      }
    end,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      vim.fn.sign_define('DiagnosticSignError', { text = ' ', texthl = 'DiagnosticSignError' })
      vim.fn.sign_define('DiagnosticSignWarn', { text = ' ', texthl = 'DiagnosticSignWarn' })
      vim.fn.sign_define('DiagnosticSignInfo', { text = ' ', texthl = 'DiagnosticSignInfo' })
      vim.fn.sign_define('DiagnosticSignHint', { text = '󰌵', texthl = 'DiagnosticSignHint' })

      require('neo-tree').setup {
        enable_diagnostics = true,
        default_component_configs = {
          icon = {
            folder_closed = '',
            folder_open = '',
            folder_empty = '󰜌',
            error = '',
            warning = '',
          },
          diagnostics = {
            symbols = {
              hint = '󰌵',
              info = '',
              warn = '',
              error = '',
            },
            -- Highlight groups for different diagnostic levels
            highlights = {
              hint = 'DiagnosticHint',
              info = 'DiagnosticInfo',
              warn = 'DiagnosticWarn',
              error = 'DiagnosticError',
            },
          },
          name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = 'NeoTreeFileName',
          },

          git_status = {
            symbols = {
              added = '✚', -- or "✚", but this is redundant info if you use git_status_colors on the name
              modified = '', -- or "", but this is redundant info if you use git_status_colors on the name
              deleted = '✖', -- this can only be used in the git_status source
              renamed = '󰁕', -- this can only be used in the git_status source
              -- Status type
              untracked = '',
              ignored = '',
              unstaged = '󰄱',
              staged = '',
              conflict = '',
            },
          },
        },
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = true,
            hide_gitignored = false,
            never_show_by_pattern = {
              '.git',
              '.DS_Store',
              'thumbs.db',
              'desktop.ini',
              '__pycache__',
              '.vscode',
            },
          },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          hijack_netrw_behavior = 'open_default',
        },
      }
      vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'Toggle Neotree' })
    end,
  },
  {
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default whick-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      -- Document existing key chains
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    init = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 999
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function()
        return { 'treesitter', 'indent' }
      end,
      preview = {
        win_config = {
          border = { '', '', '', '', '', '', '', '' }, -- No border
          winblend = 10, -- Transparency
          maxheight = 20, -- Maximum height of the preview window
          maxwidth = 80, -- Maximum width of the preview window
        },
        mappings = {
          scrollU = '<C-u>', -- Scroll up in the preview
          scrollD = '<C-d>', -- Scroll down in the preview
        },
      },
    },
  },
  {
    'declancm/maximize.nvim',
    opts = {},
    keys = {
      {
        '<leader>z',
        function()
          require('maximize').toggle()
        end,
        mode = { 'n' },
        desc = 'Maximize current window',
      },
    },
  },
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy', -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    config = function()
      require('tiny-inline-diagnostic').setup {
        preset = 'classic',
        options = {
          show_source = true,
          throttle = 0,
          multiple_diag_under_cursor = true,
          -- use_icons_from_diagnostic = true,
        },
      }
    end,
  },
  {
    'wnkz/monoglow.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },

  -- LSP Plugins
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    config = function()
      require('treesitter-context').setup {
        max_lines = 2,
      }
    end,
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      settings = {
        separate_diagnostic_server = false,
        publish_diagnostic_on = 'insert_leave',
        tsserver_max_memory = 'auto',
        expose_as_code_action = { 'fix_all', 'add_missing_imports' },
      },
    },
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        javascript = { 'eslint_d', 'prettier' },
        json = { 'prettier' },
        lua = { 'stylua' },
        python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
        scss = { 'prettier' },
        typescript = { 'eslint_d', 'prettier' },
        vue = { 'eslint_d', 'prettier' },
        go = { 'gofmt', 'goimports' },
      },
      hooks = {
        before_format = function(bufnr)
          vim.b.saved_view = vim.fn.winsaveview()
        end,
        after_format = function(bufnr)
          vim.fn.winrestview(vim.b.saved_view)
        end,
      },
    },
  },
  {
    'NvChad/nvim-colorizer.lua',
    event = 'BufReadPre',
    opts = { -- set to setup table
    },
  },
  {
    'mfussenegger/nvim-lint',
    config = function()
      -- Configuration for nvim-lint
      require('lint').linters_by_ft = {
        javascript = { 'eslint_d' },
        typescript = { 'eslint_d' },
        vue = { 'eslint_d' },
      }

      -- Automatically lint when files are saved
      vim.cmd [[
      autocmd BufWritePost <buffer> lua require('lint').try_lint()
    ]]
    end,
  },
  { 'wakatime/vim-wakatime', lazy = false },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = true } },
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration

      -- Only one of these is needed.
      'nvim-telescope/telescope.nvim', -- optional
      'ibhagwan/fzf-lua', -- optional
      'echasnovski/mini.pick', -- optional
    },
    config = true,
  },
  {
    'numToStr/Comment.nvim',
    opts = {
      padding = true,
      extra = {
        ---Add comment on the line above
        above = 'gcO',
        ---Add comment on the line below
        below = 'gco',
        ---Add comment at the end of line
        eol = 'gcA',
      },
    },
  },
  {
    'gbprod/substitute.nvim',
    opts = {},
  },
  -- {
  --   'echasnovski/mini.nvim',
  --   config = function()
  --     require('mini.ai').setup { n_lines = 500 }
  --     require('mini.surround').setup()
  --     local statusline = require 'mini.statusline'
  --     statusline.setup { use_icons = vim.g.have_nerd_font }
  --     ---@diagnostic disable-next-line: duplicate-set-field
  --     statusline.section_location = function()
  --       return '%2l:%-2v'
  --     end
  --   end,
  -- },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'json' },
      auto_install = true,
      highlight = {
        enable = true,
      },
    },
  },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.cmd [[colorscheme monoglow-lack]]

vim.cmd [[
  highlight Normal guibg=#000000 guifg=#ffffff
  highlight NonText guibg=#000000 guifg=#505050
]]

vim.o.termguicolors = true
vim.o.background = 'dark'
--
-- Squiggly line
vim.cmd [[highlight DiagnosticUnderlineError gui=undercurl guisp=#FF0000]]

-- Orange, wavy underline for warnings and unnecessary
vim.cmd [[highlight DiagnosticUnderlineWarn gui=undercurl guisp=#FFA500]]
vim.cmd [[ highlight DiagnosticUnnecessary gui=undercurl guisp=#FFA500]]

-- Blue, wavy underline for information
vim.cmd [[highlight DiagnosticUnderlineInfo gui=undercurl guisp=#0000FF]]

-- Gray, wavy underline for hints
vim.cmd [[highlight DiagnosticUnderlineHint gui=undercurl guisp=#808080]]

-- tiny-inline-diagnostic
vim.diagnostic.config {
  severity_sort = false,
  signs = true,
  underline = {
    severity = {
      min = vim.diagnostic.severity.HINT,
    },
  },
  update_in_insert = false,
  virtual_text = false,
}
