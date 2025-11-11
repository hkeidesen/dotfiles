local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Helper function to get the component name from filename
local function get_component_name()
  local filename = vim.fn.expand('%:t:r') -- Get filename without extension
  if filename == '' or filename == 'index' then
    return 'Component'
  end
  -- Convert kebab-case or snake_case to PascalCase
  local component_name = filename:gsub('[_-](%w)', function(c) return c:upper() end)
  component_name = component_name:gsub('^%l', string.upper)
  return component_name
end

return {
  -- React Functional Component
  s('rfc', {
    t 'import React from \'react\'',
    t { '', '' },
    t 'const ',
    f(get_component_name),
    t ' = (',
    i(1, 'props'),
    t ') => {',
    t { '', '  return (', '    <div>' },
    t { '', '      ' },
    i(0, 'Hello World!'),
    t { '', '    </div>', '  )', '}', '' },
    t 'export default ',
    f(get_component_name),
  }),

  -- React Component with useState
  s('rfcs', {
    t 'import React, { useState } from \'react\'',
    t { '', '' },
    t 'const ',
    f(get_component_name),
    t ' = (',
    i(1, 'props'),
    t ') => {',
    t { '', '  const [' },
    i(2, 'state'),
    t ', set',
    f(function(args) 
      local state_name = args[1][1] or 'state'
      return state_name:gsub('^%l', string.upper)
    end, {2}),
    t '] = useState(',
    i(3, "''"),
    t ')',
    t { '', '', '  return (', '    <div>' },
    t { '', '      ' },
    i(0, 'Hello World!'),
    t { '', '    </div>', '  )', '}', '' },
    t 'export default ',
    f(get_component_name),
  }),

  -- React Component with useEffect
  s('rfce', {
    t 'import React, { useEffect } from \'react\'',
    t { '', '' },
    t 'const ',
    f(get_component_name),
    t ' = (',
    i(1, 'props'),
    t ') => {',
    t { '', '  useEffect(() => {', '    ' },
    i(2, '// effect logic here'),
    t { '', '  }, [' },
    i(3),
    t '])',
    t { '', '', '  return (', '    <div>' },
    t { '', '      ' },
    i(0, 'Hello World!'),
    t { '', '    </div>', '  )', '}', '' },
    t 'export default ',
    f(get_component_name),
  }),

  -- Simple React component (minimal)
  s('rc', {
    t 'import React from \'react\'',
    t { '', '' },
    t 'const ',
    f(get_component_name),
    t ' = () => {',
    t { '', '  return (', '    <div>' },
    t { '', '      ' },
    i(0, 'Hello World!'),
    t { '', '    </div>', '  )', '}', '' },
    t 'export default ',
    f(get_component_name),
  }),
}