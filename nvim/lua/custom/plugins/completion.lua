return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "milanglacier/minuet-ai.nvim",
    },
    opts = {
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
        trigger = { prefetch_on_insert = false },
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
        default = { "lsp", "minuet", "path", "buffer", "snippets" },
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 5000,
            score_offset = 100,
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        sources = { "cmdline", "path", "buffer" },
        completion = {
          menu = { auto_show = true },
        },
      },
    },
  },
  {
    "milanglacier/minuet-ai.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 8192, -- Your 48GB RAM can handle this
      throttle = 500,
      debounce = 250,
      request_timeout = 8,
      notify = "error",
      provider_options = {
        openai_fim_compatible = {
          api_key = "TERM", -- Placeholder for Ollama (any env var works)
          name = "Ollama",
          end_point = "http://localhost:11434/v1/completions",
          -- model = "qwen2.5-coder:14b",
          model = "qwen2.5-coder:7b",
          optional = {
            max_tokens = 256,
            top_p = 0.95,
            temperature = 0.2,
            stop = { "\n\n", "\n```", "```" },
            num_predict = 256,
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { "python", "javascript", "typescript", "lua", "go", "rust", "cpp", "c" },
        keymap = {
          accept = "<Tab>",
          accept_line = "<C-l>",
          accept_n_lines = "<A-z>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<C-e>",
        },
      },
    },
  },
}
