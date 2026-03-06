return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.o.background = "dark"
      vim.o.termguicolors = true
      vim.cmd("colorscheme rose-pine")
    end,
  },
}
