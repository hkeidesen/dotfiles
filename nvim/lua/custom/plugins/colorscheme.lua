-- return {
--   {
--     'wnkz/monoglow.nvim',
--     lazy = false,
--     priority = 1000,
--     opts = {
--       on_colors = function(colors)
--         colors.glow = '#fd1b7c'
--       end,
--     },
--   },
-- }
--
-- return {
--   'timmypidashev/darkbox.nvim',
--   lazy = false,
--   config = function()
--     require('darkbox').load()
--   end,
-- }
return {
  'rose-pine/neovim',
  name = 'rose-pine',
  config = function()
    require('rose-pine').setup {
      -- Override the builtin palette per variant
      -- moon = {
      --     overlay = '#363738',
      -- },
      highlight_groups = {
        Comment = { fg = 'foam' },
        VertSplit = { fg = 'muted', bg = 'muted' },
      },
    }
    vim.cmd 'colorscheme rose-pine'
  end,
}
