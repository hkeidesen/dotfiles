return {
  "echasnovski/mini.nvim",
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("mini.icons").setup()
    require("mini.ai").setup({ n_lines = 500 })
    require("mini.surround").setup()
  end,
}
