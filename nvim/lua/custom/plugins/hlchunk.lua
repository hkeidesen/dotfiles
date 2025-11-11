return {
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("hlchunk").setup({
        chunk = {
          enable = true,
          chars = {
            vertical = "│",
          },

          style = {
            vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"),
          },
        },
        line_num = {
          enable = true,
          style = "#806d9c",
        },
      })
    end,
  },
}
