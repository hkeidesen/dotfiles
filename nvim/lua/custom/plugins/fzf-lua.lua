-- Per-picker history: persists queries to a file and binds up/ctrl-u to
-- prev-history, down/ctrl-d to next-history. Merge into a picker's fzf_opts
-- (or pass as opts.fzf_opts at the call site) to opt in.
local function with_history(name)
  return {
    ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-" .. name .. "-history",
    ["--bind"] = "up:prev-history,ctrl-u:prev-history,down:next-history,ctrl-d:next-history",
  }
end

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
      local config = fzf.config
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

      local function build_fd_excludes()
        return table.concat(
          vim.tbl_map(function(e)
            return "--exclude=" .. e
          end, EXCLUDES),
          " "
        )
      end

      local function build_rg_excludes()
        return table.concat(
          vim.tbl_map(function(e)
            return "--glob=!**/" .. e .. "/**"
          end, EXCLUDES),
          " "
        )
      end

      -- List form (no shell expansion) — used by the BufWritePost re-grep.
      local RG_OPTS_LIST = { "--hidden", "--follow", "--no-heading", "--line-number", "--column", "--smart-case", "--trim" }
      for _, e in ipairs(EXCLUDES) do
        table.insert(RG_OPTS_LIST, "--glob=!**/" .. e .. "/**")
      end

      -- String form — kept for fzf-lua, which builds shell commands.
      local RG_OPTS = table.concat({
        "--hidden",
        "--follow",
        "--no-heading",
        "--line-number",
        "--column",
        "--smart-case",
        "--trim",
        build_rg_excludes(),
      }, " ")

      -- Quickfix keymaps - LazyVim style
      config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
      config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
      config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
      config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
      config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
      config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
      config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

      -- Last grep pattern + cwd, captured when results are sent to qflist.
      -- BufWritePost autocmd below re-greps with these to keep Trouble's
      -- qflist view in sync with the buffers it points at.
      -- last_grep_entries is the qflist snapshot at Ctrl-Q time — re-greps
      -- reconcile against it so entries persist (as stale) even if edits
      -- remove the original match.
      local last_grep_pattern = nil
      local last_grep_cwd = nil
      local last_grep_entries = nil

      -- Default file-open: open the file, then re-assert the matched
      -- line/col and `zvzz` to open folds + recenter. Re-asserting on the
      -- next tick beats any BufReadPost handler (e.g. our restore-last-
      -- cursor-position autocmd) that fires during buffer load and would
      -- otherwise leave the cursor on the previous edit mark instead of
      -- the grep match.
      local fzf_path = require("fzf-lua.path")
      config.defaults.actions.files["default"] = function(selected, opts)
        actions.file_edit_or_qf(selected, opts)
        vim.schedule(function()
          if #selected == 1 then
            local entry = fzf_path.entry_to_file(selected[1], opts)
            if entry and entry.line and entry.line > 0 then
              pcall(vim.api.nvim_win_set_cursor, 0,
                { entry.line, math.max(0, (entry.col or 1) - 1) })
            end
          end
          vim.cmd("silent! normal! zvzz")
        end)
      end

      -- Quickfix action - send to quickfix then open Trouble's qflist view
      config.defaults.actions.files["ctrl-q"] = function(selected, opts)
        actions.file_sel_to_qf(selected, opts)
        vim.cmd("cclose")
        -- Live pickers expose `fn_reload`; for those the rg pattern is what
        -- the user typed (last_query). For non-live `grep`, the rg pattern
        -- is the seed (`search`) — last_query would be the fzf-side filter
        -- layered on top, which isn't a valid rg regex.
        if opts.fn_reload then
          last_grep_pattern = opts.last_query
        else
          last_grep_pattern = opts.search
        end
        last_grep_cwd = opts.cwd
        last_grep_entries = vim.fn.getqflist()
        vim.cmd("Trouble qflist open")
      end

      -- Re-run last grep on save so qflist line numbers / hits stay current.
      -- Scoped to "only when Trouble qflist is actually open" to avoid
      -- shelling out to rg on every unrelated save.
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("FzfRegrepOnSave", { clear = true }),
        callback = function()
          if not last_grep_pattern or last_grep_pattern == "" then return end

          local ok, trouble = pcall(require, "trouble")
          if not ok then return end
          -- Trouble v3 API; bail quietly if it changes.
          local open = pcall(function() return trouble.is_open({ mode = "qflist" }) end)
          if not open then return end

          -- Build args as a list so systemlist() skips the shell — otherwise
          -- zsh's `nomatch` (and `!` history expansion) trip on the rg globs.
          local args = { "rg", "--vimgrep" }
          vim.list_extend(args, RG_OPTS_LIST)
          table.insert(args, "--")
          table.insert(args, last_grep_pattern)

          local prev_cwd
          if last_grep_cwd and last_grep_cwd ~= "" then
            prev_cwd = vim.fn.getcwd()
            vim.cmd("lcd " .. vim.fn.fnameescape(last_grep_cwd))
          end
          local lines = vim.fn.systemlist(args)
          if prev_cwd then vim.cmd("lcd " .. vim.fn.fnameescape(prev_cwd)) end

          -- rg exits 1 when there are zero matches — that's a valid outcome,
          -- not an error. Only bail on actual failures (exit >= 2).
          if vim.v.shell_error >= 2 then return end

          -- No snapshot (qflist came from somewhere other than our Ctrl-Q
          -- action) — fall back to plain replace.
          if not last_grep_entries or #last_grep_entries == 0 then
            vim.fn.setqflist({}, "r", { lines = lines, title = "rg: " .. last_grep_pattern })
            pcall(function() trouble.refresh({ mode = "qflist" }) end)
            return
          end

          -- Reconcile original snapshot against fresh rg matches:
          --   * (file, trimmed text) still matches → refresh lnum/col/text
          --   * no match → keep original entry, mark type="W" (stale)
          --   * fresh matches not in the original set are ignored
          local base = (last_grep_cwd and last_grep_cwd ~= "") and last_grep_cwd or vim.fn.getcwd()
          local function to_abs(p)
            if p:sub(1, 1) == "/" then return p end
            return vim.fs.normalize(base .. "/" .. p)
          end

          local fresh_by_file = {}
          for _, line in ipairs(lines) do
            local f, l, c, t = line:match("^(.-):(%d+):(%d+):(.*)$")
            if f then
              local abs = to_abs(f)
              fresh_by_file[abs] = fresh_by_file[abs] or {}
              table.insert(fresh_by_file[abs], {
                lnum = tonumber(l),
                col = tonumber(c),
                text = vim.trim(t),
              })
            end
          end

          local items = {}
          for _, entry in ipairs(last_grep_entries) do
            local name = entry.filename
            if (not name or name == "") and entry.bufnr and entry.bufnr > 0 then
              name = vim.api.nvim_buf_get_name(entry.bufnr)
            end
            if name and name ~= "" then
              local abs = to_abs(name)
              local entry_text = vim.trim(entry.text or "")
              local matched
              local pool = fresh_by_file[abs]
              if pool then
                for i, fresh in ipairs(pool) do
                  if fresh.text == entry_text then
                    matched = fresh
                    table.remove(pool, i)
                    break
                  end
                end
              end
              if matched then
                table.insert(items, {
                  filename = abs,
                  lnum = matched.lnum,
                  col = matched.col,
                  text = matched.text,
                })
              else
                table.insert(items, {
                  filename = abs,
                  lnum = entry.lnum,
                  col = entry.col,
                  text = entry.text,
                  type = "W",
                })
              end
            end
          end

          vim.fn.setqflist({}, "r", { items = items, title = "rg: " .. last_grep_pattern })
          pcall(function() trouble.refresh({ mode = "qflist" }) end)
        end,
      })

      return {
        fzf_colors = true,
        fzf_opts = {
          ["--no-scrollbar"] = true,
        },
        winopts = {
          height = 0.85,
          width = 0.80,
          border = "single",
          backdrop = 100,
          preview = {
            default = "builtin",
            border = "single",
            title = false,
            scrollbar = false,
          },
        },
        files = {
          prompt = "Files> ",
          fd_opts = "--color=never --type f --hidden --follow " .. build_fd_excludes(),
          fzf_opts = with_history("files"),
        },
        buffers = { prompt = "Buffers> ", sort_lastused = true },
        oldfiles = { prompt = "Recent> ", include_current_session = true },
        live_grep = {
          prompt = "Grep> ",
          rg_opts = RG_OPTS,
          rg_glob = true,
          glob_flag = "--iglob",
          glob_separator = "%s%-%-",
          fzf_opts = with_history("grep"),
        },
        grep = {
          prompt = "Grep> ",
          rg_opts = RG_OPTS,
          rg_glob = true,
          glob_flag = "--iglob",
          glob_separator = "%s%-%-",
          fzf_opts = with_history("grep"),
        },
        lsp = {
          prompt_postfix = "> ",
          cwd_header = false,
          code_actions = {
            prompt = "Code Actions> ",
            ui_select = true,
            winopts = { relative = "editor", width = 0.5, height = 0.4 },
          },
        },
        git = {
          status = {
            fzf_opts = {
              ["--header"] = "ctrl-s stage | ctrl-u unstage | ctrl-x reset",
            },
            actions = {
              ["default"] = function(selected, opts)
                actions.file_edit(selected, opts)
                local bufnr = vim.api.nvim_get_current_buf()
                local jumped = false
                local function jump()
                  if jumped then return end
                  jumped = true
                  vim.api.nvim_win_set_cursor(0, { 1, 0 })
                  require("gitsigns").nav_hunk("next")
                end
                -- Fire immediately if gitsigns already has data for this buffer
                vim.schedule(function()
                  local ok, cache = pcall(require, "gitsigns.cache")
                  if ok and cache.cache[bufnr] then
                    jump()
                  else
                    vim.api.nvim_create_autocmd("User", {
                      pattern = "GitSignsUpdate",
                      once = true,
                      callback = jump,
                    })
                  end
                end)
              end,
              ["ctrl-s"] = { fn = actions.git_stage, reload = true },
              ["ctrl-u"] = { fn = actions.git_unstage, reload = true },
              ["ctrl-x"] = { fn = actions.git_reset, reload = true },
              ["left"] = false,
              ["right"] = false,
            },
          },
        },
      }
    end,

    config = function(_, opts)
      local fzf = require("fzf-lua")
      fzf.setup(opts)
      fzf.register_ui_select()

      local map = vim.keymap.set

      -- Files & Buffers
      map("n", "<leader>ff", fzf.files, { desc = "Find files" })
      map("n", "<leader>fr", fzf.oldfiles, { desc = "Find recent" })
      map("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
      map("n", "<leader><leader>", fzf.buffers, { desc = "Find buffers" })
      map("n", "<leader>f/", fzf.blines, { desc = "Find in buffer" })

      -- Grep
      map("n", "<leader>fg", fzf.live_grep, { desc = "Grep" })
      map("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word" })
      map("v", "<leader>fw", fzf.grep_visual, { desc = "Grep selection" })
      map("n", "<leader>sr", fzf.resume, { desc = "Resume search" })

      -- Help & Diagnostics
      map("n", "<leader>fh", fzf.helptags, { desc = "Find help" })
      map("n", "<leader>fk", fzf.keymaps, { desc = "Find keymaps" })
      map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Find diagnostics" })

      -- LSP (gd/gr are set in lsp.lua, these are extras)
      map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Find symbols" })
      map("n", "<leader>fS", function()
        fzf.lsp_live_workspace_symbols({ fzf_opts = with_history("lsp-symbols") })
      end, { desc = "Find workspace symbols" })
      map("n", "<leader>ca", fzf.lsp_code_actions, { desc = "Code actions" })
      map("v", "<leader>ca", fzf.lsp_code_actions, { desc = "Code actions" })

      -- Git (simple direct mappings)
      map("n", "<leader>gs", fzf.git_status, { desc = "Git status" })
      map("n", "<leader>gc", fzf.git_commits, { desc = "Git commits" })
      map("n", "<leader>gb", fzf.git_branches, { desc = "Git branches" })
      map("n", "<leader>gh", fzf.git_bcommits, { desc = "Git file history" })

      -- Command history
      map("n", "<leader>:", fzf.command_history, { desc = "Command history" })

      -- Buffer management
      map("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Delete buffer" })

      -- Quickfix
      map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
      map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
      map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })
      map("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix" })

      -- Claude plans picker
      local function claude_plans()
        local plans_dir = vim.fn.expand("~/.claude/plans")
        local files = vim.fn.glob(plans_dir .. "/*.md", false, true)
        if #files == 0 then
          vim.notify("No plans found in ~/.claude/plans/", vim.log.levels.WARN)
          return
        end

        local entries = {}
        for _, filepath in ipairs(files) do
          local lines = {}
          local f = io.open(filepath, "r")
          if f then
            for i = 1, 10 do
              local line = f:read("*l")
              if not line then break end
              lines[#lines + 1] = line
            end
            f:close()
          end

          -- Parse frontmatter
          local repo, branch, updated
          local title = vim.fn.fnamemodify(filepath, ":t:r")
          local in_frontmatter = false

          for _, line in ipairs(lines) do
            if line:match("^---") then
              if in_frontmatter then break end
              in_frontmatter = true
            elseif in_frontmatter then
              repo = repo or line:match("^repo:%s*(.+)")
              branch = branch or line:match("^branch:%s*(.+)")
              updated = updated or line:match("^updated:%s*(.+)")
            else
              local heading = line:match("^#%s+(.+)")
              if heading then title = heading end
            end
          end

          -- Fallback to mtime if no updated field
          if not updated then
            local stat = vim.uv.fs_stat(filepath)
            if stat then
              updated = os.date("%Y-%m-%d", stat.mtime.sec)
            else
              updated = "unknown"
            end
          end

          local label = string.format("[%s]", updated)
          if repo then
            label = label .. " " .. repo
            if branch then label = label .. "@" .. branch end
          end
          label = label .. " — " .. title

          entries[#entries + 1] = { label = label, updated = updated, path = filepath }
        end

        -- Sort by updated descending
        table.sort(entries, function(a, b) return a.updated > b.updated end)

        local display = {}
        for _, e in ipairs(entries) do
          display[#display + 1] = e.path .. "\t" .. e.label
        end

        fzf.fzf_exec(display, {
          prompt = "Plans> ",
          fzf_opts = {
            ["--delimiter"] = "\t",
            ["--with-nth"] = "2..",
            ["--preview"] = "bat --style=plain --color=always {1} 2>/dev/null || cat {1}",
            ["--preview-window"] = "right:60%",
          },
          actions = {
            ["default"] = function(selected)
              if not selected or #selected == 0 then return end
              local path = selected[1]:match("^(.-)\t")
              if path then
                vim.cmd("edit " .. vim.fn.fnameescape(path))
              end
            end,
          },
        })
      end

      map("n", "<leader>fp", claude_plans, { desc = "Find plans" })

      -- Harpoon
      local harpoon_ok, harpoon = pcall(require, "harpoon")
      if harpoon_ok then
        harpoon:setup({})
        map("n", "<leader>ha", function()
          harpoon:list():add()
        end, { desc = "Harpoon add" })
        map("n", "<leader>hd", function()
          harpoon:list():remove()
        end, { desc = "Harpoon remove" })
        map("n", "<leader>hc", function()
          harpoon:list():clear()
          vim.notify("Harpoon cleared", vim.log.levels.INFO)
        end, { desc = "Harpoon clear all" })
        map("n", "<C-e>", function()
          local items = {}
          for idx, item in ipairs(harpoon:list().items) do
            if item.value and item.value ~= "" then
              table.insert(items, string.format("%d: %s", idx, item.value))
            end
          end
          if #items == 0 then
            vim.notify("Harpoon empty", vim.log.levels.WARN)
            return
          end
          fzf.fzf_exec(items, {
            prompt = "Harpoon> ",
            actions = {
              ["default"] = function(selected)
                local idx = tonumber(selected[1]:match("^(%d+):"))
                if idx then
                  harpoon:list():select(idx)
                end
              end,
            },
          })
        end, { desc = "Harpoon menu" })
        for i = 1, 4 do
          map("n", "<leader>" .. i, function()
            harpoon:list():select(i)
          end, { desc = "Harpoon " .. i })
        end
      end
    end,
  },
}
