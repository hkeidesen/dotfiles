return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
      { "ThePrimeagen/harpoon", branch = "harpoon2", dependencies = { "nvim-lua/plenary.nvim" } },
      { "nvim-telescope/telescope-live-grep-args.nvim", version = "^1.0.0" },
      { "nvim-telescope/telescope-symbols.nvim" },
    },
    config = function()
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")

      require("telescope").setup({
        defaults = {
          -- your existing defaults here, e.g.:
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "smart" },
          -- etc.
        },
        pickers = {
          find_files = {
            -- Show hidden files
            hidden = true,
            -- Use ripgrep under the hood for blazing speed
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!.git/*",
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
          live_grep_args = {
            auto_quoting = true,
            mappings = {
              i = {
                ["<C-q>"] = function(prompt_bufnr)
                  actions.send_to_qflist(prompt_bufnr)
                  vim.cmd("cdo set modifiable")
                end,
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                ["<C-space>"] = require("telescope.actions").to_fuzzy_refine,
              },
            },
          },
        },
      })

      -- Load extensions
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")
      pcall(require("telescope").load_extension, "live_grep_args")
      pcall(require("telescope").load_extension, "symbols")

      local builtin = require("telescope.builtin")

      -- Keymaps
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
      vim.keymap.set(
        "n",
        "<leader>sG",
        ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
        { desc = "[S]earch by [G]rep with [A]rgs" }
      )
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
      vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "[S]earch Recent Files (repeat)" })
      vim.keymap.set("n", "<leader>sy", builtin.lsp_document_symbols, { desc = "[S]earch [Y]mbols" })
      vim.keymap.set("n", "<leader>sS", builtin.lsp_workspace_symbols, { desc = "[S]earch [S]ymbols (workspace)" })
      vim.keymap.set("n", "<leader>sm", builtin.marks, { desc = "[S]earch [M]arks" })
      vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
      vim.keymap.set("n", "<leader>bb", "<cmd>b#<CR>", { desc = "Switch to the last buffer" })
      vim.keymap.set("n", "<leader>bd", "<cmd>:bd<CR>", { desc = "Buffer delete" })
      vim.keymap.set("n", "zp", require("ufo").peekFoldedLinesUnderCursor, { desc = "Preview folded text" })

      -- Substitute mappings
      vim.keymap.set(
        "n",
        "sx",
        require("substitute.exchange").operator,
        { noremap = true, silent = true, desc = "Start substitution exchange" }
      )
      vim.keymap.set(
        "n",
        "sxx",
        require("substitute.exchange").line,
        { noremap = true, silent = true, desc = "Exchange entire line" }
      )
      vim.keymap.set(
        "x",
        "X",
        require("substitute.exchange").visual,
        { noremap = true, silent = true, desc = "Exchange visual selection" }
      )
      vim.keymap.set(
        "n",
        "sxc",
        require("substitute.exchange").cancel,
        { noremap = true, silent = true, desc = "Cancel substitution exchange" }
      )

      -- Current-buffer fuzzy find
      vim.keymap.set("n", "<leader>/", function()
        builtin.current_buffer_fuzzy_find(
          require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
        )
      end, { desc = "[/] Fuzzily search in buffer" })

      -- Live grep in open files
      vim.keymap.set("n", "<leader>s/", function()
        builtin.live_grep({ grep_open_files = true, prompt_title = "Live Grep in Open Files" })
      end, { desc = "[S]earch [/] in Open Files" })

      -- Search Neovim config
      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files({ cwd = vim.fn.stdpath("config") })
      end, { desc = "[S]earch [N]eovim files" })

      -- Harpoon + Telescope integration
      local harpoon = require("harpoon")
      harpoon:setup({})
      vim.keymap.set("n", "<leader>ha", function()
        harpoon:list():add()
      end, { desc = "Harpoon: add file" })
      vim.keymap.set("n", "<leader>hd", function()
        harpoon:list():remove()
      end, { desc = "Harpoon: remove file" })
      vim.keymap.set("n", "<leader>hc", function()
        harpoon:list():clear()
      end, { desc = "Harpoon: clear list" })
      vim.keymap.set("n", "<C-S-P>", function()
        harpoon:list():prev()
      end, { desc = "Harpoon: prev" })
      vim.keymap.set("n", "<C-S-N>", function()
        harpoon:list():next()
      end, { desc = "Harpoon: next" })

      -- Custom Harpoon picker
      local conf = require("telescope.config").values
      local function toggle_telescope(harpoon_files)
        local results = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(results, item.value)
        end
        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({ results = results }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
          })
          :find()
      end
      vim.keymap.set("n", "<C-e>", function()
        toggle_telescope(harpoon:list())
      end, { desc = "Open Harpoon window" })
    end,
  },
}
