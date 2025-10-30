-- lua/custom/plugins/neotest.lua
-- Safe, self-contained neotest setup that won't explode if required early.

local M = {}
local did_setup = false

-- ---------- Small utilities ----------
local function exists(p)
  return p and vim.loop.fs_stat(p) ~= nil
end
local function path(...)
  return table.concat({ ... }, "/")
end

local function find_root(p)
  local uv = vim.loop
  local dir = p
  if exists(dir) and uv.fs_stat(dir).type == "file" then
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  local markers = {
    "vitest.config.ts",
    "vitest.config.mts",
    "vitest.config.js",
    "vitest.config.mjs",
    "vite.config.ts",
    "vite.config.mts",
    "package.json",
    "pnpm-workspace.yaml",
  }
  while dir and dir ~= "/" do
    for _, m in ipairs(markers) do
      if exists(path(dir, m)) then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return vim.loop.cwd()
end

-- Search rules:
-- 1) same file if it's already a test
-- 2) same dir: Component.test/spec.(tsx|ts)
-- 3) same dir __tests__/Component.(test|spec).(tsx|ts) and bare Component.tsx
-- 4) one dir up __tests__/Component.(test|spec).(tsx|ts) and bare Component.tsx
local function find_matching_test(file_abs)
  if not file_abs or file_abs == "" then
    return nil
  end
  if file_abs:find("/node_modules/") then
    return nil
  end
  if not (file_abs:match("%.tsx$") or file_abs:match("%.ts$")) then
    return nil
  end

  if file_abs:match("%.test%.[tj]sx?$") or file_abs:match("%.spec%.[tj]sx?$") then
    return file_abs
  end

  local dir = vim.fn.fnamemodify(file_abs, ":h")
  local base = vim.fn.fnamemodify(file_abs, ":t:r")
  local pdir = vim.fn.fnamemodify(dir, ":h")

  local candidates = {}
  -- same dir: component.test/spec
  for _, ext in ipairs({ "test.tsx", "spec.tsx", "test.ts", "spec.ts" }) do
    table.insert(candidates, path(dir, base .. "." .. ext))
  end
  -- same dir __tests__/
  for _, name in ipairs({
    base .. ".test.tsx",
    base .. ".spec.tsx",
    base .. ".test.ts",
    base .. ".spec.ts",
    base .. ".tsx",
  }) do
    table.insert(candidates, path(dir, "__tests__", name))
  end
  -- one dir up __tests__/
  for _, name in ipairs({
    base .. ".test.tsx",
    base .. ".spec.tsx",
    base .. ".test.ts",
    base .. ".spec.ts",
    base .. ".tsx",
  }) do
    table.insert(candidates, path(pdir, "__tests__", name))
  end

  for _, p in ipairs(candidates) do
    if exists(p) then
      return p
    end
  end
  return nil
end

-- ---------- Real setup (runs once when plugins are available) ----------
local function do_setup()
  if did_setup then
    return
  end

  local ok_neotest, neotest = pcall(require, "neotest")
  if not ok_neotest then
    return
  end
  local ok_vitest, neotest_vitest = pcall(require, "neotest-vitest")
  if not ok_vitest then
    vim.notify("neotest: 'neotest-vitest' adapter not found", vim.log.levels.ERROR)
    return
  end

  neotest.setup({
    adapters = {
      neotest_vitest({
        vitestCommand = "pnpm vitest", -- change if you use npm/yarn
        cwd = function(p)
          return find_root(p)
        end,
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= "dist" and name ~= "build"
        end,
      }),
    },
    discovery = { enabled = true },
    diagnostic = { enabled = true },
    quickfix = { enabled = true, open = false },
    running = { concurrent = true },
  })

  -- Keymaps
  vim.keymap.set("n", "<leader>tf", function()
    neotest.run.run(vim.fn.expand("%"))
  end, { desc = "Neotest: run file" })
  vim.keymap.set("n", "<leader>tn", neotest.run.run, { desc = "Neotest: run nearest" })
  vim.keymap.set("n", "<leader>tw", function()
    neotest.watch.watch(vim.fn.expand("%"))
  end, { desc = "Neotest: watch file" })
  vim.keymap.set("n", "<leader>ts", neotest.summary.toggle, { desc = "Neotest: summary" })
  vim.keymap.set("n", "<leader>to", function()
    neotest.output.open({ enter = true, auto_close = true })
  end, { desc = "Neotest: output" })
  vim.keymap.set("n", "<leader>tS", neotest.run.stop, { desc = "Neotest: stop" })

  -- Auto-run/watch on open & save
  vim.g.neotest_autorun = true
  vim.api.nvim_create_user_command("NeotestAutoRunToggle", function()
    vim.g.neotest_autorun = not vim.g.neotest_autorun
    vim.notify("Neotest autorun: " .. tostring(vim.g.neotest_autorun))
  end, {})

  local watched = {}
  local function autowatch_current()
    if not vim.g.neotest_autorun then
      return
    end
    local file = vim.fn.expand("%:p")
    local target = find_matching_test(file)
    if target then
      if not watched[target] then
        neotest.watch.watch(target)
        watched[target] = true
        neotest.run.run(target) -- immediate feedback on first watch
      end
    else
      vim.notify(
        ("No tests found for %s"):format(vim.fn.fnamemodify(file, ":t")),
        vim.log.levels.WARN,
        { title = "neotest" }
      )
    end
  end

  vim.api.nvim_create_augroup("NeotestAutoWatch", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
    group = "NeotestAutoWatch",
    pattern = { "*.ts", "*.tsx" },
    callback = autowatch_current,
  })

  did_setup = true
end

-- ---------- Defer until plugins are actually loaded ----------
-- Works with lazy.nvim (VeryLazy). Falls back to VimEnter + short retry if not.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    vim.schedule(do_setup)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    -- If VeryLazy never fired (not using lazy.nvim), try a few times briefly.
    if did_setup then
      return
    end
    local tries = 20
    local timer = vim.loop.new_timer()
    timer:start(50, 50, function()
      if did_setup then
        timer:stop()
        timer:close()
        return
      end
      local ok = pcall(do_setup)
      tries = tries - 1
      if ok or tries <= 0 then
        timer:stop()
        timer:close()
        if not ok then
          vim.schedule(function()
            vim.notify("neotest: plugin not found on runtimepath", vim.log.levels.WARN)
          end)
        end
      end
    end)
  end,
})

return M
