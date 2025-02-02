return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = false }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        else
          lsp_format_opt = 'fallback'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        javascript = { 'eslint_d', 'prettier' },
        javascriptreact = { 'eslint_d', 'prettier' },
        json = { 'prettier' },
        lua = { 'stylua' },
        python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
        scss = { 'prettier' },
        css = { 'prettier', 'stylelint' },
        typescript = { 'eslint_d', 'prettier' },
        typescriptreact = { 'eslint_d', 'prettier' },
        vue = { 'eslint_d', 'prettier' },
        go = { 'gofumpt', 'goimports', 'golines' },
      },
      hooks = {
        before_format = function(bufnr)
          vim.b.saved_view = vim.fn.winsaveview()
        end,
        after_format = function(bufnr)
          vim.fn.winrestview(vim.b.saved_view)
        end,
      },
    },
  },
}
