return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.o.termguicolors = true

      -- Load colorscheme
      vim.cmd("colorscheme gruvbox")

      -- Apply custom highlights after colorscheme loads
      vim.cmd([[
        " Diffview highlights
        highlight DiffviewNormal guibg=#1e1e2e
        highlight DiffviewCursorLine guibg=#313244
        
        " Transparent gutters
        highlight SignColumn guibg=NONE ctermbg=NONE
        highlight LineNr guibg=NONE ctermbg=NONE
        highlight CursorLineNr guibg=NONE ctermbg=NONE
        
        " Transparent statusline
        highlight StatusLine guibg=NONE ctermbg=NONE
        highlight StatusLineNC guibg=NONE ctermbg=NONE
        
        " Diagnostic underlines with undercurl
        highlight DiagnosticUnderlineError gui=undercurl guisp=#FF0000
        highlight DiagnosticUnderlineWarn gui=undercurl guisp=#FFA500
        highlight DiagnosticUnderlineUnnecessary gui=undercurl guisp=#FFA500
        highlight DiagnosticUnderlineInfo gui=undercurl guisp=#0000FF
        highlight DiagnosticUnderlineHint gui=undercurl guisp=#808080
      ]])

      -- Terminal codes for undercurl support
      vim.cmd([[ let &t_Cs = "\e[4:3m" ]])
      vim.cmd([[ let &t_Ce = "\e[4:0m" ]])

      -- Autocmd to reapply highlights if colorscheme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          vim.cmd([[
            highlight StatusLine guibg=NONE ctermbg=NONE
            highlight StatusLineNC guibg=NONE ctermbg=NONE
            highlight SignColumn guibg=NONE ctermbg=NONE
            highlight LineNr guibg=NONE ctermbg=NONE
            highlight CursorLineNr guibg=NONE ctermbg=NONE
          ]])
        end,
      })
    end,
  },
}
