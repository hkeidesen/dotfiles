return {
  {
    "tzachar/local-highlight.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    config = function()
      require("local-highlight").setup({
        disable_file_types = { "terminal" },
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
