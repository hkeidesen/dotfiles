return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown" },
    opts = {
      -- Render markdown inside LSP hover floats (the `K` popup) and
      -- diagnostic floats too. Without these, the plugin only activates in
      -- real .md buffers.
      file_types = { "markdown", "vimwiki" },
      completions = { lsp = { enabled = true } },
      win_options = {
        -- LSP markdown floats are nominally `markdown` filetype, but the
        -- plugin gates on it explicitly.
        conceallevel = { default = vim.o.conceallevel, rendered = 2 },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      require("render-markdown").enable()
    end,
  },
}
