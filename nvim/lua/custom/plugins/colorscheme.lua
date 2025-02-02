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
return {
  'timmypidashev/darkbox.nvim',
  lazy = false,
  config = function()
    require('darkbox').load()
  end,
}
