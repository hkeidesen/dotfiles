return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('lualine').setup {
      options = {
        theme = 'auto',
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },
      sections = {
        lualine_c = {
          {
            function()
              return vim.g.go_test_status or 'No Test Data'
            end,
            color = { fg = '#ff5555' },
          },
        },
      },
    }
  end,
}
