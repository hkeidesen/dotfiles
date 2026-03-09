return {
  "echasnovski/mini.nvim",
  version = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("mini.icons").setup()
    require("mini.ai").setup({ n_lines = 500 })
    require("mini.surround").setup()
    require("mini.sessions").setup()

    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        MiniSessions.write("last", { force = true })
      end,
    })
  end,
}
