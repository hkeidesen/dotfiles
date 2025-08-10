return {
  -- oil.nvim configuration
  {
    "stevearc/oil.nvim",
    lazy = true,
    cmd = { "Oil" }, -- Lazy-load with the `:Oil` command
    keys = {
      { "_", "<cmd>Oil<CR>", desc = "Open Oil" }, -- Open oil explorer using the `_` key
    },
    opts = {
      default_file_explorer = true, -- Set as the default file explorer
      delete_to_trash = true, -- Move files to trash instead of permanent deletion
      columns = { "icon" }, -- Show only icons (no git status)
      use_default_keymaps = false, -- Disable default keymaps to avoid conflicts
      keymaps = {
        ["g?"] = "actions.show_help", -- Show help
        ["<CR>"] = "actions.select", -- Select file
        ["<C-p>"] = "actions.preview", -- Preview file
        ["q"] = "actions.close", -- Close buffer
        ["<backspace>"] = "actions.parent", -- Go to parent directory
        ["_"] = "actions.open_cwd", -- Open current working directory
        ["gs"] = "actions.change_sort", -- Change sort order
        ["H"] = "actions.toggle_hidden", -- Toggle hidden files
        ["g\\"] = "actions.toggle_trash", -- Toggle trash
      },
      win_options = {
        signcolumn = "yes:2", -- Enable two sign columns for Git status
        statuscolumn = "", -- Remove the status column for cleaner UI
      },
      view_options = {
        show_hidden = true, -- Show hidden files in the explorer
        highlight_filename = function(entry)
          -- Custom logic for filename highlight (optional)
        end,
      },
    },
  },

  -- oil-git-status.nvim configuration
  {
    "refractalize/oil-git-status.nvim",
    dependencies = {
      "stevearc/oil.nvim", -- Ensure oil.nvim is loaded first
    },
    config = function()
      require("oil-git-status").setup({
        show_ignored = true, -- Show files that match gitignore with !!
        symbols = { -- Customize the symbols that appear in the git status columns
          index = {
            ["!"] = "!", -- Ignored
            ["?"] = "?", -- Untracked
            ["A"] = "A", -- Added
            ["C"] = "C", -- Copied
            ["D"] = "D", -- Deleted
            ["M"] = "M", -- Modified
            ["R"] = "R", -- Renamed
            ["T"] = "T", -- Type Changed
            ["U"] = "U", -- Unmerged
            [" "] = " ", -- Unmodified
          },
          working_tree = {
            ["!"] = "!", -- Ignored
            ["?"] = "?", -- Untracked
            ["A"] = "A", -- Added
            ["C"] = "C", -- Copied
            ["D"] = "D", -- Deleted
            ["M"] = "M", -- Modified
            ["R"] = "R", -- Renamed
            ["T"] = "T", -- Type Changed
            ["U"] = "U", -- Unmerged
            [" "] = " ", -- Unmodified
          },
        },
      })
    end,
  },

  -- Optional: gitsigns.nvim for showing Git status in the gutter (works well with oil)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" }, -- Added lines
        change = { text = "~" }, -- Modified lines
        delete = { text = "_" }, -- Deleted lines
        topdelete = { text = "‾" }, -- Top delete (horizontally deleted lines)
        changedelete = { text = "~" }, -- Lines with change and delete
      },
    },
    config = function(_, opts)
      require("gitsigns").setup(opts) -- Initialize gitsigns with the configured options
    end,
  },
}
