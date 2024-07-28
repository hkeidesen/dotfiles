return {
  'fedepujol/move.nvim',
  config = true,
  event = 'LazyFile',
  keys = {
    { '<A-j>', ':MoveLine(1)<CR>', mode = { 'n' }, noremap = true, silent = true, desc = 'Move line down' },
    { '<A-k>', ':MoveLine(-1)<CR>', mode = { 'n' }, noremap = true, silent = true, desc = 'Move line up' },
    { '<A-j>', ':MoveBlock(1)<CR>', mode = { 'v' }, noremap = true, silent = true, desc = 'Move block down' },
    { '<A-k>', ':MoveBlock(-1)<CR>', mode = { 'v' }, noremap = true, silent = true, desc = 'Move block up' },
  },
}