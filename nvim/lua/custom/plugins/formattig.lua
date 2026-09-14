-- For JS-family files, prefer biome when the project has a biome.json,
-- otherwise prettier. NEVER chain biome → prettier as a fallback list:
-- if biome fails at runtime (e.g. nested-root config error, version
-- mismatch), conform would silently run prettier next, and prettier with
-- no project config reformats with its own defaults (double quotes, semis,
-- 80-col), producing diffs CI rejects.
-- See: stemne CI failure on frontend/src/views/setup/DashboardView.vue.
local function js_fmt(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local found = vim.fs.find({ "biome.json", "biome.jsonc" }, {
    path = fname,
    upward = true,
  })[1]
  if found then return { "biome" } end
  return { "prettier" }
end

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
          local bufnr = vim.api.nvim_get_current_buf()
          eslint_fix(bufnr)
          local filetype = vim.bo[bufnr].filetype
          local lsp_format = (filetype == "vue" or filetype == "sql") and "never" or "fallback"
          require("conform").format({ async = true, lsp_format = lsp_format })
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
        if vim.bo[bufnr].filetype == "vue" or vim.bo[bufnr].filetype == "sql" then
          return {
            timeout_ms = 3000,
            lsp_format = "never",
          }
        end
        return {
          timeout_ms = 3000,
          lsp_format = "fallback",
        }
      end,

      formatters_by_ft = {
        javascript = js_fmt,
        javascriptreact = js_fmt,
        typescript = js_fmt,
        typescriptreact = js_fmt,
        json = js_fmt,
        jsonc = js_fmt,

        -- Vue: use the repository formatter only. Mixing vue_ls formatting with
        -- biome makes templates oscillate between two different layouts.
        vue = js_fmt,
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
        cs = { "csharpier" },
        sql = { "sql_formatter" },
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
        -- Only run csharpier in repos that have opted in (mirrors the biome pattern).
        -- Why: avoids reformatting team repos that haven't standardised on csharpier.
        csharpier = {
          condition = function(self, ctx)
            return vim.fs.find(
              { ".csharpierrc", ".csharpierrc.json", ".csharpierrc.yaml", ".csharpierrc.yml" },
              { path = ctx.filename, upward = true }
            )[1] ~= nil
          end,
        },
        sql_formatter = {
          prepend_args = {
            "--config",
            '{"language":"transactsql","tabWidth":4}',
          },
        },
      },
    },
  },
}
