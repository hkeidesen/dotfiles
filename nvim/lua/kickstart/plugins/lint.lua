return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      local parser = require("lint.parser")

      -- --- markdownlint-cli2 (custom linter) ---
      -- Requires: npm i -g markdownlint-cli2
      lint.linters["markdownlint-cli2"] = {
        cmd = "markdownlint-cli2",
        stdin = true,
        args = {
          "--stdin",
          "--stdin-filename",
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        },
        stream = "stdout",
        ignore_exitcode = true, -- markdownlint exits 1 when it finds issues
        parser = parser.from_pattern(
          -- Example line:
          -- README.md:31:22 MD009/no-trailing-spaces Trailing spaces [Expected: 0 or 2; Actual: 1]
          [[^[^:]+:(\d+):(\d+)\s+([A-Z0-9]+)(?:/\S+)?\s+(.+)$]],
          { "lnum", "col", "code", "message" },
          nil, -- keep default severity
          {
            source = "markdownlint",
            severity = vim.diagnostic.severity.WARN,
            -- lnum/col are already 1-based in output
          }
        ),
      }

      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
        python = { "ruff" },
        go = { "golangcilint" },
      }

      lint.linters.golangcilint = vim.tbl_deep_extend("force", lint.linters.golangcilint or {}, {
        ignore_exitcode = true,
      })

      local aug = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = aug,
        callback = function()
          lint.try_lint()
        end,
      })
      -- Optional: also lint when opening a buffer
      vim.api.nvim_create_autocmd("BufEnter", {
        group = aug,
        callback = function()
          -- Only lint real files (not help/quickfix/etc.)
          if vim.fn.expand("%:p") ~= "" then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
