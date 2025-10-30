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
      -- Mason: install binaries
      local servers = {
        "biome",
        "basedpyright",
        "ruff",
        "jsonls",
        "html",
        "gopls",
        "typos_lsp",
        "marksman",
      }
      local tools = vim.list_extend(vim.deepcopy(servers), {
        "markdownlint-cli2",
        "prettier",
      })

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_installation = false,
      })
      require("mason-tool-installer").setup({ ensure_installed = tools })

      -- Capabilities (Blink if present)
      local caps = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink_cmp = pcall(require, "blink.cmp")
      if ok_blink then
        caps = blink_cmp.get_lsp_capabilities(caps)
      end

      -- Helper: root_dir via vim.fs (0.11+)
      local function root_dir(patterns)
        local found = vim.fs.find(patterns, { upward = true, stop = vim.loop.os_homedir() })
        return (found[1] and vim.fs.dirname(found[1])) or vim.uv.cwd()
      end

      -- Inlay hints: default OFF, toggle per buffer
      local inlay = {}
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_inlay_hints", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.supports_method("textDocument/inlayHint") then
            inlay[args.buf] = false
          end
        end,
      })
      vim.api.nvim_create_user_command("ToggleInlayHints", function()
        local bufnr = vim.api.nvim_get_current_buf()
        if inlay[bufnr] == nil then
          print("LSP inlay hints not supported in this buffer.")
          return
        end
        vim.lsp.inlay_hint.enable(not inlay[bufnr], { bufnr = bufnr })
        inlay[bufnr] = not inlay[bufnr]
      end, { desc = "Toggle LSP inlay hints (default off)" })

      -- Keymaps on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_keymaps", { clear = true }),
        callback = function(ev)
          local b = ev.buf
          local function map(lhs, rhs, desc, mode)
            vim.keymap.set(mode or "n", lhs, rhs, { buffer = b, desc = "LSP: " .. desc })
          end
          -- Use fzf-lua for definitions (jumps directly if only one, picker if multiple)
          map("gd", function()
            local ok, fzf = pcall(require, "fzf-lua")
            if ok and fzf.lsp_definitions then
              fzf.lsp_definitions({ jump1 = true })
            else
              vim.lsp.buf.definition()
            end
          end, "Goto Definition")
          -- Use fzf-lua for references (jumps directly if only one, picker if multiple)
          map("gr", function()
            local ok, fzf = pcall(require, "fzf-lua")
            if ok and fzf.lsp_references then
              fzf.lsp_references({ jump1 = true, ignore_current_line = true })
            else
              vim.lsp.buf.references()
            end
          end, "Goto References")
          map("K", vim.lsp.buf.hover, "Hover Docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>cd", vim.diagnostic.open_float, "Show Diagnostics")
          map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
        end,
      })

      -------------------------------------------------------------------------
      -- New API: use vim.lsp.config('name', overrides) then vim.lsp.enable('name')
      -- mason-lspconfig injects proper `cmd` so we don't need to set it manually.
      -------------------------------------------------------------------------

      vim.lsp.config("biome", {
        capabilities = caps,
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "vue" },
        root_dir = root_dir({ "biome.json", "package.json", ".git" }),
      })

      -- Ruff (fast linting, formatting, and code actions - keep all its capabilities)
      vim.lsp.config("ruff", {
        capabilities = caps,
        filetypes = { "python" },
        root_dir = root_dir({ "pyproject.toml", "ruff.toml", ".git" }),
        init_options = { settings = { lineLength = 200 } },
        -- No on_attach - let Ruff provide everything it supports
      })

      -- basedpyright (type checking only - disable what Ruff already provides)
      vim.lsp.config("basedpyright", {
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
        on_attach = function(client)
          -- Disable features that Ruff already provides (fast)
          client.server_capabilities.hoverProvider = false
          client.server_capabilities.renameProvider = false
          -- Keep: definitions, references, completion, type info (Ruff doesn't do these)
        end,
      })

      -- gopls
      vim.lsp.config("gopls", {
        capabilities = caps,
        root_dir = root_dir({ "go.mod", ".git" }),
        settings = {
          gopls = {
            analyses = { unusedparams = true, shadow = true },
            staticcheck = true,
            gofumpt = true,
          },
        },
      })

      -- jsonls
      vim.lsp.config("jsonls", {
        capabilities = caps,
        root_dir = root_dir({ "package.json", ".git" }),
      })

      -- html
      vim.lsp.config("html", {
        capabilities = caps,
      })

      -- typos-lsp
      vim.lsp.config("typos_lsp", {
        capabilities = caps,
        cmd_env = { RUST_LOG = "error" },
        init_options = { diagnosticSeverity = "Error" },
      })

      -- marksman
      vim.lsp.config("marksman", {
        capabilities = caps,
      })

      -- Disable unwanted Python LSP servers
      vim.lsp.config("pylsp", { enabled = false })
      vim.lsp.config("pyright", { enabled = false })

      -- Finally, enable all of them (activates per filetype)
      for _, name in ipairs(servers) do
        vim.lsp.enable(name)
      end
    end,
  },
}
