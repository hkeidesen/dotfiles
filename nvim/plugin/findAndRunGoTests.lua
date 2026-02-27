-- plugin/findAndRunGoTests.lua

-- Module-level state for cancellation & debounce
local current_handle = nil
local current_stdout = nil
local current_stderr = nil
local current_is_running = false -- shared flag to stop the spinner
local debounce_timer = nil
local DEBOUNCE_MS = 1000

local function find_test_file()
  local current_file = vim.fn.expand("%:p")

  -- Skip if no file or not a regular file
  if current_file == "" or vim.fn.filereadable(current_file) == 0 then
    return nil
  end

  -- If we're already in a test file, return it
  if current_file:match("_test%.go$") then
    return current_file
  end

  local file_dir = vim.fn.fnamemodify(current_file, ":h")
  local file_name = vim.fn.fnamemodify(current_file, ":t")

  -- Check if directory exists
  if vim.fn.isdirectory(file_dir) == 0 then
    return nil
  end

  -- Get the base name without .go extension
  local base_name = file_name:gsub("%.go$", "")

  -- Look for the corresponding test file: <basename>_test.go
  local corresponding_test = file_dir .. "/" .. base_name .. "_test.go"

  if vim.fn.filereadable(corresponding_test) == 1 then
    return corresponding_test
  end

  -- No corresponding test file found
  return nil
end

local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- Kill the currently running test process (if any) and stop its spinner.
local function cancel_current_run()
  -- Stop the spinner of the previous run
  current_is_running = false

  if current_handle then
    -- Kill the process group so child processes (go compile, etc.) also die
    if not current_handle:is_closing() then
      current_handle:kill("sigkill")
    end
    -- The exit callback will close pipes and handle cleanup.
    -- Nil out refs so the exit callback knows it was cancelled.
    current_handle = nil
    current_stdout = nil
    current_stderr = nil
  end
end

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

  -- Cancel any in-flight run before starting a new one
  cancel_current_run()

  local file_dir = vim.fn.fnamemodify(test_file, ":h")
  local total_tests, running_tests, failed_tests = 0, 0, 0
  current_is_running = true
  local is_running_ref = true -- local ref so the spinner closure captures it
  local spinner_index = 1
  local build_failed = false
  local compilation_errors = {}
  local start_time = os.time()

  local function update_spinner()
    if not current_is_running or not is_running_ref then
      return
    end

    -- Check for timeout after 10 seconds
    if os.time() - start_time > 10 then
      vim.g.go_test_status = "⏱️ Test timeout"
      is_running_ref = false
      current_is_running = false
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
  current_stdout = stdout
  current_stderr = stderr

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
      -- No redrawstatus here — the spinner (100ms interval) picks up counter changes
    end
  end

  local handle
  handle = vim.loop.spawn("go", {
    args = { "test", "-v", "." },
    cwd = file_dir,
    stdio = { nil, stdout, stderr },
  }, function(code)
    is_running_ref = false
    current_is_running = false
    if not stdout:is_closing() then
      stdout:close()
    end
    if not stderr:is_closing() then
      stderr:close()
    end
    if not handle:is_closing() then
      handle:close()
    end
    -- Clear module refs if this is still the active run
    if current_handle == handle then
      current_handle = nil
      current_stdout = nil
      current_stderr = nil
    end

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

  current_handle = handle

  vim.loop.read_start(stdout, function(_, data)
    process_output(data)
  end)

  vim.loop.read_start(stderr, function(_, data)
    process_output(data)
  end)
end

-- Auto-run relevant tests on save (debounced)
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.go",
  callback = function()
    if debounce_timer then
      debounce_timer:stop()
      debounce_timer:close()
      debounce_timer = nil
    end
    debounce_timer = vim.uv.new_timer()
    debounce_timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
      debounce_timer:close()
      debounce_timer = nil
      pcall(run_relevant_go_test)
    end))
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
