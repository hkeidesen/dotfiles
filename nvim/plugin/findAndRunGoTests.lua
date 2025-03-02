local function find_test_file()
  local current_file = vim.fn.expand '%:p'
  local file_dir = vim.fn.fnamemodify(current_file, ':h')
  local file_name = vim.fn.expand '%:t:r'

  -- Look for a test file that matches "<file>_test.go"
  for _, file in ipairs(vim.fn.readdir(file_dir)) do
    if file:match('^' .. file_name .. '_test%.go$') then
      return file_dir .. '/' .. file
    end
  end
  return nil
end

local spinners = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

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
  local test_cmd = { 'go', 'test', '-v', '.' }

  -- Variables to track test progress
  local total_tests, running_tests, failed_tests = 0, 0, 0
  local is_running = true
  local spinner_index = 1

  -- Function to update the spinner and status dynamically
  local function update_spinner()
    if not is_running then
      return
    end -- Stop if tests are done
    spinner_index = (spinner_index % #spinners) + 1
    vim.g.go_test_status = string.format('%s Running... %d/%d | 🔥 %d failed', spinners[spinner_index], running_tests, total_tests, failed_tests)

    vim.schedule(function()
      if package.loaded['lualine'] then
        require('lualine').refresh()
      end
    end)

    vim.defer_fn(update_spinner, 100) -- Schedule next spinner update in 100ms
  end

  -- Start the spinner animation
  update_spinner()

  -- Run tests asynchronously
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local function process_output(data)
    if not data then
      return
    end
    for line in data:gmatch '[^\r\n]+' do
      if line:match '^=== RUN' then
        total_tests = total_tests + 1
        running_tests = running_tests + 1
      elseif line:match '^--- FAIL' then
        failed_tests = failed_tests + 1
      end

      -- **Refresh status dynamically while tests are running**
      vim.g.go_test_status = string.format('%s Running... %d/%d | 🔥 %d failed', spinners[spinner_index], running_tests, total_tests, failed_tests)

      vim.schedule(function()
        if package.loaded['lualine'] then
          require('lualine').refresh()
        end
      end)
    end
  end

  local handle
  handle = vim.loop.spawn('go', {
    args = { 'test', '-v', '.' },
    cwd = file_dir,
    stdio = { nil, stdout, stderr },
  }, function()
    -- Process completion callback (runs once the test process finishes)
    is_running = false -- Stop the spinner
    stdout:close()
    stderr:close()
    handle:close()

    -- Final status update after all tests have completed
    vim.schedule(function()
      if total_tests > 0 then
        if failed_tests > 0 then
          vim.g.go_test_status = string.format('🔥 %d/%d failed', failed_tests, total_tests)
        else
          vim.g.go_test_status = string.format('✅ %d/%d passed', total_tests, total_tests)
        end
      else
        vim.g.go_test_status = '❌ No tests detected'
      end

      require('lualine').refresh()
    end)
  end)

  -- Read output and update progress in real-time
  vim.loop.read_start(stdout, function(_, data)
    process_output(data)
  end)
  vim.loop.read_start(stderr, function(_, data)
    process_output(data)
  end)
end

-- Auto-run relevant tests on save
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = '*.go',
  callback = run_relevant_go_test,
})
