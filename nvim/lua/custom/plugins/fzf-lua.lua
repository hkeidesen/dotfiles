return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      { "ThePrimeagen/harpoon", branch = "harpoon2", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = function()
      local fzf = require("fzf-lua")
      local actions = fzf.actions

      local EXCLUDES = {
        ".git",
        ".cache",
        ".venv",
        ".direnv",
        ".idea",
        ".vscode",
        "node_modules",
        "dist",
        "build",
        "coverage",
        "vendor",
        ".next",
        ".nuxt",
      }
      local function build_excludes_fd()
        local t = {}
        for _, e in ipairs(EXCLUDES) do
          t[#t + 1] = ("--exclude=%s"):format(e)
        end
        return table.concat(t, " ")
      end
      local function build_excludes_rg()
        local t = {}
        for _, e in ipairs(EXCLUDES) do
          t[#t + 1] = ("--glob=!**/%s/**"):format(e)
        end
        return table.concat(t, " ")
      end
      local EXCLUDES_FD = build_excludes_fd()
      local EXCLUDES_RG = build_excludes_rg()

      return {
        _EXCLUDES_RG = EXCLUDES_RG,
        fzf_opts = {
          ["--layout"] = "reverse",
          ["--info"] = "inline",
          ["--height"] = "96%",
          ["--border"] = "rounded",
          ["--no-scrollbar"] = true,
          ["--bind"] = table.concat({
            "ctrl-v:paste",
            "super-v:paste",
            "alt-a:toggle-all",
            "alt-d:deselect-all",
            "ctrl-u:preview-half-page-up",
            "ctrl-d:preview-half-page-down",
            "ctrl-f:preview-page-down",
            "ctrl-b:preview-page-up",
          }, ","),
        },
        winopts = {
          preview = {
            default = "builtin",
            wrap = false,
          },
        },
        previewers = {
          builtin = {
            syntax = true,
            syntax_limit_l = 0,
            syntax_limit_b = 1024 * 1024,
          },
        },
        files = {
          prompt = "Files> ",
          fd_opts = ("--color=never --type f --hidden --follow %s"):format(EXCLUDES_FD),
          rg_opts = ("--color=never --files --hidden --follow %s"):format(EXCLUDES_RG),
          file_ignore_patterns = {
            "%.lock$",
            "%-lock%.json$",
            "%.jpe?g$",
            "%.png$",
            "%.gif$",
            "%.svg$",
          },
          actions = {
            ["default"] = actions.file_edit,
            ["ctrl-q"] = actions.file_sel_to_qf, -- Same as alt-q default
          },
        },
        buffers = {
          prompt = "Buffers> ",
          sort_lastused = true,
          actions = {
            ["default"] = actions.buf_edit,
            ["ctrl-q"] = actions.file_sel_to_qf,
          },
        },
        oldfiles = {
          prompt = "Recent> ",
          include_current_session = true,
          actions = {
            ["default"] = actions.file_edit,
            ["ctrl-q"] = actions.file_sel_to_qf,
          },
        },
        live_grep = {
          prompt = "Grep> ",
          rg_opts = table.concat({
            "--hidden",
            "--follow",
            "--no-heading",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            EXCLUDES_RG,
          }, " "),
          actions = {
            ["default"] = actions.file_edit_or_qf,
            ["ctrl-q"] = actions.file_sel_to_qf,
          },
        },
        grep = {
          prompt = "Grep> ",
          rg_opts = table.concat({
            "--hidden",
            "--follow",
            "--no-heading",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            EXCLUDES_RG,
          }, " "),
          actions = {
            ["default"] = actions.file_edit_or_qf,
            ["ctrl-q"] = actions.file_sel_to_qf,
          },
        },
        lsp = {
          symbols = {
            prompt = "Document Symbols> ",
          },
          code_actions = {
            prompt = "Code Actions> ",
            ui_select = true,
            winopts = {
              relative = "editor",
              width = 0.5,
              height = 0.4,
              row = 0.4,
              col = 0.5,
              preview = {
                layout = "vertical",
                vertical = "down:40%",
              },
            },
          },
        },
        diagnostics = {
          prompt = "Diagnostics> ",
        },
        helptags = {
          prompt = "Help> ",
        },
        keymaps = {
          prompt = "Keymaps> ",
        },
        git = {
          status = {
            prompt = "Git Status> ",
            actions = {
              ["default"] = actions.file_edit,
              ["ctrl-q"] = actions.file_sel_to_qf,
            },
          },
          commits = {
            prompt = "Git Commits> ",
            actions = {
              ["default"] = actions.git_checkout,
            },
          },
          bcommits = {
            prompt = "Buffer Commits> ",
            actions = {
              ["default"] = actions.git_buf_edit,
            },
          },
          branches = {
            prompt = "Git Branches> ",
            actions = {
              ["default"] = actions.git_switch,
            },
          },
        },
        command_history = {
          prompt = "Command History> ",
        },
        search_history = {
          prompt = "Search History> ",
        },
        marks = {
          prompt = "Marks> ",
        },
        jumps = {
          prompt = "Jumps> ",
        },
      }
    end,
    config = function(_, opts)
      local fzf = require("fzf-lua")
      fzf.setup(opts)

      -- Register fzf-lua as the UI select handler for code actions
      fzf.register_ui_select()

      -- Auto-open quickfix list when it's populated by fzf
      vim.api.nvim_create_autocmd("QuickFixCmdPost", {
        pattern = "*",
        callback = function()
          vim.cmd("copen")
        end,
      })

      local map = vim.keymap.set
      local function d(s)
        return { desc = s }
      end
      local EXCLUDES_RG = opts._EXCLUDES_RG or "--glob=!**/node_modules/** --glob=!**/.git/**"

      -- Files
      map("n", "<leader>ff", fzf.files, d("[F]ind [F]iles"))
      map("n", "<leader>fF", function()
        if fzf.git_files then
          fzf.git_files({ prompt = "GitFiles> " })
        else
          fzf.files()
        end
      end, d("[F]ind Git [F]iles"))
      map("n", "<leader>fr", fzf.oldfiles, d("[F]ind [R]ecent"))
      map("n", "<leader>fb", fzf.buffers, d("[F]ind [B]uffers"))
      map("n", "<leader>f/", fzf.blines, d("[F]ind in buffer"))

      -- ══════════════════════════════════════════════════════════════════════
      -- 🎯 SINGLE UNIFIED GREP WITH INTERACTIVE TOGGLES
      -- ══════════════════════════════════════════════════════════════════════

      -- State for toggles (persists across grep sessions)
      local grep_state = {
        whole_word = false,
        file_filter = nil,
      }

      map("n", "<leader>fg", function()
        local function build_rg_opts()
          local opts_table = {
            "--hidden",
            "--follow",
            "--no-heading",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            EXCLUDES_RG,
          }

          if grep_state.whole_word then
            table.insert(opts_table, "-w")
          end

          if grep_state.file_filter then
            table.insert(opts_table, grep_state.file_filter)
          end

          return table.concat(opts_table, " ")
        end

        local function build_prompt()
          local parts = { "Grep" }
          if grep_state.whole_word then
            table.insert(parts, "[WORD]")
          end
          if grep_state.file_filter then
            local filter_display = grep_state.file_filter:match("--glob=(.+)") or grep_state.file_filter
            table.insert(parts, string.format("[%s]", filter_display))
          end
          return table.concat(parts, " ") .. "> "
        end

        local function show_grep()
          fzf.live_grep({
            prompt = build_prompt(),
            rg_opts = build_rg_opts(),
            fzf_opts = {
              ["--header"] = table.concat({
                "Alt-W: toggle whole-word [" .. (grep_state.whole_word and "ON" or "OFF") .. "]",
                "Alt-F: set file filter " .. (grep_state.file_filter and "[SET]" or "[NONE]"),
                "Alt-C: clear all filters",
                "Ctrl-Q: send to quickfix",
              }, " | "),
            },
            actions = {
              ["default"] = fzf.actions.file_edit_or_qf,
              ["ctrl-q"] = function(selected, opts)
                fzf.actions.file_edit_or_qf(selected, opts)
                vim.defer_fn(function()
                  vim.cmd("copen")
                end, 100)
              end,
              ["alt-w"] = function()
                grep_state.whole_word = not grep_state.whole_word
                vim.notify("Whole word: " .. (grep_state.whole_word and "ON" or "OFF"), vim.log.levels.INFO)
                vim.defer_fn(show_grep, 50)
              end,
              ["alt-f"] = function()
                vim.ui.input({
                  prompt = "File filter (e.g., *.lua, **/*.tsx, src/**): ",
                  default = grep_state.file_filter and grep_state.file_filter:match("--glob=(.+)") or "",
                }, function(input)
                  if input and input ~= "" then
                    grep_state.file_filter = "--glob=" .. input
                    vim.notify("Filter set: " .. input, vim.log.levels.INFO)
                  else
                    grep_state.file_filter = nil
                    vim.notify("Filter cleared", vim.log.levels.INFO)
                  end
                  vim.defer_fn(show_grep, 50)
                end)
              end,
              ["alt-c"] = function()
                grep_state.whole_word = false
                grep_state.file_filter = nil
                vim.notify("All filters cleared", vim.log.levels.INFO)
                vim.defer_fn(show_grep, 50)
              end,
            },
          })
        end

        show_grep()
      end, d("[F]ind [G]rep (Alt-W:word Alt-F:filter Alt-C:clear Ctrl-Q:quickfix)"))

      -- Quick word search (uses cursor word)
      map("n", "<leader>sw", fzf.grep_cword, d("[S]earch [W]ord under cursor"))
      map("v", "<leader>sw", fzf.grep_visual, d("[S]earch selection"))

      -- Search in open files
      map("n", "<leader>s.", function()
        fzf.grep({
          prompt = "Grep Open Files> ",
          rg_opts = table.concat({
            "--hidden",
            "--follow",
            "--no-heading",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
          }, " "),
          filespec = table.concat(
            vim.tbl_map(
              function(buf)
                return vim.api.nvim_buf_get_name(buf)
              end,
              vim.tbl_filter(function(buf)
                return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
              end, vim.api.nvim_list_bufs())
            ),
            " "
          ),
        })
      end, d("[S]earch in open files"))

      -- Resume last search
      map("n", "<leader>sr", fzf.resume, d("[S]earch [R]esume"))

      -- Help & Diagnostics
      map("n", "<leader>fh", fzf.helptags, d("[F]ind [H]elp"))
      map("n", "<leader>fk", fzf.keymaps, d("[F]ind [K]eymaps"))
      map("n", "<leader>fd", fzf.diagnostics_document, d("[F]ind [D]iagnostics"))
      map("n", "<leader>fD", fzf.diagnostics_workspace, d("[F]ind workspace [D]iagnostics"))

      -- LSP Symbols
      if fzf.lsp_document_symbols then
        map("n", "<leader>fs", fzf.lsp_document_symbols, d("[F]ind document [S]ymbols"))
      end
      if fzf.lsp_live_workspace_symbols then
        map("n", "<leader>fS", fzf.lsp_live_workspace_symbols, d("[F]ind workspace [S]ymbols"))
      end

      -- LSP Code Actions & Navigation
      map("n", "<leader>ca", fzf.lsp_code_actions, d("[C]ode [A]ctions"))
      map("v", "<leader>ca", fzf.lsp_code_actions, d("[C]ode [A]ctions"))
      map("n", "<leader>cd", fzf.lsp_definitions, d("Go to [D]efinition"))
      map("n", "<leader>cD", fzf.lsp_declarations, d("Go to [D]eclaration"))
      map("n", "<leader>ci", fzf.lsp_implementations, d("Go to [I]mplementation"))
      map("n", "<leader>ct", fzf.lsp_typedefs, d("Go to [T]ype definition"))
      map("n", "<leader>cr", fzf.lsp_references, d("[C]ode [R]eferences"))
      map("n", "<leader>cI", fzf.lsp_incoming_calls, d("[I]ncoming calls"))
      map("n", "<leader>cO", fzf.lsp_outgoing_calls, d("[O]utgoing calls"))

      -- ══════════════════════════════════════════════════════════════════════
      -- Git Integration: Quick access + unified menu
      -- ══════════════════════════════════════════════════════════════════════
      -- Quick Git Status access
      map("n", "<leader>gs", fzf.git_status, d("[G]it [S]tatus"))

      -- Unified Git & Gitsigns Menu on <leader>g
      map("n", "<leader>g", function()
        local gitsigns = package.loaded.gitsigns
        if not gitsigns then
          vim.notify("Gitsigns not loaded yet", vim.log.levels.WARN)
          return
        end

        local git_commands = {
          -- FZF-Lua Git Commands
          { "── FZF-Lua Git Commands ──", nil },
          {
            "📁 Git Status",
            function()
              fzf.git_status()
            end,
          },
          {
            "📄 Git Files",
            function()
              fzf.git_files()
            end,
          },
          {
            "📜 Git Commits (Log)",
            function()
              fzf.git_commits()
            end,
          },
          {
            "📝 Git Buffer Commits",
            function()
              fzf.git_bcommits()
            end,
          },
          {
            "🌿 Git Branches",
            function()
              fzf.git_branches()
            end,
          },
          {
            "💾 Git Stash",
            function()
              fzf.git_stash()
            end,
          },

          -- Gitsigns Hunk Commands
          { "── Gitsigns Hunk Actions ──", nil },
          {
            "👁️  Preview Hunk",
            function()
              gitsigns.preview_hunk()
            end,
          },
          {
            "➕ Stage Hunk",
            function()
              gitsigns.stage_hunk()
            end,
          },
          {
            "↩️  Reset Hunk",
            function()
              gitsigns.reset_hunk()
            end,
          },
          {
            "⏭️  Next Hunk",
            function()
              gitsigns.nav_hunk("next")
            end,
          },
          {
            "⏮️  Previous Hunk",
            function()
              gitsigns.nav_hunk("prev")
            end,
          },
          {
            "↩️  Undo Stage Hunk",
            function()
              gitsigns.undo_stage_hunk()
            end,
          },

          -- Gitsigns Buffer Commands
          { "── Gitsigns Buffer Actions ──", nil },
          {
            "📋 Stage Buffer",
            function()
              gitsigns.stage_buffer()
            end,
          },
          {
            "🔄 Reset Buffer",
            function()
              gitsigns.reset_buffer()
            end,
          },
          {
            "🔍 Blame Line",
            function()
              gitsigns.blame_line({ full = true })
            end,
          },
          {
            "👤 Toggle Blame Line",
            function()
              gitsigns.toggle_current_line_blame()
            end,
          },
          {
            "🗑️  Toggle Deleted",
            function()
              gitsigns.toggle_deleted()
            end,
          },

          -- Gitsigns Diff Commands
          { "── Gitsigns Diff Actions ──", nil },
          {
            "📊 Diff This",
            function()
              gitsigns.diffthis()
            end,
          },
          {
            "📊 Diff This ~",
            function()
              gitsigns.diffthis("~")
            end,
          },

          -- Gitsigns Visual Mode Commands
          { "── Gitsigns Visual Actions ──", nil },
          {
            "📌 Stage Visual Selection",
            function()
              vim.cmd("normal! gv")
              local start_line = vim.fn.line("'<")
              local end_line = vim.fn.line("'>")
              vim.cmd("normal! ")
              gitsigns.stage_hunk({ start_line, end_line })
            end,
          },
          {
            "♻️  Reset Visual Selection",
            function()
              vim.cmd("normal! gv")
              local start_line = vim.fn.line("'<")
              local end_line = vim.fn.line("'>")
              vim.cmd("normal! ")
              gitsigns.reset_hunk({ start_line, end_line })
            end,
          },
        }

        local display_items = vim.tbl_map(function(item)
          return item[1]
        end, git_commands)

        fzf.fzf_exec(display_items, {
          prompt = "Git Menu> ",
          actions = {
            ["default"] = function(selected)
              if not selected or #selected == 0 then
                return
              end
              for _, cmd in ipairs(git_commands) do
                if cmd[1] == selected[1] then
                  if cmd[2] then
                    cmd[2]()
                  end
                  break
                end
              end
            end,
          },
          fzf_opts = {
            ["--header"] = "Select Git/Gitsigns Command",
            ["--ansi"] = true,
          },
          winopts = {
            height = 0.6,
            width = 0.5,
          },
        })
      end, d("[G]it & Gitsigns Menu"))

      -- Command & Search History
      map("n", "<leader>:", fzf.command_history, d("Command History"))
      map("n", "<leader>fC", fzf.commands, d("[F]ind [C]ommands"))
      map("n", "<leader>f?", fzf.search_history, d("[F]ind search history"))

      -- Marks & Jumps
      map("n", "<leader>sm", fzf.marks, d("[S]earch [M]arks"))
      map("n", "<leader>sj", fzf.jumps, d("[S]earch [J]umps"))

      -- Buffer management
      map("n", "<leader><leader>", fzf.buffers, d("Find buffers"))
      map("n", "<leader>bb", function()
        local ok = pcall(vim.cmd, "b#")
        if not ok then
          fzf.buffers()
        end
      end, d("Switch to last buffer or pick"))
      map("n", "<leader>bp", "<cmd>b#<CR>", d("Switch to [P]revious buffer"))
      map("n", "<leader>bd", "<cmd>bd<CR>", d("Buffer delete"))

      -- Quickfix & Location List
      map("n", "<leader>qo", "<cmd>copen<CR>", d("[Q]uickfix [O]pen"))
      map("n", "<leader>qc", "<cmd>cclose<CR>", d("[Q]uickfix [C]lose"))
      map("n", "<leader>qn", "<cmd>cnext<CR>", d("[Q]uickfix [N]ext"))
      map("n", "<leader>qp", "<cmd>cprev<CR>", d("[Q]uickfix [P]rev"))
      map("n", "<leader>lo", "<cmd>lopen<CR>", d("[L]ocation list [O]pen"))
      map("n", "<leader>lc", "<cmd>lclose<CR>", d("[L]ocation list [C]lose"))
      map("n", "<leader>ln", "<cmd>lnext<CR>", d("[L]ocation list [N]ext"))
      map("n", "<leader>lp", "<cmd>lprev<CR>", d("[L]ocation list [P]rev"))

      -- Harpoon Integration
      local ok, harpoon = pcall(require, "harpoon")
      if ok then
        harpoon:setup({})
        map("n", "<leader>ha", function()
          harpoon:list():add()
          vim.notify("Added to Harpoon", vim.log.levels.INFO)
        end, d("Harpoon add"))
        map("n", "<leader>hd", function()
          harpoon:list():remove()
          vim.notify("Removed from Harpoon", vim.log.levels.INFO)
        end, d("Harpoon remove"))
        map("n", "<leader>hc", function()
          harpoon:list():clear()
          vim.notify("Harpoon cleared", vim.log.levels.INFO)
        end, d("Harpoon clear"))
        map("n", "<C-S-P>", function()
          harpoon:list():prev()
        end, d("Harpoon prev"))
        map("n", "<C-S-N>", function()
          harpoon:list():next()
        end, d("Harpoon next"))
        for i = 1, 4 do
          map("n", string.format("<leader>%d", i), function()
            harpoon:list():select(i)
          end, d(string.format("Harpoon file %d", i)))
        end
        map("n", "<C-e>", function()
          local list = harpoon:list()
          local items = {}
          for idx, item in ipairs(list.items) do
            if item.value and item.value ~= "" then
              table.insert(items, string.format("%d: %s", idx, item.value))
            end
          end
          if #items == 0 then
            vim.notify("Harpoon list is empty", vim.log.levels.WARN)
            return
          end
          fzf.fzf_exec(items, {
            prompt = "Harpoon> ",
            actions = {
              ["default"] = function(selected)
                if not selected or #selected == 0 then
                  return
                end
                local idx = tonumber(selected[1]:match("^(%d+):"))
                if idx then
                  harpoon:list():select(idx)
                end
              end,
              ["ctrl-d"] = function(selected)
                if not selected or #selected == 0 then
                  return
                end
                local idx = tonumber(selected[1]:match("^(%d+):"))
                if idx then
                  harpoon:list():remove_at(idx)
                  vim.notify("Removed from Harpoon", vim.log.levels.INFO)
                end
              end,
            },
            fzf_opts = {
              ["--header"] = "Enter=open, Ctrl-D=remove",
            },
          })
        end, d("Harpoon picker"))
      end

      -- Multi-file replace command
      vim.api.nvim_create_user_command("ReplaceAll", function()
        local search = vim.fn.input("Find: ")
        if search == "" then
          vim.notify("Search cancelled", vim.log.levels.WARN)
          return
        end
        local repl = vim.fn.input("Replace with: ")
        local esc = function(s)
          return vim.fn.escape(s, "/\\")
        end
        vim.cmd("cfdo %s/" .. esc(search) .. "/" .. esc(repl) .. "/g | update")
        vim.notify("ReplaceAll done", vim.log.levels.INFO)
      end, { desc = "Replace in all files from quickfix list" })
    end,
  },
}

