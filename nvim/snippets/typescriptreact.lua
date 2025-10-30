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
  -- React Functional Component with TypeScript
  s('rfc', {
    t 'import React from "react";',
    t { '', '' },
    t 'interface Props {',
    t { '', '  ' },
    i(1, 'prop: string;'),
    t { '', '}', '' },
    t 'const ',
    f(get_component_name),
    t ': React.FC<Props> = (props) => {',
    t { '', '  return <div>' },
    i(0, 'content'),
    t '</div>;',
    t { '', '};', '' },
    t 'export default ',
    f(get_component_name),
    t ';',
  }),

  -- React Component with useState
  s('rfcs', {
    t 'import React, { useState } from "react";',
    t { '', '' },
    t 'interface Props {',
    t { '', '  ' },
    i(1, 'prop: string;'),
    t { '', '}', '' },
    t 'const ',
    f(get_component_name),
    t ': React.FC<Props> = (props) => {',
    t { '', '  const [' },
    i(2, 'state'),
    t ', set',
    f(function(args) 
      local state_name = args[1][1] or 'state'
      return state_name:gsub('^%l', string.upper)
    end, {2}),
    t '] = useState<',
    i(3, 'string'),
    t '>(',
    i(4, '""'),
    t ');',
    t { '', '', '  return <div>' },
    i(0, 'content'),
    t '</div>;',
    t { '', '};', '' },
    t 'export default ',
    f(get_component_name),
    t ';',
  }),

  -- React Component with useEffect
  s('rfce', {
    t 'import React, { useEffect } from "react";',
    t { '', '' },
    t 'interface Props {',
    t { '', '  ' },
    i(1, 'prop: string;'),
    t { '', '}', '' },
    t 'const ',
    f(get_component_name),
    t ': React.FC<Props> = (props) => {',
    t { '', '  useEffect(() => {', '    ' },
    i(2, '// effect logic here'),
    t { '', '  }, [' },
    i(3),
    t ']);',
    t { '', '', '  return <div>' },
    i(0, 'content'),
    t '</div>;',
    t { '', '};', '' },
    t 'export default ',
    f(get_component_name),
    t ';',
  }),

  -- Simple React component (minimal)
  s('rc', {
    t 'import React from "react";',
    t { '', '' },
    t 'const ',
    f(get_component_name),
    t ' = () => {',
    t { '', '  return <div>' },
    i(0, 'content'),
    t '</div>;',
    t { '', '};', '' },
    t 'export default ',
    f(get_component_name),
    t ';',
  }),

  -- TypeScript interface
  s('interface', {
    t 'interface ',
    i(1, 'InterfaceName'),
    t ' {',
    t { '', '  ' },
    i(0, 'property: string;'),
    t { '', '}' },
  }),

  -- TypeScript type
  s('type', {
    t 'type ',
    i(1, 'TypeName'),
    t ' = ',
    i(0, 'string;'),
  }),
}