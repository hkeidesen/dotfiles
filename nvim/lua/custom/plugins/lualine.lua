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
          'filename',
          {
            function()
              return vim.g.go_test_status ~= '' and vim.g.go_test_status or ''
            end,
            color = function()
              if vim.g.go_test_status and vim.g.go_test_status:match 'failed' then
                return { fg = '#ff5555' } -- Red for failures
              elseif vim.g.go_test_status and vim.g.go_test_status:match 'passed' then
                return { fg = '#55ff55' } -- Green for passed tests
              else
                return { fg = '#aaaaaa' } -- Gray for no data
              end
            end,
          },
        },
      },
    }

    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = '*.go',
      callback = function()
        vim.g.go_test_status = ''
        if package.loaded['lualine'] then
          require('lualine').refresh()
        end
      end,
    })
  end,
}
