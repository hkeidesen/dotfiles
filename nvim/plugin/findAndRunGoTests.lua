local function find_test_file()
  local current_file = vim.fn.expand '%:p' -- Full path of the file
  local file_dir = vim.fn.fnamemodify(current_file, ':h') -- Directory of the file
  local file_name = vim.fn.expand '%:t:r' -- File name without extension

  -- Look for a test file that matches "<file>_test.go"
  for _, file in ipairs(vim.fn.readdir(file_dir)) do
    if file:match('^' .. file_name .. '_test%.go$') then
      return file_dir .. '/' .. file
    end
  end
  return nil
end

local function run_relevant_go_test()
  local test_file = find_test_file()

  if not test_file then
    vim.g.go_test_status = '🚨 No matching test file'
    vim.schedule(function()
      if package.loaded['lualine'] then
        require('lualine').refresh()
      end
    end)
    return
  end

  local file_dir = vim.fn.fnamemodify(test_file, ':h')
  local test_cmd = 'cd ' .. file_dir .. ' && go test -v .'

  local output = vim.fn.systemlist(test_cmd)
  local total_tests, failed_tests = 0, 0

  for _, line in ipairs(output) do
    if line:match '^=== RUN' then
      total_tests = total_tests + 1
    elseif line:match '^--- FAIL' then
      failed_tests = failed_tests + 1
    end
  end

  if total_tests > 0 then
    if failed_tests > 0 then
      vim.g.go_test_status = string.format('🔥 %d/%d failed', failed_tests, total_tests)
    else
      vim.g.go_test_status = string.format('✅ %d/%d passed', total_tests, total_tests)
    end
  else
    vim.g.go_test_status = '❌ No tests detected'
  end

  vim.schedule(function()
    require('lualine').refresh()
  end)
end

-- Auto-run relevant tests on save
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.go',
  callback = run_relevant_go_test,
})
