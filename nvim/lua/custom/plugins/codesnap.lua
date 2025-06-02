return {
  {
    'mistricky/codesnap.nvim',
    build = 'make',
    keys = {
      { '<leader>cc', '<cmd>CodeSnapHighlight<cr>', mode = 'x', desc = 'Save selected code snapshot into clipboard' },
      { '<leader>cs', '<cmd>CodeSnapSaveHighlight<cr>', mode = 'x', desc = 'Save selected code snapshot in ~/Desktop' },
    },
    opts = {
      save_path = '~/Desktop',
      has_breadcrumbs = true,
      bg_theme = 'sea',
      watermark = '',
    },
  },
}
