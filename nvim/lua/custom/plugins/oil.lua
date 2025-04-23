return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    dependencies = {
      'FerretDetective/oil-git-signs.nvim',
      'lewis6991/gitsigns.nvim',
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      columns = {
        'icon',
        'gitsigns',
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
      view_options = {
        show_hidden = true,
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
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
    config = function(_, opts)
      require('gitsigns').setup(opts)
    end,
  },
}
