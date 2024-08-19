return {
  {
    'ThePrimeagen/harpoon',
    enabled = true,
    branch = 'harpoon2',
    event = 'LazyFile',
    opts = {
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
      settings = {
        save_on_toggle = true,
      },
    },
    config = function()
      local harpoon = require('harpoon')
      harpoon.setup({})

      local conf = require("telescope.config").values

      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers").new({}, {
          prompt_title = "Harpoon",
          finder = require("telescope.finders").new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      end

      -- Keymap for <C-e> to toggle Harpoon's Telescope window
      vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end, { desc = "Open Harpoon window" })

      -- Keymap to add the current file to Harpoon
      vim.keymap.set("n", "<leader>ha", function() require('harpoon'):list():add() end, { desc = "Harpoon Add File" })

      -- Keymap to remove the current file from Harpoon
      vim.keymap.set("n", "<leader>hd", function()  require('harpoon'):list():remove() end, { desc = "Harpoon Remove File" })

      -- Keymap to clear all files from Harpoon
      vim.keymap.set("n", "<leader>hc", function() require('harpoon'):list():clear() end, { desc = "Harpoon Clear List" })
    end,
  },
}
