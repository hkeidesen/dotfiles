return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      notify_on_error = true,
      notify_no_formatters = true,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        local ft = vim.bo[bufnr].filetype

        if disable_filetypes[ft] then
          return nil  -- Disable formatting for these filetypes
        end

        -- For all other filetypes, use formatters_by_ft with LSP fallback
        return {
          timeout_ms = 3000,
          lsp_format = "fallback",  -- Always allow LSP fallback
        }
      end,
      formatters_by_ft = {
        -- Try biome first, fall back to prettier if biome not available
        javascript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        json = { "biome", "prettier", stop_after_first = true },
        jsonc = { "biome", "prettier", stop_after_first = true },

        markdown = { "prettier" },
        mdx = { "prettier" },

        vue = { "prettier" },
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
        scss = { "prettier" },
        css = { "prettier", "stylelint" },
        go = { "gofumpt", "goimports", "golines" },
      },
      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
        biome = {
          command = "biome",
          args = { "format", "--stdin-file-path", "$FILENAME" },
          stdin = true,
        },
      },
      hooks = {
        before_format = function(bufnr)
          vim.b.saved_view = vim.fn.winsaveview()
        end,
        after_format = function(bufnr)
          vim.fn.winrestview(vim.b.saved_view)
        end,
      },
    },
    config = function(_, opts)
      require("conform").setup(opts)

      -- Auto-fix on save: apply LSP code actions
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("AutoFixOnSave", { clear = true }),
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          
          -- Helper function to apply code actions silently (suppress "No code actions available")
          local function apply_code_actions_silent(kinds)
            -- Collect clients that can perform code actions
            local clients = vim.lsp.get_clients({ bufnr = args.buf })
            local capable = {}
            for _, client in ipairs(clients) do
              if client.supports_method("textDocument/codeAction") then
                capable[#capable + 1] = client
              end
            end
            if #capable == 0 then return end

            -- Build full-buffer range with accurate end character for last line
            local last_line_index = vim.api.nvim_buf_line_count(args.buf) - 1 -- zero-based
            local last_line_text = vim.api.nvim_buf_get_lines(args.buf, last_line_index, last_line_index + 1, false)[1] or ""
            local end_char = #last_line_text

            local full_params = {
              textDocument = { uri = vim.uri_from_bufnr(args.buf) },
              context = {
                diagnostics = vim.diagnostic.get(args.buf),
                only = kinds,
              },
              range = {
                start = { line = 0, character = 0 },
                ["end"] = { line = last_line_index, character = end_char },
              },
            }

            local attempted_retry = false

            local function request(params)
              vim.lsp.buf_request(args.buf, "textDocument/codeAction", params, function(err, result, ctx)
                -- If server (e.g., Ruff) rejects large range, retry with a minimal range once
                if err and not attempted_retry then
                  attempted_retry = true
                  local simple = vim.deepcopy(full_params)
                  simple.range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } }
                  request(simple)
                  return
                end
                if err or not result or vim.tbl_isempty(result) then return end

                for _, action in ipairs(result) do
                  local kind = action.kind or ""
                  for _, requested in ipairs(kinds) do
                    if kind:match("^" .. requested:gsub("%.", "%%.")) then
                      if action.edit then
                        pcall(vim.lsp.util.apply_workspace_edit, action.edit, ctx.client_id)
                      end
                      local command = action.command or action
                      if command and command.command then
                        pcall(vim.lsp.buf.execute_command, command)
                      end
                      break
                    end
                  end
                end
              end)
            end

            request(full_params)
          end
          
          -- Apply auto-fixes for these file types
          if ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact" then
            -- Apply source.fixAll and source.organizeImports code actions
            apply_code_actions_silent({ "source.fixAll", "source.organizeImports", "source.addMissingImports" })
          elseif ft == "go" then
            -- Apply Go auto-fixes
            apply_code_actions_silent({ "source.fixAll", "source.organizeImports" })
          end
          -- NOTE: Python auto-fix code actions removed.
          -- Ruff formatting & import organization handled via conform formatters: ruff_fix, ruff_format, ruff_organize_imports.
          -- This avoids malformed codeAction requests on older Ruff versions (<0.5.3) that logged missing `range`.
        end,
      })
    end,
  },
}