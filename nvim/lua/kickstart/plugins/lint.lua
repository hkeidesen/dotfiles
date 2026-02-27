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
        go = { "golangcilint", "revive" },
      }

      lint.linters.revive = function()
        local builtin = require("lint.linters.revive")
        local conf = vim.fs.find({ "revive.toml", ".revive.toml" }, {
          path = vim.fn.expand("%:p:h"),
          upward = true,
        })[1]
        local args = { "-formatter", "json" }
        if conf then
          table.insert(args, "-config")
          table.insert(args, conf)
        end
        return vim.tbl_extend("force", builtin, {
          args = args,
          ignore_exitcode = true,
        })
      end

      lint.linters.golangcilint = vim.tbl_deep_extend("force", lint.linters.golangcilint or {}, {
        ignore_exitcode = true,
        args = {
          "run",
          "--out-format", "json",
          "--fast",
          "--concurrency", "1",
          "--timeout", "30s",
        },
      })

      -- Heavyweight linters that should only run on save.
      local save_only = { golangcilint = true }

      -- Debounce timer to prevent stacking golangci-lint on rapid saves.
      local debounce_timer = nil
      local debounce_ms = 2000

      local aug = vim.api.nvim_create_augroup("lint", { clear = true })

      -- All linters run on save (debounced for heavy linters).
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = aug,
        callback = function()
          local ft = vim.bo.filetype
          local names = lint.linters_by_ft[ft] or {}

          -- Run lightweight linters immediately.
          local light = {}
          local has_heavy = false
          for _, name in ipairs(names) do
            if save_only[name] then
              has_heavy = true
            else
              light[#light + 1] = name
            end
          end
          if #light > 0 then
            lint.try_lint(light)
          end

          -- Debounce heavy linters.
          if has_heavy then
            if debounce_timer then
              debounce_timer:stop()
              debounce_timer:close()
            end
            debounce_timer = vim.uv.new_timer()
            debounce_timer:start(debounce_ms, 0, vim.schedule_wrap(function()
              debounce_timer:close()
              debounce_timer = nil
              local heavy = {}
              for _, name in ipairs(names) do
                if save_only[name] then
                  heavy[#heavy + 1] = name
                end
              end
              lint.try_lint(heavy)
            end))
          end
        end,
      })

      -- Lightweight linters also run on InsertLeave / BufEnter.
      local function try_lint_lightweight()
        local ft = vim.bo.filetype
        local names = lint.linters_by_ft[ft] or {}
        local light = {}
        for _, name in ipairs(names) do
          if not save_only[name] then
            light[#light + 1] = name
          end
        end
        if #light > 0 then
          lint.try_lint(light)
        end
      end

      vim.api.nvim_create_autocmd("InsertLeave", {
        group = aug,
        callback = function()
          if vim.bo.buftype ~= "" then
            return
          end
          try_lint_lightweight()
        end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        group = aug,
        callback = function()
          if vim.bo.buftype ~= "" then
            return
          end
          if vim.fn.expand("%:p") ~= "" then
            try_lint_lightweight()
          end
        end,
      })
    end,
  },
}
