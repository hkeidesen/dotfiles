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
          -- show path relative to cwd
          { 'filename', path = 1 },
          {
            function()
              -- Only show Go test status for Go files
              if vim.bo.filetype ~= 'go' then
                return ''
              end
              return vim.g.go_test_status or '⌛ Running tests...'
            end,
            color = function()
              if vim.bo.filetype ~= 'go' then
                return {} -- No color for non-Go files
              end
              if vim.g.go_test_status and vim.g.go_test_status:match '🔥' then
                return { fg = '#ff5555' } -- Red for failed tests
              elseif vim.g.go_test_status and vim.g.go_test_status:match '✅' then
                return { fg = '#55ff55' } -- Green for passing tests
              elseif vim.g.go_test_status and vim.g.go_test_status:match '⠋' then
                return { fg = '#ffaa00' } -- Orange for running tests (spinner)
              else
                return { fg = '#aaaaaa' } -- Gray for unknown state
              end
            end,
          },
        },
      },
    }

    -- Reset test status when entering a Go file
    vim.api.nvim_create_autocmd('BufEnter', {
      pattern = '*.go',
      callback = function()
        vim.g.go_test_status = '⌛ Waiting for tests...'
        if package.loaded['lualine'] then
          require('lualine').refresh()
        end
      end,
    })
  end,
}
