return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      animate = {
        enabled = true,
        duration = 300,
        easing = "easeOutExpo",
      },
      -- Enable GitHub integration
      picker = {
        enabled = true,
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      -- Explicitly load GitHub module
      _G.Snacks = require("snacks")
    end,
    keys = {
      -- GitHub integration keymaps (using <leader>g prefix)
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
    },
  },
}
