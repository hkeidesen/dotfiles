local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- TypeScript function
  s('fn', {
    t 'const ',
    i(1, 'functionName'),
    t ' = (',
    i(2, 'params'),
    t '): ',
    i(3, 'ReturnType'),
    t ' => {',
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
    t '): Promise<',
    i(3, 'ReturnType'),
    t '> => {',
    t { '', '  ' },
    i(0, '// function body'),
    t { '', '}' },
  }),

  -- TypeScript interface
  s('interface', {
    t 'interface ',
    i(1, 'InterfaceName'),
    t ' {',
    t { '', '  ' },
    i(0, 'property: string'),
    t { '', '}' },
  }),

  -- TypeScript type
  s('type', {
    t 'type ',
    i(1, 'TypeName'),
    t ' = ',
    i(0, 'string'),
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
}