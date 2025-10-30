return {
  {
  'oribarilan/lensline.nvim',
  tag = '1.1.1', -- or: branch = 'release/1.x' for latest non-breaking updates
  event = 'LspAttach',
  config = function()
    require("lensline").setup()
  end,
}
}
