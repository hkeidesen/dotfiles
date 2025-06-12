return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", tag = "v2.0.0", opts = {} },
      { "mason-org/mason-lspconfig.nvim", tag = "v2.0.0" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig.util")

      local ensure_installed = {
        "biome",
        "basedpyright",
        "ruff",
        "jsonls",
        "html",
      }

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = ensure_installed,
        automatic_enable = false,
      })

      local caps = vim.lsp.protocol.make_client_capabilities()
      local ok, blink_cmp = pcall(require, "blink.cmp")
      if ok then
        caps = blink_cmp.get_lsp_capabilities(caps)
      end

      lspconfig.biome.setup({
        capabilities = caps,
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "vue" },
        root_dir = util.root_pattern("biome.json", "package.json", ".git"),
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      -- Track inlay hints state per buffer (all start disabled)
      local inlay_hints_state = {}

      -- Register attach to mark buffers that support inlay hints, but do not enable by default
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_inlay_hints", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          local bufnr = args.buf
          if client and client.supports_method("textDocument/inlayHint") then
            -- mark supported but leave disabled
            inlay_hints_state[bufnr] = false
          end
        end,
      })

      -- Command to toggle inlay hints in current buffer
      vim.api.nvim_create_user_command("ToggleInlayHints", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local enabled = inlay_hints_state[bufnr]

        if enabled == nil then
          print("LSP inlay hints not supported by attached server in this buffer.")
          return
        end

        -- toggle
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
        inlay_hints_state[bufnr] = not enabled
      end, {
        desc = "Toggle LSP inlay hints in the current buffer (default off)",
      })
      lspconfig.ruff.setup({
        capabilities = caps,
        init_options = { settings = { lineLength = 200 } },
        filetypes = { "python" },
        root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
      })

      -- lspconfig.pylsp.setup({
      -- capabilities = caps,
      -- root_dir = util.root_pattern("pyproject.toml", "setup.py", ".git"),
      -- settings = {
      --   pylsp = {
      --     plugins = {
      --       pylsp_mypy = {
      --         enabled = true,
      --         args = { "--strict" },
      --         live_mode = true,
      --       },
      --       pycodestyle = { enabled = false },
      --       mccabe = { enabled = false },
      --       pyflakes = { enabled = false },
      --     },
      --   },
      -- },
      -- })
      if server_config == "pylsp" then
        return
      end

      lspconfig.basedpyright.setup({
        capabilities = caps,
        settings = {
          basedpyright = {
            analysis = {

              typeCheckingMode = "recommended",
              reportReturnType = "error",
              reportIncompatibleReturnType = "error",
              reportIncompatibleMethodOverride = "error",

              diagnosticMode = "openFilesOnly",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,

              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
                callArgumentNames = true,
              },
            },
          },
        },
      })

      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Goto Definition")
          map("gr", vim.lsp.buf.references, "Goto References")
          map("K", vim.lsp.buf.hover, "Hover Docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>cd", vim.diagnostic.open_float, "Show Diagnostics")

          map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
        end,
      })
    end,
  },
}
