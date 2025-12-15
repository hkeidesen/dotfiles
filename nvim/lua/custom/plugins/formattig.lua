return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      notify_on_error = false, -- Don't notify when biome fails but prettier succeeds
      notify_no_formatters = true,

      -- Simple format on save with LSP fallback
      format_on_save = function(bufnr)
        -- Disable format on save for specific paths if needed
        -- local bufname = vim.api.nvim_buf_get_name(bufnr)
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
        go = { "goimports", "gofumpt" },
        yaml = { "prettier" },
        yml = { "prettier" },
      },

      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
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
        -- Prettier - use project config
        prettier = {
          -- Let prettier find and use .prettierrc, prettier.config.js, etc.
        },
      },
    },
  },
}
