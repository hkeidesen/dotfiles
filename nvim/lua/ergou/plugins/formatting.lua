local timeout = 1500
return {
  {
    'stevearc/conform.nvim',
    event = 'LazyFile',
    cmd = 'ConformInfo',
    config = function()
      local conform = require('conform')

      conform.setup({
        formatters = {
          phpcbf = {
            prepend_args = { '--standard=vendor/php-cs/ruleset.xml' },
          },
        },
        formatters_by_ft = {
          vue = { 'prettierd' },
          javascript = { 'prettierd' },
          typescript = { 'prettierd' },
          javascriptreact = { 'eslint_d' },
          typescriptreact = { 'eslint_d' },
          css = { 'eslint_d' },
          scss = { 'eslint_d' },
          html = { 'eslint_d' },
          json = { 'prettierd' },
          jsonc = { 'eslint_d' },
          json5 = { 'eslint_d' },
          yaml = { 'eslint_d' },
          markdown = { 'eslint_d' },
          graphql = { 'eslint_d' },
          lua = { 'stylua' },
          python = { 'ruff', 'ruff' },
          php = { 'pint', 'phpcbf', stop_after_first = true },
          zsh = { 'shfmt' },
          sh = { 'shfmt' },
          bash = { 'shfmt' },
          liquid = { 'prettierd' },
        },
        format_on_save = function()
          local ft = vim.bo.filetype

          ---@type conform.FormatOpts
          local config = {
            lsp_format = 'fallback',
            async = false,
            timeout_ms = timeout,
          }

          if ft == 'php' then
            config.lsp_format = 'first'
          end

          -- do not format blade file with html lsp
          if ft == 'blade' then
            config.lsp_format = 'never'
          end

          return config
        end,
      })

      vim.keymap.set({ 'n', 'v' }, '<leader>cF', function()
        conform.format({
          lsp_fallback = 'always',
          async = false,
          timeout_ms = timeout,
        })
      end, { desc = 'Format file or range with LSP Formatter' })

      vim.keymap.set({ 'n', 'v' }, '<leader>cf', function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = timeout,
        })
      end, { desc = 'Format file or range' })
    end,
  },
}