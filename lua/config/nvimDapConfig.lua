return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'jbyuki/one-small-step-for-vimkind',
  },
  lazy = false,
  config = function()
    -- Put the suggested configuration here
    local dap = require 'dap'
    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance',
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback { type = 'server', host = config.host or '127.0.0.1', port = config.port or 8086 }
    end
    vim.keymap.set('n', '<leader>dl', function()
      require('osv').launch { port = 8086 }
    end, { noremap = true })

    vim.keymap.set('n', '<leader>dw', function()
      local widgets = require 'dap.ui.widgets'
      widgets.hover()
    end)

    vim.keymap.set('n', '<leader>df', function()
      local widgets = require 'dap.ui.widgets'
      widgets.centered_float(widgets.frames)
    end)
  end,
}
