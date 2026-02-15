local function open_plan_float(filepath)
  local lines = vim.fn.readfile(filepath)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.bo[buf].filetype = "markdown"
end

local function get_plans_sorted()
  local files = vim.fn.glob(vim.fn.expand("~/.claude/plans/*.md"), false, true)
  table.sort(files, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  return files
end

vim.keymap.set("n", "<leader>gp", function()
  local files = get_plans_sorted()
  if #files == 0 then
    print("No Claude plan found")
    return
  end
  open_plan_float(files[1])
end, { desc = "View most recent Claude plan (floating)" })

vim.keymap.set("n", "<leader>gP", function()
  local files = get_plans_sorted()
  if #files == 0 then
    print("No Claude plan found")
    return
  end

  local items = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t")
    local mtime = vim.fn.strftime("%Y-%m-%d %H:%M", vim.fn.getftime(f))
    table.insert(items, { display = name .. " — " .. mtime, path = f })
  end

  vim.ui.select(items, {
    prompt = "Select Claude plan:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      open_plan_float(choice.path)
    end
  end)
end, { desc = "List all Claude plans (floating)" })
