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

      -- Quickfix action - this makes ctrl-q actually send to quickfix
      config.defaults.actions.files["ctrl-q"] = actions.file_sel_to_qf

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
          fzf_opts = {
            ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-files-history",
          },
        },
        buffers = { prompt = "Buffers> ", sort_lastused = true },
        oldfiles = { prompt = "Recent> ", include_current_session = true },
        live_grep = {
          prompt = "Grep> ",
          rg_opts = RG_OPTS,
          rg_glob = true,
          glob_flag = "--iglob",
          glob_separator = "%s%-%-",
          fzf_opts = {
            ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-grep-history",
          },
        },
        grep = {
          prompt = "Grep> ",
          rg_opts = RG_OPTS,
          rg_glob = true,
          glob_flag = "--iglob",
          glob_separator = "%s%-%-",
          fzf_opts = {
            ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-grep-history",
          },
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
      map("n", "<leader>fS", fzf.lsp_live_workspace_symbols, { desc = "Find workspace symbols" })
      map("n", "<leader>ca", fzf.lsp_code_actions, { desc = "Code actions" })
      map("v", "<leader>ca", fzf.lsp_code_actions, { desc = "Code actions" })

      -- Git (simple direct mappings)
      map("n", "<leader>gs", fzf.git_status, { desc = "Git status" })
      map("n", "<leader>gc", fzf.git_commits, { desc = "Git commits" })
      map("n", "<leader>gb", fzf.git_branches, { desc = "Git branches" })
      map("n", "<leader>gB", fzf.git_bcommits, { desc = "Git buffer commits" })

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
