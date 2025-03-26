return {
  {
    'echasnovski/mini.nvim',
    config = function()
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
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
