return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim", config = true },
      { "williamboman/mason-lspconfig.nvim", version = "1.32.0" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      -- servers to ensure installed
      local ensure_installed = { "biome", "pyright", "ruff" }

      require("mason").setup()
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        handlers = {
          function(server_name)
            -- base capabilities (with blink.cmp if available)
            local caps = vim.lsp.protocol.make_client_capabilities()
            local ok, blink_cmp = pcall(require, "blink.cmp")
            if ok then
              caps = blink_cmp.get_lsp_capabilities(caps)
            end

            -- BIOME
            if server_name == "biome" then
              lspconfig.biome.setup({
                capabilities = caps,
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "vue" },
                root_dir = util.root_pattern("biome.json", "package.json", ".git"),
                on_attach = function(client)
                  -- disable formatting if using a dedicated formatter
                  client.server_capabilities.documentFormattingProvider = false
                  client.server_capabilities.documentRangeFormattingProvider = false
                end,
              })
              return
            end

            -- RUFF (Python linter)
            if server_name == "ruff" then
              lspconfig.ruff.setup({
                capabilities = caps,
                init_options = { settings = { lineLength = 200 } },
                filetypes = { "python" },
                root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
              })
              return
            end

            -- PYRIGHT (Python type-checker)
            if server_name == "pyright" then
              lspconfig.pyright.setup({
                capabilities = caps,
                root_dir = util.root_pattern("pyproject.toml", "setup.py", ".git"),
                settings = {
                  python = {
                    analysis = {
                      autoImportCompletions = true,
                      diagnosticMode = "workspace",
                      typeCheckingMode = "strict",
                      useLibraryCodeForTypes = true,
                      extraPaths = { "/opt/utils-common" },
                    },
                  },
                },
              })
              return
            end
          end,
        },
      })

      -- Global LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local map = function(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Goto Definition")
          map("gr", vim.lsp.buf.references, "Goto References")
          map("K", vim.lsp.buf.hover, "Hover Docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>cd", vim.diagnostic.open_float, "Show Diagnostics")
        end,
      })
    end,
  },
}
