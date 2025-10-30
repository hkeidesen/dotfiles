return {
  "CopilotC-Nvim/CopilotChat.nvim",
  version = "3.*",
  event = "VeryLazy", 
  dependencies = {
    { "zbirenbaum/copilot.lua" },
    { "nvim-lua/plenary.nvim", branch = "master" },
  },
  build = "make tiktoken",
  opts = {
    model = 'gpt-4o',
    auto_follow_cursor = false,
    show_help = false,
    
    -- VS Code-like sidebar layout
    window = {
      layout = "vertical", -- VS Code sidebar style
      width = 0.4, -- 40% of screen width 
      height = 0.8,
      border = "rounded",
    },
    
    -- VS Code-like prompts
    prompts = {
      Explain = "Please explain how the following code works.",
      Review = "Please review the following code and provide suggestions for improvement.",
      Tests = "Please explain how the selected code works, then generate unit tests for it.",
      Refactor = "Please refactor the following code to improve its clarity and readability.",
      FixDiagnostic = "Please assist with the following diagnostic issue in file:",
      Commit = "Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit and add a short description of the change after the message.",
      CommitStaged = "Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit and add a short description of the change after the message.",
    },

    -- Auto-complete-like behavior
    auto_insert_mode = true,
    clear_chat_on_new_prompt = false,
    highlight_selection = true,
  },
  keys = {
    -- VS Code-like keybindings
    { "<C-s>", "<cmd>CopilotChatSave<cr>", desc = "Save chat", mode = {"n", "v"} },
    { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
    { "<leader>cx", "<cmd>CopilotChatReset<cr>", desc = "Reset Chat" },
    { "<leader>cq", function()
        local input = vim.fn.input("Quick Chat: ")
        if input ~= "" then
          require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
        end
      end, desc = "Quick Chat" },
    
    -- Code actions (like VS Code)
    { "<leader>ce", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code", mode = {"n", "v"} },
    { "<leader>ct", "<cmd>CopilotChatTests<cr>", desc = "Generate Tests", mode = {"n", "v"} },
    { "<leader>cr", "<cmd>CopilotChatReview<cr>", desc = "Review Code", mode = {"n", "v"} },
    { "<leader>cR", "<cmd>CopilotChatRefactor<cr>", desc = "Refactor Code", mode = {"n", "v"} },
    { "<leader>cd", "<cmd>CopilotChatFixDiagnostic<cr>", desc = "Fix Diagnostic", mode = {"n", "v"} },
    
    -- Git integration (like VS Code)
    { "<leader>cm", "<cmd>CopilotChatCommit<cr>", desc = "Generate Commit Message" },
    { "<leader>cM", "<cmd>CopilotChatCommitStaged<cr>", desc = "Generate Commit Message (Staged)" },
  },
  config = function(_, opts)
    require("CopilotChat").setup(opts)
    
    -- VS Code-like auto-commands
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-*",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
      end,
    })
  end,
}