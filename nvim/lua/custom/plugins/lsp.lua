return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      local lspconfig = require 'lspconfig'

      local ensure_installed = {
        'ts_ls',
        'volar',
        'pyright',
        'ruff',
        'pylsp',
        'gopls',
        'eslint',
      }

      require('mason').setup()
      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }
      require('mason-lspconfig').setup {
        ensure_installed = ensure_installed,
        automatic_installation = {},
        handlers = {
          function(server_name)
            if server_name == 'tsserver' then
              server_name = 'ts_ls'
            end

            local server = {}

            -- ✅ Ensure Blink.cmp is initialized before using
            local ok, blink_cmp = pcall(require, 'blink.cmp')
            if ok then
              server.capabilities = blink_cmp.get_lsp_capabilities(server.capabilities or {})
            end

            if server_name == 'ts_ls' or server_name == 'volar' then
              local mason_registry = require 'mason-registry'
              local vue_package = mason_registry.get_package 'vue-language-server'
              local vue_language_server_path = vue_package and vue_package:get_install_path() .. '/node_modules/@vue/language-server' or ''
              lspconfig.volar.setup {
                on_attach = function(client)
                  client.server_capabilities.documentFormattingProvider = false
                end,
              }
              if server_name == 'ts_ls' then
                lspconfig.ts_ls.setup {
                  capabilities = server.capabilities,
                  init_options = {
                    plugins = {
                      { name = '@vue/typescript-plugin', location = vue_language_server_path, languages = { 'vue' } },
                    },
                  },
                  filetypes = { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'vue' },
                  on_attach = function(client)
                    client.server_capabilities.documentFormattingProvider = false
                  end,
                }
                return
              end
            end
            if server_name == 'biome' then
              lspconfig.biome.setup {
                filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc', 'vue' },
                root_dir = function(fname)
                  return require('lspconfig.util').root_pattern('biome.json', 'package.json', '.git')(fname) or vim.fn.getcwd() -- Fallback to current working directory
                end,
                on_attach = function(client, bufnr)
                  client.server_capabilities.documentFormattingProvider = true
                  client.server_capabilities.documentRangeFormattingProvider = true
                end,
              }
            end

            if server_name == 'ruff' then
              lspconfig.ruff.setup {
                capabilities = server.capabilities,
                init_options = { settings = { lineLength = 120 } },
              }
              return
            end

            -- ✅ Python (pylsp + Rope for Extract Method)
            if server_name == 'pylsp' then
              -- lspconfig.pylsp.setup {
              -- capabilities = server.capabilities,
              -- settings = {
              --   pylsp = {
              --     plugins = {
              --       -- ✅ Disable pylsp's built-in linters (since Ruff handles it)
              --       pylint = { enabled = false },
              --       pyflakes = { enabled = false },
              --       pycodestyle = { enabled = false },
              --
              --       -- ✅ Keep Rope for refactoring (Extract Method)
              --       rope_autoimport = { enabled = true },
              --       rope_completion = { enabled = true },
              --       rope_rename = { enabled = true },
              --       rope_refactoring = { enabled = true },
              --     },
              --   },
              -- },
              -- }
              return
            end

            -- ✅ Go Configuration
            if server_name == 'gopls' then
              lspconfig.gopls.setup {
                capabilities = server.capabilities,
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
              }
              return
            end

            -- Eslint

            lspconfig.eslint.setup {
              on_attach = function(client)
                client.server_capabilities.documentFormattingProvider = false
              end,
            }

            -- Typos
            lspconfig.typos_lsp.setup {
              -- cmd_env = { RUST_LOG = 'error' },
              init_options = {
                -- Custom config. Used together with a config file found in the workspace or its parents,
                -- taking precedence for settings declared in both.
                -- Equivalent to the typos `--config` cli argument.
                config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
                -- How typos are rendered in the editor, can be one of an Error, Warning, Info or Hint.
                -- Defaults to error.
                diagnosticSeverity = 'Error',
              },
            }

            -- ✅ Default LSP setup
            lspconfig[server_name].setup(server)
          end,
        },
      }

      -- ✅ LSP Attach Mappings & Autocommands
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('<leader>cd', vim.diagnostic.open_float, '[C]ode [D]iagnostics', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- ✅ LSP Highlights
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- ✅ Inlay Hints Toggle
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })
    end,
  },
}
