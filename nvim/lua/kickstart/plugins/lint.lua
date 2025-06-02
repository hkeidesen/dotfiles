return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      -- register ruff as the Python linter
      lint.linters.ruff = {
        exe = "ruff",
        args = { "--stdin-filename", vim.fn.expand("%:p"), "-" },
        stdin = true,
      }

      lint.linters_by_ft = {
        markdown = { "markdownlint" },
        python = { "ruff" },
      }

      local aug = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = aug,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
