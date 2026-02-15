local M = {}

local default_config = require("claude-review.config")

M.config = {
  default = default_config.default,
  projects = default_config.projects,
}

function M.setup(opts)
  opts = opts or {}
  if opts.default then
    M.config.default = opts.default
  end
  if opts.projects then
    M.config.projects = vim.tbl_deep_extend("force", M.config.projects, opts.projects)
  end
end

local function get_project_name()
  local toplevel = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if vim.v.shell_error ~= 0 or toplevel == "" then
    return nil
  end
  return vim.fn.fnamemodify(toplevel, ":t")
end

local function get_instructions()
  local name = get_project_name()
  if name and M.config.projects[name] then
    return M.config.projects[name]
  end
  return M.config.default
end

local severity_map = {
  ["BUG"] = vim.diagnostic.severity.ERROR,
  ["CONCERN"] = vim.diagnostic.severity.WARN,
  ["SUGGESTION"] = vim.diagnostic.severity.INFO,
  ["TIL"] = vim.diagnostic.severity.HINT,
}

local ns_review = vim.api.nvim_create_namespace("claude_review")
local ns_diag = vim.api.nvim_create_namespace("claude_diagnostics")

-- Parse Claude's response into diagnostics
-- Expected format: LINE:SEVERITY:message
-- e.g. "12:BUG:nil check missing on err return"
local function parse_response(response, bufnr, source)
  local diagnostics = {}
  for line in response:gmatch("[^\n]+") do
    local lnum, sev, msg = line:match("^(%d+):(%a+):(.+)$")
    if lnum and sev and msg then
      local line_count = vim.api.nvim_buf_line_count(bufnr)
      local clamped = math.min(tonumber(lnum), line_count)
      local line_text = vim.api.nvim_buf_get_lines(bufnr, clamped - 1, clamped, false)[1] or ""
      local first_nonws = (line_text:find("%S") or 1) - 1 -- 0-indexed
      local end_col = #line_text
      table.insert(diagnostics, {
        bufnr = bufnr,
        lnum = clamped - 1, -- 0-indexed
        col = first_nonws,
        end_col = end_col,
        message = msg,
        severity = severity_map[sev] or vim.diagnostic.severity.HINT,
        source = source or "claude",
      })
    end
  end
  return diagnostics
end

function M.review_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end

  local diff = vim.fn.system({ "git", "diff", "--", filepath })

  if diff == "" then
    vim.notify("No changes to review", vim.log.levels.INFO)
    return
  end

  vim.notify("Claude reviewing...", vim.log.levels.INFO)

  local prompt = [[
Review this diff. For each issue, respond with ONLY lines in this exact format:
LINE_NUMBER:SEVERITY:message

Where SEVERITY is one of: BUG, CONCERN, SUGGESTION, TIL
LINE_NUMBER is the line number in the NEW version of the file.

Example output:
42:BUG:err is not checked after db.Query call
15:TIL:strings.Cut is cleaner than strings.SplitN for this pattern
28:CONCERN:this goroutine could leak if ctx is never cancelled

If the code looks good, respond with just: LGTM
Do not include any other text, explanation, or formatting.
]]

  local job_id = vim.fn.jobstart({ "claude", "-p", prompt }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      -- Filter trailing empty string that Neovim appends
      local filtered = vim.tbl_filter(function(s)
        return s ~= ""
      end, data or {})
      local response = table.concat(filtered, "\n")

      vim.schedule(function()
        if response == "" then
          return
        end

        if response:match("^%s*LGTM%s*$") then
          vim.diagnostic.set(ns_review, bufnr, {})
          vim.notify("Claude: LGTM", vim.log.levels.INFO)
          return
        end

        local diagnostics = parse_response(response, bufnr, "claude")
        vim.diagnostic.set(ns_review, bufnr, diagnostics)
        vim.notify(string.format("Claude: %d findings", #diagnostics), vim.log.levels.INFO)
      end)
    end,
    on_stderr = function(_, data)
      local filtered = vim.tbl_filter(function(s)
        return s ~= ""
      end, data or {})
      local err = table.concat(filtered, "\n")
      if err ~= "" then
        vim.schedule(function()
          vim.notify("Claude error: " .. err, vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job_id <= 0 then
    vim.notify("Failed to start claude process", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, diff)
  vim.fn.chanclose(job_id, "stdin")
end

function M.diagnose_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")

  if content == "" then
    vim.notify("Buffer is empty", vim.log.levels.INFO)
    return
  end

  vim.notify("Claude diagnosing...", vim.log.levels.INFO)

  local instructions = get_instructions()
  local prompt = string.format(
    [[
Analyze this %s file for issues. For each issue, respond with ONLY lines in this exact format:
LINE_NUMBER:SEVERITY:message

Where SEVERITY is one of: BUG, CONCERN, SUGGESTION, TIL
LINE_NUMBER is the line number in the file.

%s

If the code looks good, respond with just: LGTM
Do not include any other text, explanation, or formatting.
]],
    vim.bo[bufnr].filetype,
    instructions
  )

  local job_id = vim.fn.jobstart({ "claude", "-p", prompt }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local filtered = vim.tbl_filter(function(s)
        return s ~= ""
      end, data or {})
      local response = table.concat(filtered, "\n")

      vim.schedule(function()
        if response == "" then
          return
        end

        if response:match("^%s*LGTM%s*$") then
          vim.diagnostic.set(ns_diag, bufnr, {})
          vim.notify("Claude dx: LGTM", vim.log.levels.INFO)
          return
        end

        local diagnostics = parse_response(response, bufnr, "claude-dx")
        vim.diagnostic.set(ns_diag, bufnr, diagnostics)

        vim.notify(string.format("Claude dx: %d findings", #diagnostics), vim.log.levels.INFO)
      end)
    end,
    on_stderr = function(_, data)
      local filtered = vim.tbl_filter(function(s)
        return s ~= ""
      end, data or {})
      local err = table.concat(filtered, "\n")
      if err ~= "" then
        vim.schedule(function()
          vim.notify("Claude error: " .. err, vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job_id <= 0 then
    vim.notify("Failed to start claude process", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, content)
  vim.fn.chanclose(job_id, "stdin")
end

-- Auto-mode state
M.auto_enabled = false
local last_run = {} -- bufnr -> timestamp
local augroup = vim.api.nvim_create_augroup("claude_auto_diagnostics", { clear = true })

local function debounced_diagnose()
  local bufnr = vim.api.nvim_get_current_buf()
  local now = vim.uv.now() / 1000 -- seconds
  if last_run[bufnr] and (now - last_run[bufnr]) < 5 then
    return
  end
  last_run[bufnr] = now
  M.diagnose_buffer()
end

function M.toggle_auto()
  M.auto_enabled = not M.auto_enabled
  vim.api.nvim_clear_autocmds({ group = augroup })

  if M.auto_enabled then
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      callback = debounced_diagnose,
    })
    vim.api.nvim_create_autocmd("CursorHold", {
      group = augroup,
      callback = debounced_diagnose,
    })
  end

  vim.notify("Auto diagnostics: " .. (M.auto_enabled and "ON" or "OFF"), vim.log.levels.INFO)
end

function M.clear()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.set(ns_review, bufnr, {})
  vim.diagnostic.set(ns_diag, bufnr, {})
  vim.notify("Claude diagnostics cleared", vim.log.levels.INFO)
end

return M
