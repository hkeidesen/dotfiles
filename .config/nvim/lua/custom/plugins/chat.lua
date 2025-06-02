-- ~/.config/nvim/lua/plugins/copilot_chat.lua
return {
  "CopilotC-Nvim/CopilotChat.nvim",
  version = "3.*", -- <-- make sure you’re on the Lua rewrite
  event = "VeryLazy",
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or "github/copilot.vim"
    { "nvim-lua/plenary.nvim", branch = "master" },
  },
  build = "make tiktoken", -- optional but nice for token counting
  opts = {
    -- ⬇️  THIS is the bit that flips it from a split to a floating panel
    window = {
      layout = "float", -- 'vertical', 'horizontal', 'float', 'replace'
      border = "rounded", -- feel free to pick 'single', 'double', …
      relative = "editor", -- or 'cursor' if you want it right by the caret
      width = 0.50, -- 50 % of the screen
      height = 0.60, -- 60 % of the screen
      row = 0.15, -- centre it a tad lower
      col = 0.25,
    },

    -- (all the other config lives here – prompts, models, mappings …)
  },
  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<CR>", desc = "  Copilot Chat" },
    { "<leader>ce", "<cmd>CopilotChatExplain<CR>", desc = "  Explain selection" },
  },
}
