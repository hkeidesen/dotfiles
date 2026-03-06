local timer = nil
local last_heartbeat = 0
local last_activity = 0
local INTERVAL_MS = 2 * 60 * 1000

local sentinels = { "README.md", "pyproject.toml", "package.json", "go.mod", "Cargo.toml" }

local function get_project_entity()
  local cwd = vim.fn.getcwd()
  for _, name in ipairs(sentinels) do
    local path = cwd .. "/" .. name
    if vim.uv.fs_stat(path) then
      return path
    end
  end
  return cwd
end

local function send_heartbeat()
  local entity = get_project_entity()
  local v = vim.version()
  vim.system({
    "wakatime-cli",
    "--entity", entity,
    "--entity-type", "app",
    "--category", "coding",
    "--project", vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
    "--plugin", "neovim/" .. v.major .. "." .. v.minor .. " wakatime-terminal/0.1",
  }, { detach = true })
  last_heartbeat = vim.uv.now()
end

--- Send heartbeat immediately if cooldown has elapsed.
local function on_activity()
  last_activity = vim.uv.now()
  if last_activity - last_heartbeat >= INTERVAL_MS then
    send_heartbeat()
  end
end

--- Timer callback: send heartbeat only if there was activity since the last one.
local function on_timer()
  if last_activity > last_heartbeat then
    send_heartbeat()
  end
end

local function start_timer()
  if timer then return end
  timer = vim.uv.new_timer()
  on_activity()
  timer:start(INTERVAL_MS, INTERVAL_MS, vim.schedule_wrap(on_timer))
end

local function stop_timer()
  if not timer then return end
  timer:stop()
  timer:close()
  timer = nil
end

local augroup = vim.api.nvim_create_augroup("WakatimeTerminal", { clear = true })

-- Activity signals: user enters terminal mode, terminal sends escape sequences
vim.api.nvim_create_autocmd({ "TermEnter", "TermRequest" }, {
  group = augroup,
  callback = on_activity,
})

-- Start timer when entering a terminal buffer
vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
  group = augroup,
  callback = function()
    if vim.bo.buftype == "terminal" then
      start_timer()
    end
  end,
})

-- Stop timer when leaving a terminal buffer
vim.api.nvim_create_autocmd("BufLeave", {
  group = augroup,
  callback = function()
    if vim.bo.buftype == "terminal" then
      stop_timer()
    end
  end,
})
