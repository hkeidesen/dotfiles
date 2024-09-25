vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

vim.opt.number = true
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

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode

-- Keep selection when indenting in visual mode
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
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

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
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup {
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = 'x' },  -- "_" can also be used based on your preference for visibility
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
        on_attach = function(bufnr)
  
          -- Actions
          vim.keymap.set('n', '<leader>gb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>', { desc = 'Blame line' })
          vim.keymap.set('n', '<leader>gB', '<cmd>lua require"gitsigns".toggle_current_line_blame()<CR>',{ desc = 'Toggle blame line' })
          vim.keymap.set('n', '<leader>gd', '<cmd>lua require"gitsigns".diffthis()<CR>', { desc = 'Diff against HEAD' })
        end
      }
    end
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.fn.sign_define("DiagnosticSignError",
      {text = " ", texthl = "DiagnosticSignError"})
      vim.fn.sign_define("DiagnosticSignWarn",
      {text = " ", texthl = "DiagnosticSignWarn"})
      vim.fn.sign_define("DiagnosticSignInfo",
      {text = " ", texthl = "DiagnosticSignInfo"})
      vim.fn.sign_define("DiagnosticSignHint",
      {text = "󰌵", texthl = "DiagnosticSignHint"})

      require("neo-tree").setup({
        enable_diagnostics = true, -- Ensure diagnostics are enabled
        default_component_configs = {
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "󰜌",
            -- Add icons for error and warning states
            error = "",
            warning = "",
          },
          diagnostics = {
            symbols = {
              hint = "󰌵",
              info = "",
              warn = "",
              error = "",
            },
            -- Highlight groups for different diagnostic levels
            highlights = {
              hint = "DiagnosticHint",
              info = "DiagnosticInfo",
              warn = "DiagnosticWarn",
              error = "DiagnosticError",
            },
          },
          name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
          },

          git_status = {
            symbols = {
              -- Change type
              added     = "✚", -- or "✚", but this is redundant info if you use git_status_colors on the name
              modified  = "", -- or "", but this is redundant info if you use git_status_colors on the name
              deleted   = "✖",-- this can only be used in the git_status source
              renamed   = "󰁕",-- this can only be used in the git_status source
              -- Status type
              untracked = "",
              ignored   = "",
              unstaged  = "󰄱",
              staged    = "",
              conflict  = "",
            }
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
              '.vscode'
            },
          },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          hijack_netrw_behavior = "open_default",
        },
        -- Additional Neotree configurations
      })
      -- Keybinding to toggle Neotree
      vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neotree" })
    end,
  },
  
  {
      'fedepujol/move.nvim',
      config = true,
      keys = {
        { '<A-j>', ':MoveLine(1)<CR>', mode = { 'n' }, noremap = true, silent = true, desc = 'Move line down' },
        { '<A-k>', ':MoveLine(-1)<CR>', mode = { 'n' }, noremap = true, silent = true, desc = 'Move line up' },
        { '<A-j>', ':MoveBlock(1)<CR>', mode = { 'v' }, noremap = true, silent = true, desc = 'Move block down' },
        { '<A-k>', ':MoveBlock(-1)<CR>', mode = { 'v' }, noremap = true, silent = true, desc = 'Move block up' },
      },
  },
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      panel = {
        enabled = false,  -- Disable the Copilot panel UI since nvim-cmp will handle suggestions
      },
      suggestion = {
        enabled = true,  -- Enable suggestions to work with nvim-cmp
        auto_trigger = true,
        -- keymap = {
        --   accept = "<Tab>",  -- Use Tab to accept the suggestion
        --   next = "<C-n>",    -- Use Ctrl-n to cycle through suggestions
        --   prev = "<C-p>",    -- Use Ctrl-p to go back to the previous suggestion
        --   dismiss = "<C-]>", -- Dismiss the suggestion with Ctrl-]
        -- },
      },
      filetypes = {
        markdown = true,
        gitrebase = true,
        yaml = true,
        ['grug-far'] = false,
      },
    },
    config = function(_, opts)
      require('copilot').setup(opts)
    end,
  },
  { 'AndreM222/copilot-lualine' },
  { -- Useful plugin to show you pending keybinds.
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
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function()
        return { 'treesitter', 'indent' }
      end,
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
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    'Shatur/neovim-session-manager',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local Path = require('plenary.path')
      local config = require('session_manager.config')
      local config_group = vim.api.nvim_create_augroup('MyConfigGroup', {}) -- A global group for all your config autocommand
  
      require('session_manager').setup({
        sessions_dir = Path:new(vim.fn.stdpath('data'), 'sessions'),
        autoload_mode = config.AutoloadMode.LastSession,
        autosave_last_session = true,
        autosave_ignore_not_normal = true,
        autosave_ignore_dirs = {},
        autosave_ignore_filetypes = { 'gitcommit', 'gitrebase' },
        autosave_ignore_buftypes = {},
        autosave_only_in_session = false,
        max_path_length = 80,
      })
      -- Auto save session
      vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
        callback = function ()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            -- Don't save while there's any 'nofile' buffer open.
            if vim.api.nvim_get_option_value("buftype", { buf = buf }) == 'nofile' then
              return
            end
          end
          session_manager.save_current_session()
        end
      })
      -- Auto load
      vim.api.nvim_create_autocmd({ 'User' }, {
        pattern = "SessionLoadPost",
        group = config_group,
        callback = function()
          require('neo-tree.command').execute { action = "focus" }
        end,
      })
      vim.keymap.set('n', '<leader>sml', '<cmd>SessionManager load_session<CR>', { desc = 'Load session' })
      vim.keymap.set('n', '<leader>sms', '<cmd>SessionManager save_current_session<CR>', { desc = 'Save session' })
      vim.keymap.set('n', '<leader>smd', '<cmd>SessionManager delete_session<CR>', { desc = 'Delete session' })
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    }
  },


  -- Colorscheme
  -- config = function ()
  --   require("catppuccin").setup({
  --     flavour = "frappe",
  --   })
  -- end
  -- },
  {
    "shaunsingh/nord.nvim",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "nord"
    end,
  },

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" }
      },
      { 
        "nvim-telescope/telescope-live-grep-args.nvim" ,
        -- This will not install any breaking changes.
        -- For major updates, this must be adjusted manually.
        version = "^1.0.0",
    },
   

    },
    config = function()
      local lga_actions = require("telescope-live-grep-args.actions")
      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                ["<C-space>"] = require('telescope.actions').to_fuzzy_refine,
              },
            },
          },
        
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'live_grep_args')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', "<leader>sG", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", { desc = '[S]earch by [G]rep with [A]rgs' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n','<leader>bb','<cmd>b#<CR>', { desc='Switch to the last buffer' })
      vim.keymap.set('n','<leader>bd','<cmd>:bd<CR>', { desc='Buffer delete' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })

     -- Harpoon + Telescope integration
     local harpoon = require('harpoon')
     harpoon:setup({})

     -- Harpoon keybindings
    vim.keymap.set("n", "<leader>ha", function() harpoon:list():add() end, { desc = "Add current file to Harpoon" })
    vim.keymap.set("n", "<leader>hd", function() harpoon:list():remove() end, { desc = "Remove current file from Harpoon" })
    vim.keymap.set("n", "<leader>hc", function() harpoon:list():clear() end, { desc = "Clear Harpoon" })

    vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end, { desc = "Select Harpoon list 1" })
    vim.keymap.set("n", "<C-t>", function() harpoon:list():select(2) end, { desc = "Select Harpoon list 2" })
    vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end, { desc = "Select Harpoon list 3" })
    vim.keymap.set("n", "<C-s>", function() harpoon:list():select(4) end, { desc = "Select Harpoon list 4" })

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Previous Harpoon list" })
    vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Next Harpoon list" })
     
     -- basic telescope configuration
     local conf = require("telescope.config").values
     local function toggle_telescope(harpoon_files)
         local file_paths = {}
         for _, item in ipairs(harpoon_files.items) do
             table.insert(file_paths, item.value)
         end
     
         require("telescope.pickers").new({}, {
             prompt_title = "Harpoon",
             finder = require("telescope.finders").new_table({
                 results = file_paths,
             }),
             previewer = conf.file_previewer({}),
             sorter = conf.generic_sorter({}),
         }):find()
     end
     
     vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
         { desc = "Open harpoon window" })
    end, 
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
      require('treesitter-context').setup({
        max_lines = 1, 
      })
    end
  },
  {
    'stevearc/oil.nvim',
    opts = {
      delete_to_trash = true,
      columns = {
        'icon',
        -- 'permissions',
        -- 'size',
        -- 'mtime',
      },
      use_default_keymaps = false,
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-p>'] = 'actions.preview',
        ['q'] = 'actions.close',
        ['<backspace>'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
        ['gs'] = 'actions.change_sort',
        ['H'] = 'actions.toggle_hidden',
        ['g\\'] = 'actions.toggle_trash',
      },
    },
    cmd = { 'Oil' },
    keys = {
      {
        '-',
        '<cmd>Oil<CR>',
        desc = 'Open Oil',
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true },
  {
    -- Main LSP Configuration
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Allows extra capabilities provided by nvim-cmp
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          -- Find references for the word under your cursor.
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          -- Rename the variable under your cursor.
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          -- Open the diagnostics list for the current buffer.
          map('<leader>cd', vim.diagnostic.open_float, '[C]ode [D]iagnostics', { 'n', 'x' })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

   
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
      
      local function find_python_path()
        -- Get the current working directory
        local cwd = vim.fn.getcwd()
      
        -- Define possible locations of the Python interpreter within the project
        local possible_paths = {
          cwd .. "/venv/bin/python",   -- if you use a venv directory for virtualenv
          cwd .. "/bin/python",        -- if virtualenv is directly under bin
          "/usr/bin/python3",          -- fallback to system Python
        }
      
        -- Check each path and return the first that exists
        for _, path in ipairs(possible_paths) do
          if vim.fn.filereadable(path) == 1 then
            return path
          end
        end
      
        -- Fallback if no valid path is found (optional, consider a more robust handling)
        return "/usr/bin/python3"
      end
      local servers = {


        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = 'Replace',
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      require('mason').setup()
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }


      local lspconfig = require('lspconfig')

      -- Vue
      local mason_registry = require('mason-registry')
      local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'


      -- Python
      lspconfig.ruff.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Disable document formatting for Ruff to avoid conflicts
          client.server_capabilities.document_formatting = false
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ timeout_ms = 1000, async = false })
            end
          })
        end,
        init_options = {
          settings = {
            logLevel = 'debug',
          }
        }
      })
      require('lspconfig').pyright.setup({
        settings = {
          pyright = {
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              ignore = { "*" },
            },
          },
        }
      })
      
      
      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            if server_name == "tsserver" then
              server_name = "ts_ls"
            end
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})

            if server_name == 'ts_ls' then
              lspconfig.ts_ls.setup {
                init_options = {
                  plugins = {
                    {
                      name = '@vue/typescript-plugin',
                      location = vue_language_server_path,  -- Use the Mason-managed path
                      languages = { 'vue' },
                    },
                  },
                },
                filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
              }
              return
            end
            -- Custom configuration for Volar (Vue Language Server)
            if server_name == 'volar' then
              lspconfig.volar.setup {}
              return
            end

            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },
  {
    -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
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
        lua = { 'stylua' },
        vue = { 'eslint_d', 'prettier' },
        python = { 'ruff_format' }
      },
      -- Preserve cursor position during format
      hooks = {
        before_format = function(bufnr)
          vim.b.saved_view = vim.fn.winsaveview() -- Save current cursor position
        end,
        after_format = function(bufnr)
          vim.fn.winrestview(vim.b.saved_view) -- Restore cursor position
        end,
      },
    },
  },
  { -- Autocompletion
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    {
      'L3MON4D3/LuaSnip',
      build = (function()
        if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
      },
    },
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',

    {
      'zbirenbaum/copilot-cmp',
      after = { 'copilot.lua' }, 
    },
    {
      'zbirenbaum/copilot.lua',
      cmd = 'Copilot',
      event = 'InsertEnter',
      opts = {
        panel = { enabled = true },
        suggestion = { enabled = true },
      },
    },
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    luasnip.config.setup {}

    cmp.setup {
    
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },

      -- For an understanding of why these mappings were chosen, you will need to read `:help ins-completion`
      mapping = cmp.mapping.preset.insert {
        -- Select the [n]ext item
        ['<C-n>'] = cmp.mapping.select_next_item(),
        -- Select the [p]revious item
        ['<C-p>'] = cmp.mapping.select_prev_item(),

        -- Scroll the documentation window [b]ack / [f]orward
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),

        -- Accept ([y]es) the completion. This will auto-import if your LSP supports it.
        ['<C-y>'] = cmp.mapping.confirm { select = true },

        -- Manually trigger a completion from nvim-cmp.
        ['<C-Space>'] = cmp.mapping.complete {},

        -- Use Tab and Shift-Tab for navigation and confirmation
        ['<Tab>'] = cmp.mapping(function(fallback)
          local has_copilot, copilot = pcall(require, 'copilot.suggestion')
          if has_copilot then
            if copilot.is_visible() then
              copilot.accept()
            end
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      },
      sources = {
        { name = 'copilot' },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
      },
    }
  end,
},

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require 'mini.statusline'
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  -- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  -- { import = 'custom.plugins' },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
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


-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
-- vim.cmd.colorscheme "catppuccin"
--Lua:
vim.cmd[[colorscheme nord]]
