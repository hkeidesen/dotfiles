local Util = require('ergou.util')
local signs = Util.icons.diagnostics

return {
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    event = 'LazyFile',
    dependencies = {
      {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
        build = ':MasonUpdate',
        opts_extend = { 'ensure_installed' },
        opts = {
          ensure_installed = {
            'stylua',
            'eslint_d',
            'cspell',
            'prettierd',
            'ruff',
          },
        },
        config = function(_, opts)
          require('mason').setup(opts)
          local mr = require('mason-registry')
          mr:on('package:install:success', function()
            vim.defer_fn(function()
              require('lazy.core.handler.event').trigger({
                event = 'FileType',
                buf = vim.api.nvim_get_current_buf(),
              })
            end, 100)
          end)

          mr.refresh(function()
            for _, tool in ipairs(opts.ensure_installed) do
              local p = mr.get_package(tool)
              if not p:is_installed() then
                p:install()
              end
            end
          end)
        end,
      },
      { 'williamboman/mason-lspconfig.nvim', config = function() end },
      {
        'utilyre/barbecue.nvim',
        name = 'barbecue',
        dependencies = {
          { 'SmiteshP/nvim-navic' },
        },
        opts = { attach_navic = false },
      },
      { 'b0o/schemastore.nvim' },
    },
    opts = {
      inlay_hints = { enabled = true },
      document_highlight = {
        enabled = true,
      },
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = 'if_many',
          prefix = function(diagnostic)
            if diagnostic.severity == vim.diagnostic.severity.ERROR then
              return signs.Error
            elseif diagnostic.severity == vim.diagnostic.severity.WARN then
              return signs.Warn
            elseif diagnostic.severity == vim.diagnostic.severity.HINT then
              return signs.Hint
            elseif diagnostic.severity == vim.diagnostic.severity.INFO then
              return signs.Info
            end
            return '●'
          end,
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = signs.Error,
            [vim.diagnostic.severity.WARN] = signs.Warn,
            [vim.diagnostic.severity.HINT] = signs.Hint,
            [vim.diagnostic.severity.INFO] = signs.Info,
          },
        },
      },
    },
    config = function(_, opts)
      local servers = Util.lsp.get_servers()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      local ensure_install_servers = vim.tbl_keys(servers)

      local mason_lspconfig = require('mason-lspconfig')
      Util.lsp.lsp_autocmd()

      mason_lspconfig.setup({
        ensure_installed = ensure_install_servers,
        handlers = {
          function(server_name)
            if server_name ~= "pylsp" then
              local server = servers[server_name] or {}
              server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
              require('lspconfig')[server_name].setup(server)
            end
            if server_name == 'tsserver' then
              server_name ="ts_ls"
            end
          end,
        },
      })
    end,
  },
}
