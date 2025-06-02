return {
  {
    "saghen/blink.cmp",
    version = "v0.13.0",
    dependencies = {
      "rafamadriz/friendly-snippets",
      { "L3MON4D3/LuaSnip", version = "v2.*" },

      -- NEW ▸ Copilot completion source
      "fang2hou/blink-copilot",
    },

    ---@type blink.cmp.Config
    opts = {
      keymap = { preset = "default" },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = false },
      },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      snippets = { preset = "luasnip" },

      -- 👉 Add Copilot to the default sources
      sources = {
        default = { "lsp", "copilot", "path", "snippets", "buffer" },

        -- 👉 Tell blink how to talk to Copilot
        providers = {
          copilot = {
            name = "Copilot",
            module = "blink-copilot",
            async = true,
            score_offset = 120, -- lift Copilot suggestions near the top
          },
        },
      },

      cmdline = { -- untouched …
        enabled = true,
        keymap = { preset = "cmdline" },
        sources = function()
          local type = vim.fn.getcmdtype()
          if type == "/" or type == "?" then
            return { "buffer" }
          end
          if type == ":" or type == "@" then
            return { "cmdline" }
          end
          return {}
        end,
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = { selection = { preselect = true, auto_insert = true } },
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
      },
    },

    -- keep your opts_extend as-is
    opts_extend = { "sources.default" },
  },
}
