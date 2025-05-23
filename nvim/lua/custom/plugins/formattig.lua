-- Conform config
return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          local mode = vim.fn.mode()
          if mode == 'v' then
            local start_pos = vim.fn.getpos "'<"
            local end_pos = vim.fn.getpos "'>"
            require('conform').format {
              async = false,
              range = {
                start = { start_pos[2], start_pos[3] },
                ['end'] = { end_pos[2], end_pos[3] },
              },
            }
          else
            require('conform').format { async = false }
          end
        end,
        mode = { 'n', 'v' },
        desc = '[F]ormat buffer or selection',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local ft = vim.bo[bufnr].filetype
        local biome_filetypes = {
          javascript = true,
          javascriptreact = true,
          typescript = true,
          typescriptreact = true,
          json = true,
          jsonc = true,
          -- vue = true,  -- removed vue here!
        }
        local lsp_format_opt
        if disable_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'never'
        elseif biome_filetypes[vim.bo[bufnr].filetype] then
          lsp_format_opt = 'always'
        else
          lsp_format_opt = 'fallback'
        end
        if ft == 'javascriptreact' or ft == 'typescriptreact' then
          lsp_format_opt = 'never'
        end
        return {
          timeout_ms = 500,
          lsp_format = lsp_format_opt,
        }
      end,
      formatters_by_ft = {
        javascript = { 'biome' },
        javascriptreact = { 'biome' },
        typescript = { 'biome' },
        typescriptreact = { 'biome' },
        json = { 'biome' },
        jsonc = { 'biome' },
        vue = { 'prettier' },
        lua = { 'stylua' },
        python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
        scss = { 'prettier' },
        css = { 'prettier', 'stylelint' },
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
