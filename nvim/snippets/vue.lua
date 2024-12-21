-- ~/.config/nvim/lua/snippets/vue.lua

local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Vue Component Snippet using <script setup> with TypeScript and SCSS
  s('vue', {
    t '<template>',
    t { '', '    <div class="' },
    i(1, 'container'),
    t { '">', '        ' },
    i(2, 'content'),
    t { '', '    </div>', '</template>', '' },
    t { '', '' },
    t '<script setup lang="ts">',
    t { '', '' },
    t { '', '</script>', '' },
    t { '', '' },
    t '<style lang="scss">',
    t { '', '</style>' },
  }),
}
