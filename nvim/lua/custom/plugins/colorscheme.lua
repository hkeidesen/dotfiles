return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      -- UI options
      vim.o.background = "dark"
      vim.o.termguicolors = true

      -- activate colorscheme
      vim.cmd("colorscheme rose-pine")
    end,
  },
}
