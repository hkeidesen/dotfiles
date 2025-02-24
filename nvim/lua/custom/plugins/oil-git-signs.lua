return {
  {
    -- I recommend not installing this a dependency of oil as it isn't required
    -- until you open an oil buffer
    'FerretDetective/oil-git-signs.nvim',
    ft = 'oil',
    opts = {},
  },
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      win_options = {
        signcolumn = 'yes:2',
        statuscolumn = '',
      },
    },
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
}
