return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      { 'j-hui/fidget.nvim', opts = {} },
      -- Replaced `cmp-nvim-lsp` with blink.cmp
      'saghen/blink.cmp',
    },
    config = function()
      -------------------------------------------------------------------------
      -- 0) Create the autocmd for LSP keymaps
      -------------------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          -- Jump to definition
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          -- Find references
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          -- Implementations
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          -- Type definitions
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          -- Document symbols
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          -- Workspace symbols
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          -- Rename
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          -- Code actions
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          -- Diagnostics
          map('<leader>cd', vim.diagnostic.open_float, '[C]ode [D]iagnostics', { 'n', 'x' })
          -- Goto declaration
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Example toggling inlay hints if server supports them
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method 'textDocument/inlayHint' then
            map('<leader>th', function()
              vim.lsp.inlay_hint(event.buf, nil) -- toggles the inlay hints
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      local capabilities = require('blink.cmp').get_lsp_capabilities()

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { 'vim' } },
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              completeUnimported = true,
              usePlaceholders = true,
              analyses = {
                unusedparams = true,
                shadow = true,
              },
              staticcheck = true,
            },
          },
          on_attach = function(_, bufnr)
            vim.diagnostic.enable(bufnr)

            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format { async = false }
              end,
            })
          end,
        },
      }

      require('mason').setup()
      local ensure_installed = vim.tbl_keys(servers)
      vim.list_extend(ensure_installed, {
        'stylua', -- Example: stylua for formatting lua code
      })
      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }

      local lspconfig = require 'lspconfig'
      local mason_registry = require 'mason-registry'
      local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path() .. '/node_modules/@vue/language-server'

      -- Example config: ruff for Python
      lspconfig.ruff.setup {
        init_options = { settings = { lineLength = 120 } },
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format { async = false }
            end,
          })
        end,
      }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            -- rename tsserver to ts_ls
            if server_name == 'tsserver' then
              server_name = 'ts_ls'
            end

            -- skip certain servers I don't want
            if server_name == 'emmet_ls' or server_name == 'tailwindcss' or server_name == 'htmx' then
              return
            end

            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})

            if server_name == 'ts_ls' then
              lspconfig.ts_ls.setup {
                capabilities = server.capabilities,
                init_options = {
                  plugins = {
                    {
                      name = '@vue/typescript-plugin',
                      location = vue_language_server_path,
                      languages = { 'vue' },
                    },
                  },
                },
                filetypes = { 'javascript', 'typescript', 'vue' },
              }
              return
            end

            -- If it's Volar (Vue Language Server)
            if server_name == 'volar' then
              lspconfig.volar.setup {
                capabilities = server.capabilities,
              }
              return
            end

            lspconfig[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
