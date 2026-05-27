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
  local failed_test_names = {}
  local failing_package = nil
  local current_failing_test = nil
  local failure_output = {} -- map of test name -> {lines}
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
      -- Check for compilation errors (file:line:col: message)
      if line:match("%.go:%d+:%d+:") then
        build_failed = true
        table.insert(compilation_errors, line)
      end

      -- Check for build failed indicator + capture which package
      local bf_pkg = line:match("^FAIL%s+(%S+)%s+%[build failed%]")
      if bf_pkg then
        build_failed = true
        failing_package = bf_pkg
      elseif line:match("%[build failed%]") then
        build_failed = true
      end

      -- Go test output patterns (only count if no build failure)
      if not build_failed then
        local fail_name = line:match("^%s*%-%-%- FAIL:%s+(%S+)")
        if line:match("^=== RUN") then
          total_tests = total_tests + 1
          running_tests = running_tests + 1
          current_failing_test = nil
        elseif fail_name then
          failed_tests = failed_tests + 1
          table.insert(failed_test_names, fail_name)
          current_failing_test = fail_name
          failure_output[fail_name] = failure_output[fail_name] or {}
        elseif line:match("^%s*%-%-%- PASS") then
          running_tests = running_tests - 1
          current_failing_test = nil
        elseif current_failing_test then
          -- Indented lines after --- FAIL belong to the failing test
          local body = line:match("^%s+(.+)$")
          if body and #failure_output[current_failing_test] < 5 then
            table.insert(failure_output[current_failing_test], body)
          end
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
    if not stdout:is_closing() then
      stdout:close()
    end
    if not stderr:is_closing() then
      stderr:close()
    end
    if not handle:is_closing() then
      handle:close()
    end

    -- If this run was cancelled mid-flight, the module refs already point at a
    -- newer run (or nil). Bail without notifying so we don't double-fire.
    local was_active = (current_handle == handle)
    if was_active then
      current_handle = nil
      current_stdout = nil
      current_stderr = nil
      current_is_running = false
    end

    if not was_active then
      return
    end

    vim.schedule(function()
      if build_failed then
        local err_count = #compilation_errors
        vim.g.go_test_status = string.format("🏗️ Build failed: %d error(s)", err_count)

        local lines = {}
        if failing_package then
          table.insert(lines, "📦 " .. failing_package)
        end
        local show = math.min(4, err_count)
        for i = 1, show do
          table.insert(lines, "• " .. compilation_errors[i])
        end
        if err_count > show then
          table.insert(lines, string.format("…and %d more", err_count - show))
        end
        if #lines == 0 then
          table.insert(lines, "Build failed (no diagnostic lines captured)")
        end

        Snacks.notify(table.concat(lines, "\n"), { level = "error", title = "Go build failed" })
      elseif total_tests > 0 then
        if failed_tests > 0 then
          vim.g.go_test_status = string.format("🔥 %d/%d failed", failed_tests, total_tests)

          local lines = {}
          local show_tests = math.min(3, #failed_test_names)
          for i = 1, show_tests do
            local name = failed_test_names[i]
            table.insert(lines, "✗ " .. name)
            local out = failure_output[name] or {}
            for j = 1, math.min(2, #out) do
              table.insert(lines, "    " .. out[j])
            end
          end
          if #failed_test_names > show_tests then
            table.insert(lines, string.format("…and %d more", #failed_test_names - show_tests))
          end

          Snacks.notify(table.concat(lines, "\n"), { level = "warn", title = "Go tests failed" })
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

-- Augroup with clear=true so re-sourcing this file (lazy.nvim reload, :luafile,
-- accidental double-load) does not stack duplicate BufWritePost listeners —
-- previously, every extra registration triggered a parallel `go test` run and a
-- duplicate Snacks notification on save.
local augroup = vim.api.nvim_create_augroup("FindAndRunGoTests", { clear = true })

-- Auto-run relevant tests on save (debounced)
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
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
  group = augroup,
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
