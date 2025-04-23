return {
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require 'dap'

      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Start Debugging / Continue' })
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Step Over' })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Step Into' })
      vim.keymap.set('n', '<F12>', dap.step_out, { desc = 'Step Out' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>dr', dap.repl.open, { desc = 'Open REPL' })
    end,
  },

  {
    'leoluz/nvim-dap-go',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    config = function()
      require('dap-go').setup()
    end,
  },

  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap' },
    config = function()
      local dap, dapui = require 'dap', require 'dapui'
      dapui.setup()

      -- Open/close UI automatically
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
      end
    end,
  },
}
