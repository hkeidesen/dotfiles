return {
  dir = vim.fn.stdpath("config"),
  name = "claude-review",
  config = function()
    require("claude-review").setup({})

    vim.keymap.set("n", "<leader>cr", function()
      require("claude-review").review_buffer()
    end, { desc = "[C]laude: [R]eview current file changes" })

    vim.keymap.set("n", "<leader>cD", function()
      require("claude-review").diagnose_buffer()
    end, { desc = "[C]laude: [D]iagnose full file" })

    vim.keymap.set("n", "<leader>cA", function()
      require("claude-review").toggle_auto()
    end, { desc = "[C]laude: toggle [A]uto diagnostics" })

    vim.keymap.set("n", "<leader>cc", function()
      require("claude-review").clear()
    end, { desc = "[C]laude: [C]lear diagnostics" })
  end,
}
