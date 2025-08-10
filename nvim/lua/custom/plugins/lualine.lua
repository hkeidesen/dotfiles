return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = false,
        theme = "auto",
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        globalstatus = false, -- if you want the single bottom bar instead of per-window
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {},
        lualine_c = {
          { "filename", path = 1 },
        },
        lualine_x = {
          {
            "diagnostics",
            sources = { "nvim_lsp" },
            sections = { "error", "warn" },
            symbols = { error = " ", warn = " " },
            colored = true, -- color the whole component
            update_in_insert = false,
          },
        },
        lualine_y = { "branch" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      extensions = {},
    })
  end,
}
