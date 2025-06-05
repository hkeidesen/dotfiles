return {
  "CopilotC-Nvim/CopilotChat.nvim",
  version = "3.*",
  event = "VeryLazy",

  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or "github/copilot.vim"
    { "nvim-lua/plenary.nvim", branch = "master" },
  },

  build = "make tiktoken",

  opts = {
    window = {
      layout = "float",
      border = "rounded",
      relative = "editor",
      width = 0.50,
      height = 0.60,
      row = 0.15,
      col = 0.25,
    },
  },

  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<CR>", desc = "  Copilot Chat" },
    { "<leader>ce", "<cmd>CopilotChatExplain<CR>", desc = "  Explain selection" },
  },
}
