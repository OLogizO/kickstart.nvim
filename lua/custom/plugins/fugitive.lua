return {
  'tpope/vim-fugitive',
  config = function()
    vim.keymap.set('n', '<leader>gs', ':Git<CR>', { desc = 'Git: git [s]atus' })
    vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit<CR>', { desc = 'Git: git vertical [d]iff split' })
    vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { desc = 'Git: git [b]lame' })
    vim.keymap.set('v', '<leader>gdo', ':diffput<CR>', { desc = 'Git: stage selected changes in diff window' })
    vim.keymap.set('n', '<leader>gm', ':Gvdiffsplit!<CR>', { desc = 'Git: solve [m]erge conflict. open a 3 way split.' })
  end,
}
