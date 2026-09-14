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

      -- Prettify Go swag annotations (@Summary, @Produce, @Success, …) in
      -- hover popups. gopls returns the godoc verbatim, and swag tags packed
      -- on consecutive single-newline lines collapse into one markdown
      -- paragraph — unreadable. We parse them into structured markdown:
      -- @Summary X      -> **Summary:** X
      -- @Router /foo [get] -> **Route:** `GET /foo`
      -- @Success/@Failure are grouped into a single **Responses:** list.
      --
      -- In Neovim 0.11+, vim.lsp.buf.hover bypasses vim.lsp.handlers and
      -- renders via vim.lsp.util.open_floating_preview directly — so that
      -- is where we hook. The focus_id guard scopes us to hover popups
      -- only (not signature help, which shares the same preview function).
      local function prettify_swag_lines(lines)
        local out, in_responses = {}, false
        local function push(s)
          if in_responses and not s:match("^%- ") then in_responses = false end
          table.insert(out, s)
        end
        local function ensure_responses_header()
          if not in_responses then
            table.insert(out, "")
            table.insert(out, "**Responses:**")
            in_responses = true
          end
        end
        for _, line in ipairs(lines) do
          local code, model = line:match("^@Success%s+(%S+)%s+{[^}]+}%s+(.+)$")
          if not code then
            code, model = line:match("^@Failure%s+(%S+)%s+{[^}]+}%s+(.+)$")
          end
          if code then
            ensure_responses_header()
            table.insert(out, string.format("- `%s` → `%s`", code, vim.trim(model)))
          else
            in_responses = false
            local summary = line:match("^@Summary%s+(.+)$")
            local produce = line:match("^@Produce%s+(.+)$")
            local accept  = line:match("^@Accept%s+(.+)$")
            local tags    = line:match("^@Tags%s+(.+)$")
            local sec     = line:match("^@Security%s+(.+)$")
            -- Brackets often arrive backslash-escaped (`\[get\]`) because the
            -- LSP markdown pipeline escapes them. Allow optional backslash.
            local route, method = line:match("^@Router%s+(%S+)%s+\\?%[(%w+)\\?%]$")
            if summary then
              push(""); push("**Summary:** " .. summary)
            elseif route then
              push(""); push(string.format("**Route:** `%s %s`", method:upper(), route))
            elseif produce then
              push(""); push("**Produces:** `" .. produce .. "`")
            elseif accept then
              push(""); push("**Accepts:** `" .. accept .. "`")
            elseif tags then
              push(""); push("**Tags:** " .. tags)
            elseif sec then
              push(""); push("**Security:** " .. sec)
            else
              push(line)
            end
          end
        end
        return out
      end

      local orig_open_preview = vim.lsp.util.open_floating_preview
      ---@diagnostic disable-next-line: duplicate-set-field
      function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
        if opts and opts.focus_id == "textDocument/hover" and type(contents) == "table" then
          -- gopls joins consecutive godoc lines into one paragraph (godoc
          -- paragraph rule: inline newlines collapse to spaces), so the
          -- swag tags arrive on a single line. Force a break before every
          -- @Tag preceded by anything, then split and parse line by line.
          local flat = {}
          for _, c in ipairs(contents) do
            c = c:gsub("(%S)%s+(@%u%w+)", "%1\n%2")
            for _, l in ipairs(vim.split(c, "\n", { plain = true })) do
              table.insert(flat, l)
            end
          end
          contents = prettify_swag_lines(flat)
        end
        return orig_open_preview(contents, syntax, opts, ...)
      end

      local servers = {
        "basedpyright",
        "ruff",
        "jsonls",
        "html",
        "gopls",
        "sqls",
        "sqruff",
        "typos_lsp",
        "marksman",
        "vtsls",
        "vue_ls",
        "eslint",
        -- Biome LSP surfaces the same lint warnings CI uses (noNonNullAssertion,
        -- noExplicitAny, useDateNow, unused biome-ignore suppressions). Without
        -- this, those only show up in CI. Conform owns formatting, so biome's
        -- formatter half is disabled in the per-server config below.
        "biome",
        "cssls",
        "yamlls",
      }

      require("mason").setup({
        -- Crashdummyy registry hosts the `roslyn` package (Microsoft's official C# LSP)
        -- used by seblj/roslyn.nvim. Must list the default registry explicitly here too,
        -- otherwise it gets replaced rather than extended.
        registries = {
          "github:mason-org/mason-registry",
          "github:Crashdummyy/mason-registry",
        },
      })
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = true,
      })
      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(servers), {
          "prettier",
          "sql-formatter",
          "biome",
          "stylua",
          -- .NET / C#: roslyn is the LSP binary used by seblj/roslyn.nvim;
          -- csharpier is the formatter (wired up in formattig.lua).
          "roslyn",
          "csharpier",
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
            map("gr", function()
              fzf.lsp_references({ includeDeclaration = false })
            end, "Goto References")
            map("gI", fzf.lsp_implementations, "Goto Implementation")
            map("gy", fzf.lsp_typedefs, "Goto Type Definition")
            map("<leader>sw", fzf.grep_cword, "Search Word")
          else
            map("gd", vim.lsp.buf.definition, "Goto Definition")
            map("gr", function()
              vim.lsp.buf.references({ includeDeclaration = false })
            end, "Goto References")
            map("gI", vim.lsp.buf.implementation, "Goto Implementation")
            map("gy", vim.lsp.buf.type_definition, "Goto Type Definition")
          end

          map("K", function()
            vim.lsp.buf.hover({
              border = "rounded",
              -- 80 fits comfortably inside one split on a side-by-side layout;
              -- bump to 100 if you mostly work in a single pane.
              max_width = 80,
              max_height = 30,
              wrap = true,
            })
          end, "Hover Docs")
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
            staticcheck = false,
            gofumpt = true,
            hints = {
              assignVariableTypes = false,
              compositeLiteralFields = false,
              compositeLiteralTypes = false,
              constantValues = false,
              functionTypeParameters = false,
              parameterNames = false,
              rangeVariableTypes = false,
            },
          },
        },
      })
      vim.lsp.enable("gopls")

      -- sqls has a known whitespace-corrupting formatter. Keep its
      -- diagnostics/completion, but let Conform own SQL formatting.
      vim.lsp.config("sqls", {
        on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      vim.lsp.enable("sqls")

      -- Sqruff provides SQL diagnostics. These migrations use SQL Server
      -- syntax, so select its T-SQL dialect explicitly.
      vim.lsp.config("sqruff", {
        cmd = {
          "sqruff",
          "lsp",
          "--dialect",
          "tsql",
          "--config",
          vim.fn.stdpath("config") .. "/sqruff.cfg",
        },
      })
      vim.lsp.enable("sqruff")

      -- Configure typos_lsp to report typos as warnings
      vim.lsp.config("typos_lsp", {
        init_options = {
          config = "~/dotfiles/_typos.toml",
          diagnosticSeverity = "Warning",
        },
      })
      vim.lsp.enable("typos_lsp")

      local vue_language_server_path = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

      vim.lsp.config("vtsls", {
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
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
        on_attach = function(client, bufnr)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname:match("%.cy%.ts$") then
            vim.lsp.buf_detach_client(bufnr, client.id)
          end
        end,
      })

      vim.lsp.enable("vtsls")

      vim.lsp.config("vue_ls", {
        filetypes = { "vue" },
      })

      vim.lsp.config("eslint", {
        settings = {
          format = { enable = false },
        },
      })

      -- Root the biome LSP at the first biome.json above the file (NOT at the
      -- git root). Stemne's biome config lives at frontend/biome.json and is
      -- marked as a project root, so starting biome from the repo root errors
      -- with "Found a nested root configuration" and produces zero diagnostics.
      -- Pinning root_dir to the biome.json directory makes diagnostics work
      -- regardless of where nvim was launched from.
      vim.lsp.config("biome", {
        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          local found = vim.fs.find({ "biome.json", "biome.jsonc" }, {
            path = fname,
            upward = true,
          })[1]
          if found then on_dir(vim.fs.dirname(found)) end
        end,
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
