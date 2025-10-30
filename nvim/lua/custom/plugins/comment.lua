return {
  "numToStr/Comment.nvim",
  opts = {
    padding = true,
    extra = {
      ---Add comment on the line above
      above = "gcO",
      ---Add comment on the line below
      below = "gco",
      ---Add comment at the end of line
      eol = "gcA",
    },
    -- Custom hook to handle React/TSX comments
    pre_hook = function(ctx)
      -- Only target React files
      local ft = vim.bo.filetype
      if not (ft == "typescriptreact" or ft == "javascriptreact" or ft == "tsx" or ft == "jsx") then
        return
      end

      local utils = require("Comment.utils")
      
      -- Get the location where we're commenting
      local location = nil
      if ctx.ctype == utils.ctype.blockwise then
        location = require("Comment.utils").get_cursor_location()
      else
        location = ctx.range
      end

      -- Check if we're inside JSX using treesitter
      local ts_utils = require("nvim-treesitter.ts_utils")
      local parser = vim.treesitter.get_parser(0)
      
      if not parser then
        return
      end
      
      -- Get the syntax tree at the cursor position
      local root = parser:parse()[1]:root()
      local node = root:descendant_for_range(location.srow - 1, location.scol, location.erow - 1, location.ecol)
      
      -- Walk up the tree to see if we're inside JSX
      local function is_inside_jsx(n)
        while n do
          local node_type = n:type()
          if node_type == "jsx_element" or 
             node_type == "jsx_self_closing_element" or 
             node_type == "jsx_fragment" or
             node_type == "jsx_expression" then
            return true
          end
          n = n:parent()
        end
        return false
      end

      -- If we're inside JSX, use block comments
      if is_inside_jsx(node) then
        local commentstring = "{/* %s */}"
        return commentstring
      end
      
      -- Otherwise use default line comments
      return nil
    end,
  },
}
