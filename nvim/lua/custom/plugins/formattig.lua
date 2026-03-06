local function eslint_fix(bufnr)
  local client = vim.lsp.get_clients({ name = "eslint", bufnr = bufnr })[1]
  if not client then return end
  client:request("textDocument/codeAction", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = { start = { line = 0, character = 0 }, ["end"] = { line = vim.api.nvim_buf_line_count(bufnr), character = 0 } },
    context = { only = { "source.fixAll.eslint" }, diagnostics = {} },
  }, function(_, result)
    if not result then return end
    for _, action in ipairs(result) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding or "utf-16")
      end
    end
  end, bufnr)
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          eslint_fix(vim.api.nvim_get_current_buf())
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      notify_on_error = false, -- Don't notify when biome fails but prettier succeeds
      notify_no_formatters = true,

      -- ESLint auto-fix + format on save
      format_on_save = function(bufnr)
        eslint_fix(bufnr)
        if vim.bo[bufnr].filetype == "go" then
          return {
            timeout_ms = 3000,
            lsp_format = "last",
          }
        end
        return {
          timeout_ms = 3000,
          lsp_format = "fallback",
        }
      end,

      formatters_by_ft = {
        -- JS/TS: Try biome first (if biome.json exists), fall back to prettier
        javascript = { "biome", "prettier" },
        javascriptreact = { "biome", "prettier" },
        typescript = { "biome", "prettier" },
        typescriptreact = { "biome", "prettier" },
        json = { "biome", "prettier" },
        jsonc = { "biome", "prettier" },

        -- Vue/CSS/Markdown
        vue = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        mdx = { "prettier" },

        -- Other languages
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
        go = { "goimports", "gofumpt", "golines" },
        yaml = { "prettier" },
        yml = { "prettier" },
      },

      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
        golines = {
          prepend_args = { "-m", "130" },
        },
        -- Biome only runs if biome.json exists, otherwise skips to prettier
        biome = {
          condition = function(self, ctx)
            return vim.fs.find({ "biome.json", "biome.jsonc" }, {
              path = ctx.filename,
              upward = true,
            })[1] ~= nil
          end,
        },
        golangci_lint_fix = {
          command = "golangci-lint",
          args = { "run", "--fix", "$FILENAME" },
          stdin = false,
        },
        -- Prettier - use project config
        prettier = {
          -- Let prettier find and use .prettierrc, prettier.config.js, etc.
        },
      },
    },
  },
}
