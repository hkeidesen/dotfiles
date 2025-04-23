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
        -- 'ts_ls',
        'volar',
        'pyright',
        'ruff',
        'pylsp',
        'gopls',
        -- 'eslint',
        'biome',
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
            -- If server_name is "tsserver", we rename it to "ts_ls" so we can handle it specially
            if server_name == 'tsserver' then
              server_name = 'ts_ls'
            end

            -- Base server config table
            local server = {}

            -- If using a custom cmp extension (like blink.cmp) for LSP capabilities
            local ok, blink_cmp = pcall(require, 'blink.cmp')
            if ok then
              server.capabilities = blink_cmp.get_lsp_capabilities(server.capabilities or {})
            end

            -- Handle Vue + TypeScript (Volar, ts_ls) setup
            if server_name == 'ts_ls' or server_name == 'volar' then
              local mason_registry = require 'mason-registry'
              local vue_package = mason_registry.get_package 'vue-language-server'
              local vue_language_server_path = vue_package and (vue_package:get_install_path() .. '/node_modules/@vue/language-server') or ''

              -- Setup Volar
              lspconfig.volar.setup {
                on_attach = function(client)
                  client.server_capabilities.documentFormattingProvider = false
                end,
              }

              -- Setup ts_ls
              if server_name == 'ts_ls' then
                lspconfig.ts_ls.setup {
                  capabilities = server.capabilities,
                  init_options = {
                    plugins = {
                      { name = '@vue/typescript-plugin', location = vue_language_server_path, languages = { 'vue' } },
                    },
                  },
                  filetypes = { 'javascript', 'typescript', 'vue' },
                  on_attach = function(client)
                    client.server_capabilities.documentFormattingProvider = false
                  end,
                }
                return
              end
            end

            -- Biome setup
            if server_name == 'biome' then
              lspconfig.biome.setup {
                filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'jsonc', 'vue' },
                root_dir = function(fname)
                  return require('lspconfig.util').root_pattern('biome.json', 'package.json', '.git')(fname) or vim.fn.getcwd()
                end,
                on_attach = function(client, bufnr)
                  if vim.bo[bufnr].filetype == 'vue' then
                    -- Disable Biome formatting for Vue so Prettier (via Conform) can take over
                    client.server_capabilities.documentFormattingProvider = false
                    client.server_capabilities.documentRangeFormattingProvider = false
                  else
                    client.server_capabilities.documentFormattingProvider = true
                    client.server_capabilities.documentRangeFormattingProvider = true
                  end
                end,
              }
            end

            -- Ruff setup
            if server_name == 'ruff' then
              lspconfig.ruff.setup {
                capabilities = server.capabilities,
                init_options = { settings = { lineLength = 120 } },
              }
              return
            end

            -- If we detect pylsp, skip it here (maybe you configure it elsewhere)
            if server_name == 'pylsp' then
              return
            end

            -- Pyright: attach autoImportCompletions to server.settings
            if server_name == 'pyright' then
              server.settings = {
                python = {
                  analysis = {
                    autoImportCompletions = true,
                  },
                },
              }
            end

            -- Gopls setup
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

            -- Eslint setup
            lspconfig.eslint.setup {
              on_attach = function(client, bufnr)
                local ft = vim.bo[bufnr].filetype
                if ft == 'javascriptreact' or ft == 'typescriptreact' then
                  client.stop() -- Stop ESLint for React files
                  return
                end
                client.server_capabilities.documentFormattingProvider = false
              end,
            }

            -- Typos LSP setup
            if server_name == 'typos_lsp' then
              lspconfig.typos_lsp.setup {
                root_dir = function(fname)
                  return require('lspconfig.util').root_pattern('.git', 'package.json')(fname) or vim.fn.getcwd()
                end,
                init_options = {
                  config = '~/code/typos-lsp/crates/typos-lsp/tests/typos.toml',
                  diagnosticSeverity = 'Error',
                },
              }
              return
            end

            -- For all other servers, use the default setup with our custom `server` table
            lspconfig[server_name].setup(server)
          end,
        },
      }

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end
          local builtin = require 'telescope.builtin'
          local actions = require 'telescope.actions'
          local action_state = require 'telescope.actions.state'

          local function lsp_definitions_split()
            builtin.lsp_definitions {
              attach_mappings = function(prompt_bufnr, map)
                local open_in_vsplit = function()
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  if selection then
                    vim.lsp.util.show_document(selection.value)
                  end
                end
                map('i', '<CR>', open_in_vsplit)
                map('n', '<CR>', open_in_vsplit)
                return true
              end,
            }
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gs', lsp_definitions_split, '[G]oto [S]plit Definition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
          map('<leader>cd', vim.diagnostic.open_float, '[C]ode [D]iagnostics', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

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
