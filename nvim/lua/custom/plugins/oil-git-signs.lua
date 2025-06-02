return {
  -- 1) Collect git status signs (only in oil buffers)
  {
    "FerretDetective/oil-git-signs.nvim",
    ft = "oil",
    opts = {
      keymaps = {
        ["g?"]         = "actions.show_help",
        ["<CR>"]       = "actions.select",
        ["<C-p>"]      = "actions.preview",
        ["q"]          = "actions.close",
        ["<backspace>"]= "actions.parent",
        ["_"]          = "actions.open_cwd",
        ["gs"]         = "actions.change_sort",
        ["H"]          = "actions.toggle_hidden",
        ["g\\"]        = "actions.toggle_trash",
      },
    },
  },

  -- 2) The Oil file explorer itself
  {
    "stevearc/oil.nvim",
    lazy = true,
    cmd  = { "Oil" },                    -- register :Oilep
    keys = {
      { "_", "<cmd>Oil<CR>", desc = "Open Oil" },
    },
    dependencies = {
      "FerretDetective/oil-git-signs.nvim",
      "lewis6991/gitsigns.nvim",
      { "echasnovski/mini.icons", opts = {} },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash       = true,
      columns               = { "icon", "gitsigns" },
      use_default_keymaps   = false,
      keymaps = {
        ["g?"]         = "actions.show_help",
        ["<CR>"]       = "actions.select",
        ["<C-p>"]      = "actions.preview",
        ["q"]          = "actions.close",
        ["<backspace>"]= "actions.parent",
        ["_"]          = "actions.open_cwd",
        ["gs"]         = "actions.change_sort",
        ["H"]          = "actions.toggle_hidden",
        ["g\\"]        = "actions.toggle_trash",
      },
      win_options = {
        signcolumn   = "yes:2",
        statuscolumn = "",
      },
      view_options = {
        show_hidden = true,

        -- color the filename based on the Git-signs jump list
        highlight_filename = function(entry)
          local ogs = require("oil-git-signs")
          -- ensure git-signs has run
          if not vim.b.oil_git_signs_exists then
            return
          end
          local jumps = vim.b.oil_git_signs_jump_list or {}
          local twochar = jumps[vim.v.lnum] or ""
          local idx_char = twochar:sub(1,1)
          for _, disp in pairs(ogs.defaults.index) do
            if disp.icon == idx_char then
              return disp.hl_group
            end
          end
        end,
      },
    },
  },

  -- 3) Lua-powered gutter signs elsewhere
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "+" },
        change       = { text = "~" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },
}
