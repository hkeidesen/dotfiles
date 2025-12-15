-- lua/plugin/findAndRunGoTests.lua

local function find_test_file()
  local current_file = vim.fn.expand("%:p")
  
  -- Skip if no file or not a regular file
  if current_file == "" or vim.fn.filereadable(current_file) == 0 then
    return nil
  end
  
  local file_dir = vim.fn.fnamemodify(current_file, ":h")
  
  -- Check if directory exists
  if vim.fn.isdirectory(file_dir) == 0 then
    return nil
  end

  -- Look for any *_test.go or *test.go files in the same directory as the current file
  local test_files = {}
  local ok, files = pcall(vim.fn.readdir, file_dir)
  if not ok or not files then
    return nil
  end
  
  for _, file in ipairs(files) do
    if file:match("_test%.go$") or file:match("test%.go$") then
      table.insert(test_files, file_dir .. "/" .. file)
    end
  end

  -- Return the first test file found, or nil if none exist
  if #test_files > 0 then
    return test_files[1]
  end

  return nil
end

local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function run_relevant_go_test()
  -- Skip if buffer doesn't have a valid file path
  local current_file = vim.fn.expand("%:p")
  if current_file == "" or vim.fn.filereadable(current_file) == 0 then
    return
  end
  
  local test_file = find_test_file()

  if not test_file then
    vim.g.go_test_status = "🚨 No matching test file"
    vim.schedule(function()
      vim.cmd("redrawstatus")
    end)
    return
  end

  local file_dir = vim.fn.fnamemodify(test_file, ":h")
  local total_tests, running_tests, failed_tests = 0, 0, 0
  local is_running = true
  local spinner_index = 1
  local build_failed = false
  local compilation_errors = {}
  local start_time = os.time()

  local function update_spinner()
    if not is_running then
      return
    end

    -- Check for timeout after 10 seconds
    if os.time() - start_time > 10 then
      vim.g.go_test_status = "⏱️ Test timeout"
      is_running = false
      return
    end

    spinner_index = (spinner_index % #spinners) + 1
    vim.g.go_test_status = string.format(
      "%s Running... %d/%d | 🔥 %d failed",
      spinners[spinner_index],
      running_tests,
      total_tests,
      failed_tests
    )

    vim.schedule(function()
      vim.cmd("redrawstatus")
    end)

    vim.defer_fn(update_spinner, 100)
  end

  update_spinner()

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  local function process_output(data)
    if not data then
      return
    end

    for line in data:gmatch("[^\r\n]+") do
      -- Check for compilation errors
      if line:match("%.go:%d+:%d+:") then
        build_failed = true
        table.insert(compilation_errors, line)
      end

      -- Check for build failed indicator
      if line:match("%[build failed%]") then
        build_failed = true
      end

      -- Go test output patterns (only count if no build failure)
      if not build_failed then
        -- "=== RUN   TestFunctionName"
        if line:match("^=== RUN") then
          total_tests = total_tests + 1
          running_tests = running_tests + 1
        -- "--- FAIL: TestFunctionName"
        elseif line:match("^--- FAIL") then
          failed_tests = failed_tests + 1
        -- "--- PASS: TestFunctionName"
        elseif line:match("^--- PASS") then
          running_tests = running_tests - 1
        end
      end

      vim.g.go_test_status = string.format(
        "%s Running... %d/%d | 🔥 %d failed",
        spinners[spinner_index],
        running_tests,
        total_tests,
        failed_tests
      )

      vim.schedule(function()
        vim.cmd("redrawstatus")
      end)
    end
  end

  local handle
  handle = vim.loop.spawn("go", {
    args = { "test", "-v", "." },
    cwd = file_dir,
    stdio = { nil, stdout, stderr },
  }, function(code)
    is_running = false
    stdout:close()
    stderr:close()
    handle:close()

    vim.schedule(function()
      if build_failed then
        if #compilation_errors > 0 then
          vim.g.go_test_status = string.format("🏗️ Build failed: %d error(s)", #compilation_errors)
          -- Print first few errors for visibility
          for i = 1, math.min(3, #compilation_errors) do
            print("  " .. compilation_errors[i])
          end
        else
          vim.g.go_test_status = "🏗️ Build failed"
        end
      elseif total_tests > 0 then
        if failed_tests > 0 then
          vim.g.go_test_status = string.format("🔥 %d/%d failed", failed_tests, total_tests)
        else
          vim.g.go_test_status = string.format("✅ %d/%d passed", total_tests, total_tests)
        end
      else
        vim.g.go_test_status = "❌ No tests detected"
      end
      vim.cmd("redrawstatus")
    end)
  end)

  vim.loop.read_start(stdout, function(_, data)
    process_output(data)
  end)

  vim.loop.read_start(stderr, function(_, data)
    process_output(data)
  end)
end

-- Auto-run relevant tests on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.go",
  callback = function()
    pcall(run_relevant_go_test)
  end,
})

-- Clear test status when buffer changes
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*.go",
  callback = function()
    pcall(function()
      -- Only clear if it's a real file
      if vim.bo.buftype == "" and vim.fn.filereadable(vim.fn.expand("%")) == 1 then
        vim.g.go_test_status = ""
        vim.cmd("redrawstatus")
      end
    end)
  end,
})
