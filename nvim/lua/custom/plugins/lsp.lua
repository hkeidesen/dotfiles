return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} }, -- unpinned to get latest registry (vue_ls, vtsls)
      { "mason-org/mason-lspconfig.nvim" },
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "j-hui/fidget.nvim", opts = {} },
      "saghen/blink.cmp",
    },

    config = function()
      -- Mason: install binaries
      local servers = {
        -- Existing
        "biome",
        "basedpyright",
        "ruff",
        "jsonls",
        "html",
        "gopls",
        "typos_lsp",
        "marksman",
        -- Node / Web / Vue ecosystem additions
        "vtsls",        -- TypeScript language server (needed by vue_ls)
        "eslint",       -- JS/TS/Vue linting & code actions
        "cssls",        -- CSS/SCSS/Less
        "tailwindcss",  -- Tailwind utility class IntelliSense
        "emmet_ls",     -- Emmet abbreviations
        "yamlls",       -- YAML (CI config, workflows)
        -- Vue (dynamic enable below)
        "vue_ls",       -- Official Vue 3 language server (hybrid mode only)
        "vuels",        -- Vue 2 legacy support
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

      -- Detect Vue major version from package.json (returns number or nil)
      local function detect_vue_version(root)
        local pkg_path = root .. "/package.json"
        local stat = vim.loop.fs_stat(pkg_path)
        if not stat then return nil end
        local ok, content = pcall(vim.fn.readfile, pkg_path)
        if not ok then return nil end
        local joined = table.concat(content, "\n")
        local ok_json, decoded = pcall(vim.json.decode, joined)
        if not ok_json or type(decoded) ~= "table" then return nil end
        local function grab(tbl)
          if not tbl then return nil end
          local v = tbl.vue
          if type(v) ~= "string" then return nil end
          return v
        end
        local version_str = grab(decoded.dependencies) or grab(decoded.devDependencies)
        if not version_str then return nil end
        version_str = version_str:gsub("[%^~<>]=?", ""):gsub("%s", "")
        local major = tonumber(version_str:match("^(%d+)%.") or version_str:match("^(%d+)$"))
        return major
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
              fzf.lsp_references({ 
                jump1 = true,  -- Jump directly if only one result
                ignore_current_line = true,  -- Ignore current line (where cursor is)
              })
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

      -- Debug command to check which LSP servers are attached
      vim.api.nvim_create_user_command("LspClients", function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          vim.notify("No LSP clients attached to this buffer", vim.log.levels.WARN)
          return
        end
        local info = {}
        for _, client in ipairs(clients) do
          local caps = client.server_capabilities
          table.insert(info, string.format(
            "%s: refs=%s, def=%s, rename=%s, hover=%s",
            client.name,
            caps.referencesProvider and "✓" or "✗",
            caps.definitionProvider and "✓" or "✗",
            caps.renameProvider and "✓" or "✗",
            caps.hoverProvider and "✓" or "✗"
          ))
        end
        vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
      end, { desc = "Show LSP clients and their capabilities" })

      -- Force basedpyright to restart and reindex
      vim.api.nvim_create_user_command("LspReindexPython", function()
        local clients = vim.lsp.get_clients({ name = "basedpyright" })
        if #clients == 0 then
          vim.notify("Basedpyright not running", vim.log.levels.WARN)
          return
        end
        for _, client in ipairs(clients) do
          vim.notify("Restarting basedpyright to reindex workspace...", vim.log.levels.INFO)
          client.stop()
          vim.defer_fn(function()
            vim.cmd("edit")  -- Trigger LSP attach
            vim.notify("Basedpyright restarted", vim.log.levels.INFO)
          end, 1000)
        end
      end, { desc = "Restart basedpyright to reindex workspace" })

      -------------------------------------------------------------------------
      -- New API: use vim.lsp.config('name', overrides) then vim.lsp.enable('name')
      -- mason-lspconfig injects proper `cmd` so we don't need to set it manually.
      -------------------------------------------------------------------------

      vim.lsp.config("biome", {
        capabilities = caps,
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "vue" },
        root_dir = root_dir({ "biome.json", "package.json", ".git" }),
        on_attach = function(client)
          -- Disable definition-like providers to prevent duplicate results with tsserver
          client.server_capabilities.definitionProvider = false
          client.server_capabilities.declarationProvider = false
          client.server_capabilities.typeDefinitionProvider = false
          client.server_capabilities.implementationProvider = false
        end,
      })
      -- Utility: Deduplicate identical locations (same file + line + character)
      local function dedupe_locations(locations)
        local seen, out = {}, {}
        for _, loc in ipairs(locations) do
          local uri = loc.uri or loc.targetUri
          local range = loc.range or loc.targetRange or loc.targetSelectionRange
          if uri and range and range.start then
            -- Create key from URI + start position (ignore end to catch minor differences)
            local key = string.format("%s:%d:%d", uri, range.start.line, range.start.character)
            if not seen[key] then
              seen[key] = true
              table.insert(out, loc)
            end
          else
            table.insert(out, loc) -- fallback keep
          end
        end
        return out
      end

      -- Override built-in definitions handler to remove duplicates originating from multi-server overlap
      local orig_handler = vim.lsp.handlers["textDocument/definition"]
      vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
        if type(result) == "table" and #result > 1 then
          result = dedupe_locations(result)
        end
        return orig_handler(err, result, ctx, config)
      end

      -- Ruff (fast linting, formatting, and code actions - keep all its capabilities)
      vim.lsp.config("ruff", {
        capabilities = caps,
        filetypes = { "python" },
        root_dir = root_dir({ "pyproject.toml", "ruff.toml", ".git" }),
        init_options = { settings = { lineLength = 200 } },
        -- No on_attach - let Ruff provide everything it supports
      })

      -- basedpyright (type checking, definitions, references, and completion)
      vim.lsp.config("basedpyright", {
        capabilities = caps,
        root_dir = root_dir({ "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "pyrightconfig.json", ".git" }),
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "basic",
              diagnosticMode = "workspace",  -- Must be workspace to find cross-file references
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              stubPath = vim.fn.stdpath("data") .. "/lazy/python-type-stubs",
              autoImportCompletions = true,
              -- Explicitly enable indexing for better cross-file reference tracking
              indexing = true,
              -- Tell basedpyright to analyze all Python files in the workspace
              include = { "**/*.py" },
              exclude = {
                "**/node_modules",
                "**/__pycache__",
                "**/.git",
                "**/.*cache*",
                "**/.venv",
                "**/venv",
              },
              -- CRITICAL: Enable finding references across the entire workspace
              extraPaths = {},
              inlayHints = {
                variableTypes = true,
                functionReturnTypes = true,
                callArgumentNames = true,
              },
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Force workspace indexing on attach
          vim.defer_fn(function()
            -- Trigger a workspace refresh to ensure all files are indexed
            if client.server_capabilities.workspace then
              vim.notify("Basedpyright indexing workspace...", vim.log.levels.INFO)
            end
          end, 1000)
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

      -- eslint (for JS/TS/Vue code actions & diagnostics; formatting handled by conform/prettier/biome)
      vim.lsp.config("eslint", {
        capabilities = caps,
        root_dir = root_dir({ "package.json", ".git" }),
        settings = {
          -- Silence formatting capability so conform takes precedence
          format = { enable = false },
        },
      })

      -- cssls
      vim.lsp.config("cssls", {
        capabilities = caps,
        root_dir = root_dir({ "package.json", ".git" }),
      })

      -- tailwindcss
      vim.lsp.config("tailwindcss", {
        capabilities = caps,
        root_dir = root_dir({ "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts", "postcss.config.js", "package.json", ".git" }),
        settings = {
          tailwindCSS = {
            experimental = { classRegex = { "tw`([^`]*)`" } },
          },
        },
      })

      -- emmet_ls
      vim.lsp.config("emmet_ls", {
        capabilities = caps,
        filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "vue" },
      })

      -- yamlls
      vim.lsp.config("yamlls", {
        capabilities = caps,
        settings = { yaml = { keyOrdering = false } },
      })

      -- vtsls (TypeScript language server needed by vue_ls)
      -- Configure with Vue TypeScript plugin for proper Vue support
      local vue_language_server_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      
      vim.lsp.config("vtsls", {
        capabilities = caps,
        filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "vue" },
        root_dir = root_dir({ "package.json", "tsconfig.json", "jsconfig.json", ".git" }),
        settings = {
          vtsls = {
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
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
        },
        on_attach = function(client, bufnr)
          -- Disable semantic tokens for Vue files to prevent conflicts with vue_ls
          if vim.bo[bufnr].filetype == "vue" then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      })

      -- Vue 2 legacy (vuels)
      vim.lsp.config("vuels", {
        capabilities = caps,
        enabled = false,
        filetypes = { "vue" },
        settings = {
          vetur = {
            validation = { template = true, style = true, script = true },
            completion = { autoImport = true, tag = true, attribute = true },
            format = { defaultFormatter = { js = "prettier" } },
          },
        },
      })

      -- Vue 3 server (vue_ls) hybrid mode: handles templates; TS handled by typescript-tools
      vim.lsp.config("vue_ls", {
        capabilities = caps,
        enabled = false,
        filetypes = { "vue" },
        -- Default cmd from lspconfig: { "vue-language-server", "--stdio" }
      })


      -- Autocmd to enable correct Vue language server based on version
      vim.api.nvim_create_autocmd("BufReadPre", {
        group = vim.api.nvim_create_augroup("vue_dynamic_lsp", { clear = true }),
        pattern = "*.vue",
        callback = function(ev)
          local root = root_dir({ "package.json", "pnpm-workspace.yaml", "yarn.lock", "node_modules", ".git" })
          local major = detect_vue_version(root) or 3 -- assume Vue3 if undetectable
          if major < 3 then
            if not vim.lsp.get_clients({ name = "vuels", bufnr = ev.buf })[1] then
              vim.lsp.enable("vuels")
            end
          else
            if not vim.lsp.get_clients({ name = "vue_ls", bufnr = ev.buf })[1] then
              vim.lsp.enable("vue_ls")
            end
          end
        end,
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

      -- Enable all non-dynamic servers now (Vue servers handled separately)
      for _, name in ipairs(servers) do
        if name ~= "vue_ls" and name ~= "vuels" then
          vim.lsp.enable(name)
        end
      end
    end,
  },
}
