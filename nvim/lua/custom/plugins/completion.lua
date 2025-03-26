return {
  {
    'saghen/blink.cmp',
    dependencies = {
      'rafamadriz/friendly-snippets', -- Snippet collection
      { 'L3MON4D3/LuaSnip', version = 'v2.*' },
    },

    version = 'v0.13.0',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = 'default' },

      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono',
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = false },
      },
      signature = {
        enabled = true,
      },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      snippets = { preset = 'luasnip' },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = 'cmdline' },
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == '/' or type == '?' then
            return { 'buffer' }
          end
          -- Commands
          if type == ':' or type == '@' then
            return { 'cmdline' }
          end
          return {}
        end,
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = {
            selection = {
              preselect = true,
              auto_insert = true,
            },
          },
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
      },
    },
    opts_extend = { 'sources.default' },
  },
}
