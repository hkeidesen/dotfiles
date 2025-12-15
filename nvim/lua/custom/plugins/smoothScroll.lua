return {
  {
    "LuxVim/nvim-luxmotion",
    config = function()
      require("luxmotion").setup({
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
