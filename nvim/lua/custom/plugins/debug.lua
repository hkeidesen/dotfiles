return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
  },
  keys = function(_, keys)
    local dap = require 'dap'
    local dapui = require 'dapui'
    return {
      { '<F5>', dap.continue, desc = 'Debug: Start/Continue' },
      { '<F1>', dap.step_into, desc = 'Debug: Step Into' },
      { '<F2>', dap.step_over, desc = 'Debug: Step Over' },
      { '<F3>', dap.step_out, desc = 'Debug: Step Out' },
      { '<F7>', dapui.toggle, desc = 'Debug: Toggle DAP UI' },
      { '<leader>db', dap.toggle_breakpoint, desc = 'Debug: Toggle Breakpoint' },
      {
        '<leader>dB',
        function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end,
        desc = 'Debug: Conditional Breakpoint',
      },
      { '<leader>dr', dap.repl.open, desc = 'Debug: Open REPL' },
      {
        '<leader>dl',
        function()
          local bps = require('dap.breakpoints').get()
          local fzf = require 'fzf-lua'
          local entries = {}
          for bufnr, buf_bps in pairs(bps) do
            local filename = vim.api.nvim_buf_get_name(bufnr)
            if filename ~= '' then
              filename = vim.fn.fnamemodify(filename, ':~:.')
            end
            for _, bp in ipairs(buf_bps) do
              local line = bp.line
              local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
              local cond = bp.condition and (' [if: ' .. bp.condition .. ']') or ''
              entries[#entries + 1] = string.format('%s:%d:1: %s%s', filename, line, vim.trim(text), cond)
            end
          end
          if #entries == 0 then
            vim.notify('No breakpoints set', vim.log.levels.WARN)
            return
          end
          fzf.fzf_exec(entries, {
            prompt = 'Breakpoints> ',
            previewer = 'builtin',
            actions = fzf.defaults.actions.files,
          })
        end,
        desc = 'Debug: List Breakpoints',
      },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- Breakpoint signs
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapBreakpointCondition', { fg = '#e5a514' })
    vim.api.nvim_set_hl(0, 'DapStopped', { fg = '#98c379', bg = '#2e4033' })
    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint' })
    vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DapBreakpointCondition' })
    vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DapBreakpoint' })
    vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DapStopped', linehl = 'DapStopped' })

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {
        delve = function() end,
      },
      ensure_installed = {
        'delve',
      },
    }

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    -- Intentionally no auto-close: keeps UI open after exit so you can
    -- inspect output / errors.  Close manually with <F7>.

    require('dap-go').setup {
      delve = {
        detached = vim.fn.has 'win32' == 0,
      },
      dap_configurations = {
        {
          type = 'go',
          name = 'Debug Server',
          request = 'launch',
          program = '${workspaceFolder}/cmd/mine-eiendommer-api/main.go',
          env = {
            CONFIG = 'file::dev_cfg/cfg.yml',
            IS_LOCALHOST = 'true',
            SSN_OVERRIDE = '',
          },
        },
      },
    }
  end,
}
