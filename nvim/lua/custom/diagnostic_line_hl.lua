-- custom/diagnostic_line_hl.lua
-- Diagnostic line highlights: colour full lines for ERROR/WARN,
-- but skip comment lines containing TODO/HACK/FIXME/NOTE/INFO/XXX.
local M = {}

local api = vim.api

M.ns = api.nvim_create_namespace("diagnostic_line_hl")
M.skip_pattern = "^%s*[/-]*%s*(%u+):"
M.skip_keywords = { TODO = true, HACK = true, FIXME = true, NOTE = true, INFO = true, XXX = true }

--- Returns true when the line text matches a skip keyword.
---@param text string
---@return boolean
function M.should_skip_line(text)
  local keyword = text:match(M.skip_pattern)
  return keyword ~= nil and M.skip_keywords[keyword] == true
end

--- Re-apply line highlights for ERROR/WARN diagnostics in `bufnr`.
---@param bufnr integer
function M.refresh(bufnr)
  api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
  local best = {}
  for _, d in ipairs(vim.diagnostic.get(bufnr)) do
    if d.severity <= vim.diagnostic.severity.WARN then
      if not best[d.lnum] or d.severity < best[d.lnum] then
        best[d.lnum] = d.severity
      end
    end
  end
  local line_count = api.nvim_buf_line_count(bufnr)
  for lnum, sev in pairs(best) do
    if lnum < line_count then
      local text = (api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or "")
      if not M.should_skip_line(text) then
        local hl = sev == vim.diagnostic.severity.ERROR and "DiagnosticLineError" or "DiagnosticLineWarn"
        api.nvim_buf_set_extmark(bufnr, M.ns, lnum, 0, { line_hl_group = hl, priority = 10 })
      end
    end
  end
end

return M
