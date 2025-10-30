return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,

      -- Keep minimal columns for speed
      columns = {
        "icon",
      },

      buf_options = {
        buflisted = false,
        bufhidden = "hide",
      },

      win_options = {
        wrap = false,
        signcolumn = "yes:2", -- Required for oil-git-status (2 columns: index + working tree)
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
      },

      -- Performance: Disable file watching
      watch_for_changes = false,
      cleanup_delay_ms = 1000,

      lsp_file_methods = {
        -- This is likely the culprit! LSP operations can be slow
        enabled = false, -- Disable unless you need LSP-aware file operations
        timeout_ms = 500,
        autosave_changes = false,
      },

      constrain_cursor = "editable",
      use_default_keymaps = true,

      keymaps = {
        ["<C-h>"] = false, -- Disable if conflicts with tmux/window nav
        ["<C-l>"] = false, -- Disable if conflicts with tmux/window nav
        ["q"] = "actions.close",
        ["<C-c>"] = "actions.close",
      },

      view_options = {
        -- Start with hidden files visible (you had this enabled)
        show_hidden = true,

        is_hidden_file = function(name, bufnr)
          return vim.startswith(name, ".")
        end,

        -- CRITICAL: Skip heavy directories entirely
        is_always_hidden = function(name, bufnr)
          return name == ".."
            or name == ".git"
            or name == "node_modules"
            or name == ".next"
            or name == "dist"
            or name == "build"
            or name == "target"
            or name == "vendor"
            or name == ".venv"
            or name == "__pycache__"
        end,

        natural_order = "fast", -- Use fast mode for large directories
        case_insensitive = false,

        sort = {
          { "type", "asc" },
          { "name", "asc" },
        },
      },

      float = {
        padding = 2,
        max_width = 0.9,
        max_height = 0.9,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },

      preview_win = {
        update_on_cursor_moved = true,
        preview_method = "fast_scratch", -- Fastest preview method

        -- Skip preview for very large files
        disable_preview = function(filename)
          local max_filesize = 1024 * 1024 -- 1MB
          local ok, stats = pcall(vim.loop.fs_stat, filename)
          if ok and stats and stats.size > max_filesize then
            return true
          end
          return false
        end,

        win_options = {},
      },

      confirmation = {
        border = "rounded",
      },

      progress = {
        border = "rounded",
        minimized_border = "none",
      },
    },
  },

  {
    "refractalize/oil-git-status.nvim",
    dependencies = { "stevearc/oil.nvim" },
    lazy = false,
    config = function()
      require("oil-git-status").setup({
        -- Keep show_ignored false for better performance
        -- Set to true only if you need to see gitignored files
        show_ignored = false,

        -- Clean symbols (you can customize these)
        symbols = {
          index = {
            ["!"] = "◌",
            ["?"] = "?",
            ["A"] = "+",
            ["C"] = "C",
            ["D"] = "-",
            ["M"] = "~",
            ["R"] = "→",
            ["T"] = "T",
            ["U"] = "U",
            [" "] = " ",
          },
          working_tree = {
            ["!"] = "◌",
            ["?"] = "?",
            ["A"] = "+",
            ["C"] = "C",
            ["D"] = "-",
            ["M"] = "~",
            ["R"] = "→",
            ["T"] = "T",
            ["U"] = "U",
            [" "] = " ",
          },
        },
      })
    end,
  },
}
