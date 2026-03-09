return {
  {
    "LuxVim/whisk.nvim",
    config = function()
      require("whisk").setup({
        cursor = {
          duration = 250,
          easing = "ease-out",
          enabled = false,
        },
        scroll = {
          duration = 100,
          easing = "linear",
          enabled = true,
        },
        performance = { enabled = true },
        keymaps = {
          cursor = true,
          scroll = true,
        },
      })
    end,
  },
}
