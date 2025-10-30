local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Function declaration
  s('fn', {
    t 'const ',
    i(1, 'functionName'),
    t ' = (',
    i(2, 'params'),
    t ') => {',
    t { '', '  ' },
    i(0, '// function body'),
    t { '', '}' },
  }),

  -- Async function
  s('afn', {
    t 'const ',
    i(1, 'functionName'),
    t ' = async (',
    i(2, 'params'),
    t ') => {',
    t { '', '  ' },
    i(0, '// function body'),
    t { '', '}' },
  }),

  -- Try-catch block
  s('try', {
    t 'try {',
    t { '', '  ' },
    i(1, '// try block'),
    t { '', '} catch (' },
    i(2, 'error'),
    t ') {',
    t { '', '  ' },
    i(0, '// catch block'),
    t { '', '}' },
  }),

  -- Console.log
  s('log', {
    t 'console.log(',
    i(0, 'value'),
    t ')',
  }),

  -- Export statement
  s('exp', {
    t 'export { ',
    i(1, 'item'),
    t ' } from \'',
    i(0, './path'),
    t '\'',
  }),

  -- Import statement
  s('imp', {
    t 'import { ',
    i(1, 'item'),
    t ' } from \'',
    i(0, 'module'),
    t '\'',
  }),

  -- Default import
  s('impd', {
    t 'import ',
    i(1, 'defaultExport'),
    t ' from \'',
    i(0, 'module'),
    t '\'',
  }),

  -- Class definition
  s('class', {
    t 'class ',
    i(1, 'ClassName'),
    t ' {',
    t { '', '  constructor(' },
    i(2, 'params'),
    t ') {',
    t { '', '    ' },
    i(0, '// constructor body'),
    t { '', '  }', '}' },
  }),
}