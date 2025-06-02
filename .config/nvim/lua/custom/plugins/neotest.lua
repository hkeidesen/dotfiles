return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/nvim-nio",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-python",
  },
  config = function()
    local neotest = require("neotest")
    neotest.setup({
      adapters = {
        -- Vitest for your TS/JS
        require("neotest-vitest")({
          vitestCommand    = "npx vitest run --",
          vitestConfigFile = "vitest.config.ts",
        }),
        -- Python (pytest)
        require("neotest-python")({
          dap                       = { justMyCode = false },
          args                      = { "--log-level", "DEBUG" },
          runner                    = "pytest",
          python                    = ".venv/bin/python",
          pytest_discover_instances = true,
        }),
      },
    })
    local map = vim.keymap.set
    map("n", "<leader>tw", function()
      require("neotest.consumers.watch").start()
    end, { desc = " Watch tests for changes" })
    map("n", "<leader>ts", function()
      require("neotest.consumers.watch").stop()
    end, { desc = " Stop watching tests" })
    -- keymaps
    vim.keymap.set("n", "<leader>t", function() neotest.run.run() end,
      { desc = "Run nearest test", silent = true })
    vim.keymap.set("n", "<leader>o", function() neotest.output_panel.toggle() end,
      { desc = "Toggle test output", silent = true })
    vim.keymap.set("n", "<leader>T",
      function() neotest.run.run(vim.fn.expand("%")) end,
      { desc = "Run all tests in file", silent = true })
  end,
}
