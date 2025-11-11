return {
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        -- Navigation
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Next git [h]unk" })
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Previous git [h]unk" })
        -- Quick hunk actions
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "[H]unk [p]review" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "[H]unk [r]eset" })
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "[H]unk [s]tage" })
        -- Text object for hunks
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select git hunk" })
      end,
    },
  },

}
