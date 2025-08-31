return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git: git [s]atus' })
    vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit<CR>', { desc = 'Git: git vertical [d]iff split' })
    vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Git: git [b]lame' })
    vim.keymap.set('v', '<leader>gdo', ':diffput<CR>', { desc = 'Git: stage selected changes in diff window' })
    vim.keymap.set('n', '<leader>gm', ':Gvdiffsplit!<CR>', { desc = 'Git: solve [m]erge conflict. open a 3 way split.' })
    vim.keymap.set('n', '<leader>gir', function()
      local count = vim.v.count
      if count == 0 then
        count = 1
      end
      vim.defer_fn(function()
        vim.cmd('Git rebase -i HEAD~' .. count)
      end, 0)
    end, { desc = 'Git: [I]nteractive [R]ebase', expr = true })
    vim.keymap.set('n', '<leader>gic', ':Git rebase --continue', { desc = 'Git: rebase [c]ontinue' })
  end,
} -- :Git rebase -i HEAD~
