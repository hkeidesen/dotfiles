vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor_position", { clear = true }),
  callback = function(args)
    -- OPTIMIZATION 1: Skip special buffers immediately
    local buftype = vim.bo[args.buf].buftype
    if buftype ~= "" then
      return
    end

    -- OPTIMIZATION 2: Skip if no filename
    local filename = vim.api.nvim_buf_get_name(args.buf)
    if filename == "" then
      return
    end
    if filename:match("^oil://") then
      return
    end

    -- OPTIMIZATION 3: Skip gitcommit and other special filetypes
    local exclude_ft = { "gitcommit", "gitrebase", "svn", "hgcommit" }
    if vim.tbl_contains(exclude_ft, vim.bo[args.buf].filetype) then
      return
    end

    -- OPTIMIZATION 4: Use the correct buffer number (not 0)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')

    -- OPTIMIZATION 5: Early return if mark is invalid
    if not mark or mark[1] <= 0 then
      return
    end

    local lcount = vim.api.nvim_buf_line_count(args.buf)

    -- OPTIMIZATION 6: Validate mark is within bounds
    if mark[1] > lcount then
      return
    end

    -- OPTIMIZATION 7: Use pcall but don't ignore errors silently
    local ok, err = pcall(vim.api.nvim_win_set_cursor, 0, mark)
    if not ok then
      if not err:match("Invalid window id") then
        vim.notify("Failed to restore cursor: " .. err, vim.log.levels.WARN)
      end
    end
  end,
})
