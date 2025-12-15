return {
  {
    "tzachar/local-highlight.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("local-highlight").setup({
        animate = {
          enabled = true,
          easing = "linear",
          duration = {
            step = 10,
            total = 100,
          },
        },
      })

      -- Set the highlight after setup
      vim.api.nvim_set_hl(0, "LocalHighlight", {
        bold = true,
        fg = "#ffcc66",
      })
    end,
  },
}
