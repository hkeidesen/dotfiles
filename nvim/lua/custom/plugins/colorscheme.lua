return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.o.background = "dark"
      vim.o.termguicolors = true
      vim.cmd("colorscheme rose-pine")

      -- Set darker black background
      vim.api.nvim_set_hl(0, "Normal", { bg = "#0a0a0a" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#0a0a0a" })
    end,
  },
}
--
-- return {
--   {
--     "wnkz/monoglow.nvim",
--     name = "monoglow",
--     config = function()
--       require("monoglow").setup({
--         on_colors = function(colors)
--           -- colors.glow = "#fd1b7c"
--           colors.glow = "#6a502a"
--         end,
--       })
--       vim.cmd("colorscheme monoglow")
--     end,
--   },
-- }
-- return {
--   {
--     "folke/tokyonight.nvim",
--     opts = {
--       transparent = true,
--       styles = {
--         sidebars = "transparent",
--         floats = "transparent",
--       },
--     },
--     config = function(_, opts)
--       require("tokyonight").setup(opts)
--       vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
--     end,
--   },
-- }
