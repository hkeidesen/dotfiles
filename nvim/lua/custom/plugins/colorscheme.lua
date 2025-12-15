-- return {
--   {
--     "rose-pine/neovim",
--     name = "rose-pine",
--     config = function()
--       vim.o.background = "dark"
--       vim.o.termguicolors = true
--
--       vim.cmd("colorscheme rose-pine")
--     end,
--   },
-- }
--
return {
  {
    "wnkz/monoglow.nvim",
    name = "monoglow",
    config = function()
      require("monoglow").setup({
        on_colors = function(colors)
          -- colors.glow = "#fd1b7c"
          colors.glow = "#6a502a"
        end,
      })
      vim.cmd("colorscheme monoglow")
    end,
  },
}
