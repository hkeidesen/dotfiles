return {
  'Aasim-A/scrollEOF.nvim',
  -- INFO: avoid event = 'CursorMoved' here — that fires the lazy-load chain on
  -- the very first cursor jiggle (including the snacks terminal cursor blink),
  -- which adds a noticeable hitch. BufReadPost loads on file open instead.
  event = 'BufReadPost',
  opts = {},
}
