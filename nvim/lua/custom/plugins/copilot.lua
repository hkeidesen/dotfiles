return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true, -- hide Copilot ghost text when blink menu is open
        debounce = 75,
        keymap = {
          accept = "<Tab>",
          accept_word = "<C-l>", -- mirrors your old accept_line roughly
          accept_line = "<A-l>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<C-e>",
        },
      },
      panel = { enabled = false }, -- the old :Copilot panel; blink + suggestion cover it
      filetypes = {
        -- inverse of a blocklist: explicit allow for filetypes you care about
        python = true,
        javascript = true,
        typescript = true,
        typescriptreact = true,
        javascriptreact = true,
        vue = true,
        lua = true,
        go = true,
        rust = true,
        cpp = true,
        c = true,
        sh = true,
        -- sensitive filetypes explicitly off
        gitcommit = false,
        gitrebase = false,
        ["."] = false, -- the catch-all default: off unless listed above
      },
    },
  },
}
