return {
  "echasnovski/mini.nvim",
  config = function()
    require("mini.icons").setup()
    
    require('mini.ai').setup {
      n_lines = 500,
      -- custom_textobjects = {
      --   -- Function selection
      --   f = require('mini.ai').gen_spec.treesitter {
      --     a = '@function.outer',
      --     i = '@function.inner',
      --   },
      --   -- Class selection
      --   c = require('mini.ai').gen_spec.treesitter {
      --     a = '@class.outer',
      --     i = '@class.inner',
      --   },
      -- },
    }
    require('mini.surround').setup()
    -- mini.statusline removed in favor of custom statusline
  end,
}
