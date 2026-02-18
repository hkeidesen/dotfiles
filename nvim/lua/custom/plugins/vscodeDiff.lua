return {
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CodeDiff",
    config = function()
      require("codediff").setup({})

      -- Label conflict panels via winbar
      vim.api.nvim_create_autocmd({ "BufWinEnter", "TabEnter" }, {
        group = vim.api.nvim_create_augroup("codediff_winbar_labels", { clear = true }),
        callback = function()
          vim.schedule(function()
            local lifecycle = package.loaded["codediff.ui.lifecycle"]
            if not lifecycle then return end

            local tabpage = vim.api.nvim_get_current_tabpage()
            local _, result_win = lifecycle.get_result(tabpage)
            if not result_win or not vim.api.nvim_win_is_valid(result_win) then return end

            local original_win, modified_win = lifecycle.get_windows(tabpage)
            if original_win and vim.api.nvim_win_is_valid(original_win) then
              vim.wo[original_win].winbar = " INCOMING (theirs)"
            end
            if modified_win and vim.api.nvim_win_is_valid(modified_win) then
              vim.wo[modified_win].winbar = " CURRENT (ours)"
            end
            vim.wo[result_win].winbar = " RESULT"
          end)
        end,
      })
    end,
  },
}
