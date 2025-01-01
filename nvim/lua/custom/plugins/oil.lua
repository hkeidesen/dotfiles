return {
  {
    'stevearc/oil.nvim',
    opts = {
      delete_to_trash = true,
      columns = {
        'icon',
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
}
