-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)
local function setUpUnityDebugger() end

local function openOnlyScopesWindow() -- layout 6 in this case is the scopes window. also the one i tend to use.
  require('dapui').open { layout = 6 }
end
return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'jbyuki/one-small-step-for-vimkind',
  },
  lazy = false,
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    {
      '<leader>dl',
      function()
        require('osv').launch { port = 8086 }
      end,
      { noremap = true },
      desc = 'Debug: starts neovim debug server',
    },
    {
      '<leader>dw',
      function()
        local widgets = require 'dap.ui.widgets'
        widgets.hover()
      end,
      desc = 'Debug: open dap ui widgets',
    },
    {
      '<leader>df',
      function()
        local widgets = require 'dap.ui.widgets'
        widgets.centered_float(widgets.frames)
      end,
      desc = 'Debug: open centered float',
    },
    -- window toggles
    {
      '<leader>dtc',
      function()
        require('dapui').toggle { layout = 1 }
      end,
      desc = 'Debug: toggle the console window',
    },
    {
      '<leader>dtr',
      function()
        require('dapui').toggle { layout = 2 }
      end,
      desc = 'Debug: toggle the repl window',
    },

    {
      '<leader>dtw',
      function()
        require('dapui').toggle { layout = 3 }
      end,
      desc = 'Debug: toggle the watches window',
    },

    {
      '<leader>dtt',
      function()
        require('dapui').toggle { layout = 4 }
      end,
      desc = 'Debug: toggle the stacks window',
    },

    {
      '<leader>dtb',
      function()
        require('dapui').toggle { layout = 5 }
      end,
      desc = 'Debug: toggle the breakpoint window',
    },

    {
      '<leader>dts',
      function()
        require('dapui').toggle { layout = 6 }
      end,
      desc = 'Debug: toggle the scopes window',
    },
    -- end of window toggles.

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    local vstuc_path = vim.env.HOME .. '/.vscode/extensions/visualstudiotoolsforunity.vstuc-1.1.2/bin/'
    dap.adapters.vstuc = {
      type = 'executable',
      command = 'dotnet',
      args = { vstuc_path .. 'UnityDebugAdapter.dll' },
      name = 'Attach to Unity',
    }
    dap.configurations.cs = {
      {
        type = 'vstuc',
        request = 'attach',
        name = 'Attach to Unity',
        logFile = vim.fs.joinpath(vim.fn.stdpath 'data') .. '/vstuc.log',
        projectPath = function()
          local path = vim.fn.expand '%:p'
          while true do
            local new_path = vim.fn.fnamemodify(path, ':h')
            if new_path == path then
              return ''
            end
            path = new_path
            local assets = vim.fn.glob(path .. '/Assets')
            if assets ~= '' then
              return path
            end
          end
        end,
        endPoint = function()
          local system_obj = vim.system({ 'dotnet', vstuc_path .. 'UnityAttachProbe.dll' }, { text = true })
          local probe_result = system_obj:wait(2000).stdout
          if probe_result == nil or #probe_result == 0 then
            print 'No endpoint found (is unity running?)'
            return ''
          end
          for json in vim.gsplit(probe_result, '\n') do
            if json ~= '' then
              local probe = vim.json.decode(json)
              for _, p in pairs(probe) do
                if p.isBackground == false then
                  return p.address .. ':' .. p.debuggerPort
                end
              end
            end
          end
          return ''
        end,
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
    end

    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance',
      },
    }

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
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
      layouts = { -- each window is in its own layout so i can toggle them individually
        {
          elements = { -- 1
            {
              id = 'console',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = { -- 2
            {
              id = 'repl',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = { -- 3
            {
              id = 'watches',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = { -- 4
            {
              id = 'stacks',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = { -- 5
            {
              id = 'breakpoints',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = { -- 6
            {
              id = 'scopes',
              size = 40,
            },
          },
          position = 'left',
          size = 40,
        },
      },
    }

    -- Change breakpoint icons
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    dap.listeners.after.event_initialized['dapui_config'] = openOnlyScopesWindow
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
  end,
}
