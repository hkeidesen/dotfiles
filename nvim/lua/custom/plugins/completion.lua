return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
      -- "milanglacier/minuet-ai.nvim",
    },
    opts = {
      enabled = function()
        return vim.bo.buftype ~= "terminal"
      end,
      keymap = {
        preset = "default",
      },
      appearance = {
        nerd_font_variant = "mono",
        -- Kind icons (completion item types)
        kind_icons = {
          claude = "󰋦",
          Ollama = "󰳆",
          ["Llama.cpp"] = "󰳆",
          Text = "󰉿",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",
          Field = "󰜢",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "󰜰",
          Module = "󰆧",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "󰒻",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "󰒻",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "󱐋",
          Operator = "󰆕",
          TypeParameter = "󰬛",
          Array = "",
          Boolean = "󰨙",
          Number = "󰎠",
          String = "󰀬",
          Object = "󰅩",
          Key = "󰌋",
          Null = "󰟢",
          Package = "󰏗",
          Namespace = "󰦮",
        },
      },
      completion = {
        documentation = { auto_show = true },
        trigger = { prefetch_on_insert = true },
        menu = {
          auto_show = true,
          draw = {
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind" },
              { "source_name" }, -- Shows [minuet], [LSP], etc.
            },
            components = {
              source_name = {
                width = { fill = true },
                text = function(ctx)
                  return "[" .. ctx.source_name .. "]"
                end,
                highlight = "BlinkCmpSource",
              },
            },
          },
        },
      },
      sources = {
        default = { "lsp", "path", "buffer", "snippets" },
        providers = {
          -- minuet = {
          --   name = "minuet",
          --   module = "minuet.blink",
          --   async = true,
          --   timeout_ms = 5000,
          --   score_offset = 100,
          -- },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
          -- cmdline preset's Tab is `show_and_insert_or_accept_single` then
          -- `select_next`, which skips past the preselected item when multiple
          -- matches exist. Prefer accepting the current selection first so
          -- Tab inserts the highlighted item (e.g. :L<Tab> -> :Lazy).
          ["<Tab>"] = { "select_and_accept", "select_next", "fallback" },
          ["<S-Tab>"] = { "select_prev", "fallback" },
        },
        sources = { "cmdline", "path", "buffer" },
        completion = {
          menu = { auto_show = true },
          list = {
            selection = {
              -- Highlighted first match is treated as selected, so <CR> accepts
              -- it instead of executing the raw typed text, and <Tab> inserts
              -- the currently highlighted item rather than skipping to the next.
              preselect = true,
              auto_insert = true,
            },
          },
        },
      },
    },
  },
}
