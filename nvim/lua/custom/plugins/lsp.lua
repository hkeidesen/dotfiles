return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      { "williamboman/mason-lspconfig.nvim" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },

    -- Fix https://github.com/neovim/neovim/issues/28058
    init = function()
      local make_client_capabilities = vim.lsp.protocol.make_client_capabilities
      function vim.lsp.protocol.make_client_capabilities()
        local caps = make_client_capabilities()
        if caps.workspace then
          caps.workspace.didChangeWatchedFiles = nil
        end
        return caps
      end
    end,

    config = function()
      vim.filetype.add({
        pattern = {
          [".*%.cy%.ts"] = "typescript",
        },
      })

      local servers = {
        "basedpyright",
        "ruff",
        "jsonls",
        "html",
        "gopls",
        "typos_lsp",
        "marksman",
        "vtsls",
        "vue_ls",
        "eslint",
        "cssls",
        "yamlls",
      }

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = true,
      })
      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(servers), {
          "prettier",
          "biome",
          "stylua",
        }),
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
          end

          -- Use fzf-lua for definition/references if available, fallback to builtin
          local fzf_ok, fzf = pcall(require, "fzf-lua")
          if fzf_ok then
            map("gd", fzf.lsp_definitions, "Goto Definition")
            map("gr", fzf.lsp_references, "Goto References")
            map("gI", fzf.lsp_implementations, "Goto Implementation")
            map("gy", fzf.lsp_typedefs, "Goto Type Definition")
            map("<leader>sw", fzf.grep_cword, "Search Word")
          else
            map("gd", vim.lsp.buf.definition, "Goto Definition")
            map("gr", vim.lsp.buf.references, "Goto References")
            map("gI", vim.lsp.buf.implementation, "Goto Implementation")
            map("gy", vim.lsp.buf.type_definition, "Goto Type Definition")
          end

          map("K", vim.lsp.buf.hover, "Hover Docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>cd", vim.diagnostic.open_float, "Diagnostics")
          vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = ev.buf })
        end,
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",

              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              autoImportCompletions = true,

              diagnosticSeverityOverrides = {
                reportUnusedImport = "information",
                reportUnusedVariable = "information",
                reportUnusedFunction = "information",
                reportMissingTypeStubs = "none",
                reportOptionalMemberAccess = "none",
                reportOptionalSubscript = "none",
                reportPrivateImportUsage = "none",
              },

              diagnosticMode = "workspace",

              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
                parameterTypes = true,
              },
            },
          },
        },
      })
      vim.lsp.enable("basedpyright")

      vim.lsp.config("ruff", {})
      vim.lsp.enable("ruff")

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
              unusedvariable = true,
            },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })
      vim.lsp.enable("gopls")

      -- Configure typos_lsp to report typos as warnings
      vim.lsp.config("typos_lsp", {
        init_options = {
          config = "~/dotfiles/_typos.toml",
          diagnosticSeverity = "Warning",
        },
      })
      vim.lsp.enable("typos_lsp")

      local util = require("lspconfig.util")
      local vue_language_server_path = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

      vim.lsp.config("vtsls", {
        cmd = { "vtsls", "--stdio" },
        settings = {
          vtsls = {
            enableMoveToFileCodeAction = false, -- Disabled due to TS 5.8.3 bug
            tsserver = {
              globalPlugins = {
                {
                  name = "@vue/typescript-plugin",
                  location = vue_language_server_path,
                  languages = { "vue" },
                  configNamespace = "typescript",
                },
              },
            },
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        callback = function(args)
          local fname = vim.api.nvim_buf_get_name(args.buf)
          if fname:match("%.cy%.ts$") then
            return
          end

          local root = util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
          if root then
            local client_id = vim.lsp.start({
              name = "vtsls",
              cmd = { "vtsls", "--stdio" },
              root_dir = root,
              settings = {
                vtsls = {
                  enableMoveToFileCodeAction = false, -- Disabled due to TS 5.8.3 bug
                  tsserver = {
                    globalPlugins = {
                      {
                        name = "@vue/typescript-plugin",
                        location = vue_language_server_path,
                        languages = { "vue" },
                        configNamespace = "typescript",
                      },
                    },
                  },
                },
              },
            })
            if client_id then
              vim.lsp.buf_attach_client(args.buf, client_id)
            end
          end
        end,
      })

      vim.lsp.config("vue_ls", {
        filetypes = { "vue" },
      })

      vim.lsp.config("eslint", {
        settings = {
          format = { enable = false },
        },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            format = {
              enable = true,
              singleQuote = false,
              bracketSpacing = true,
              proseWrap = "preserve",
              printWidth = 200,
            },
            validate = true,
            hover = true,
            completion = true,
            schemas = {
              ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                "docker-compose*.yml",
                "docker-compose*.yaml",
              },
            },
            schemaStore = {
              enable = true,
              url = "https://www.schemastore.org/api/json/catalog.json",
            },
          },
        },
      })
    end,
  },
}
