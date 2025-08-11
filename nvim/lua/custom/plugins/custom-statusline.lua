return {
  {
    -- Local statusline plugin
    name = "custom-statusline",
    dir = vim.fn.stdpath("config"),
    dependencies = { "echasnovski/mini.nvim" },
    config = function()
    local M = {}

    -- Neovim APIs
    local api, fn, bo = vim.api, vim.fn, vim.bo
    local get_opt = api.nvim_get_option_value

    -- Icon providers
    local has_mini_icons, mini_icons = pcall(require, "mini.icons")

    -- ##################################################################
    -- START: Re-implementation of the 'tools' module from the source
    -- ##################################################################

    -- Helper function to create highlighted strings for the statusline
    local function hl_str(group, str)
      return string.format("%%#%s#%s%%*", group, str)
    end

    -- Helper to escape strings for use in patterns
    local function esc_str(str)
      return str:gsub("([%(%)%%%+%-%*%?%[%]%^%$])", "%%%1")
    end

    -- Git utility: Get the root of the git repository
    local function get_path_root(path)
      local dir = fn.fnamemodify(path, ":h")
      if dir == "" or dir == "." then
        dir = fn.getcwd()
      end
      local git_root = fn.systemlist("cd " .. fn.shellescape(dir) .. " && git rev-parse --show-toplevel 2>/dev/null")[1]
      return git_root and git_root ~= "" and git_root or nil
    end

    -- Git utility: Get the current git branch
    local function get_git_branch(root)
      if not root then return nil end
      local branch = fn.systemlist("cd " .. fn.shellescape(root) .. " && git branch --show-current 2>/dev/null")[1]
      return branch and branch ~= "" and branch or nil
    end

    -- Git utility: Get the remote name (simplified to repo name)
    local function get_git_remote_name(root)
      if not root then return nil end
      local remote = fn.systemlist("cd " .. fn.shellescape(root) .. " && git remote get-url origin 2>/dev/null")[1]
      if remote and remote ~= "" then
        return remote:match("([^/]+)%.git$") or remote:match("([^/]+)$")
      end
      return nil
    end

    -- Check if diagnostics are available and enabled for the buffer
    local function diagnostics_available()
      local bufnr = api.nvim_get_current_buf()
      if vim.diagnostic.is_enabled then
        return vim.diagnostic.is_enabled({ bufnr = bufnr })
      end
      return #vim.diagnostic.get(bufnr) > 0
    end

    -- Format a number with comma separators
    local function group_number(num, sep)
      sep = sep or ","
      local str = tostring(num)
      return str:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse():gsub("^" .. sep, "")
    end

    -- Filetypes where word count is more useful than line count
    local nonprog_modes = {
      [""] = true, text = true, markdown = true, help = true,
      man = true, gitcommit = true, gitrebase = true,
    }

    -- ##################################################################
    -- END: Re-implementation of the 'tools' module
    -- ##################################################################

    -- Define icons (imitating tools.ui.icons)
    local icons = {
      branch = "", -- Git branch icon
      node = "",   -- Generic file icon
      document = "", -- Document icon for fileinfo
      bullet = "●",
      lock = "",
      error = "",
      warning = "",
    }

    -- Define highlight groups and their associated icons, like the source
    local HL = {
      branch = { "DiagnosticOk", icons.branch },
      file = { "NonText", icons.node },
      fileinfo = { "Function", icons.document },
      nomodifiable = { "DiagnosticWarn", icons.bullet },
      modified = { "DiagnosticError", icons.bullet },
      readonly = { "DiagnosticWarn", icons.lock },
      error = { "DiagnosticError", icons.error },
      warn = { "DiagnosticWarn", icons.warning },
      visual = { "DiagnosticInfo", "‹› " },
    }

    -- Create highlighted icon strings
    local ICON = {}
    for k, v in pairs(HL) do
      ICON[k] = hl_str(v[1], v[2])
    end

    -- Define the order of statusline components, exactly as in the source
    local ORDER = {
      "pad", "path", "venv", "mod", "ro", "sep",
      "diag", "fileinfo", "pad", "scrollbar", "pad",
    }

    -- Define constants, exactly as in the source
    local PAD = " "
    local SEP = "%="
    local SBAR = { "▔", "🮂", "🬂", "🮃", "▀", "▄", "▃", "🬭", "▂", " " }

    -- utilities -----------------------------------------
    -- Concat function, exactly as in the source
    local function concat(parts)
      local out, i = {}, 1
      for _, k in ipairs(ORDER) do
        local v = parts[k]
        if v and v ~= "" then
          out[i] = v
          i = i + 1
        end
      end
      return table.concat(out, " ")
    end

    -- path and git info -----------------------------------------
    -- path_widget, adapted to use our local helpers and mini.icons
    local function path_widget(root, fname)
      local file_name = fn.fnamemodify(fname, ":t")

      local path, icon, hl
      if has_mini_icons then
        icon, hl = mini_icons.get("file", file_name)
      else
        icon = "" -- Fallback icon
        hl = "Normal"
      end

      if fname == "" then file_name = "[No Name]" end
      path = hl_str(hl, icon) .. " " .. file_name

      if bo.buftype == "help" then return path end

      local dir_path = fn.fnamemodify(fname, ":h") .. "/"
      if dir_path == "./" then dir_path = "" end

      local remote = get_git_remote_name(root)
      local branch = get_git_branch(root)
      local repo_info = ""
      if remote and branch and root then
        -- Make path relative to git root, like the source
        if fname:sub(1, #root) == root then
          dir_path = fname:sub(#root + 2)
          dir_path = fn.fnamemodify(dir_path, ":h") .. "/"
          if dir_path == "./" then dir_path = "" end
        end
        repo_info = string.format("%s %s @ %s ", ICON.branch, remote, branch)
      end

      local win_w = api.nvim_win_get_width(0)
      local need = #repo_info + #dir_path + #path
      if win_w < need + 5 then dir_path = "" end
      if win_w < need - #dir_path then repo_info = "" end

      return repo_info .. dir_path .. path .. " "
    end

    -- diagnostics ---------------------------------------------
    -- diagnostics_widget, adapted for Neovim 0.11.3 but matching source logic
    local function diagnostics_widget()
      if not diagnostics_available() then return "" end
      -- Using numeric indices to match the source code
      local diag_count = vim.diagnostic.count()
      local err = string.format("%-3d", diag_count[1] or 0)
      local warn = string.format("%-3d", diag_count[2] or 0)

      if (diag_count[1] or 0) == 0 and (diag_count[2] or 0) == 0 then
        return ""
      end

      return string.format(
        "%s %s  %s %s  ",
        ICON.error,
        hl_str("DiagnosticError", err),
        ICON.warn,
        hl_str("DiagnosticWarn", warn)
      )
    end

    -- file/selection info -------------------------------------
    -- fileinfo_widget, adapted to use our local helpers
    local function fileinfo_widget()
      local ft = get_opt("filetype", {})
      local lines = group_number(api.nvim_buf_line_count(0))
      local str = ICON.fileinfo .. " "

      if not nonprog_modes[ft] then
        return str .. string.format("%3s lines", lines)
      end

      local wc = fn.wordcount()
      if not wc.visual_words or wc.visual_words == 0 then
        return str
          .. string.format(
            "%3s lines  %3s words",
            lines,
            group_number(wc.words)
          )
      end

      local vlines = math.abs(fn.line(".") - fn.line("v")) + 1
      return str
        .. string.format(
          "%3s lines %3s words  %3s chars",
          group_number(vlines),
          group_number(wc.visual_words),
          group_number(wc.visual_chars)
        )
    end

    -- python venv ---------------------------------------------
    -- venv_widget, exactly as in the source
    local function venv_widget()
      if bo.filetype ~= "python" then return "" end
      local env = vim.env.VIRTUAL_ENV

      local str
      if env and env ~= "" then
        str = string.format("[.venv: %s]  ", fn.fnamemodify(env, ":t"))
        return hl_str("Comment", str)
      end
      env = vim.env.CONDA_DEFAULT_ENV
      if env and env ~= "" then
        str = string.format("[conda: %s]  ", env)
        return hl_str("Comment", str)
      end
      return hl_str("Comment", "[no venv]")
    end

    -- scrollbar ---------------------------------------------
    -- scrollbar_widget, exactly as in the source
    local function scrollbar_widget()
      local cur = api.nvim_win_get_cursor(0)[1]
      local total = api.nvim_buf_line_count(0)
      if total == 0 then return "" end
      local idx = math.floor((cur - 1) / total * #SBAR) + 1
      return hl_str("Substitute", SBAR[idx]:rep(2))
    end

    -- render ---------------------------------------------
    -- M.render, adapted to use our local get_path_root
    function M.render()
      local fname = api.nvim_buf_get_name(0)
      local root = (bo.buftype == "" and get_path_root(fname)) or nil
      if bo.buftype ~= "" and bo.buftype ~= "help" then fname = bo.filetype end

      local buf = api.nvim_win_get_buf(vim.g.statusline_winid or 0)

      local parts = {
        pad = PAD,
        path = path_widget(root, fname),
        venv = venv_widget(),
        mod = get_opt("modifiable", { buf = buf })
            and (get_opt("modified", { buf = buf }) and ICON.modified or " ")
          or ICON.nomodifiable,
        ro = get_opt("readonly", { buf = buf }) and ICON.readonly or "",
        sep = SEP,
        diag = diagnostics_widget(),
        fileinfo = fileinfo_widget(),
        scrollbar = scrollbar_widget(),
      }

      return concat(parts)
    end

    -- Make the module available globally for the statusline expression
    _G.custom_statusline_module = M
    vim.o.statusline = "%!v:lua.custom_statusline_module.render()"

    -- Ensure statusline has a transparent background
    vim.cmd([[
      highlight StatusLine guibg=NONE ctermbg=NONE
      highlight StatusLineNC guibg=NONE ctermbg=NONE
    ]])
  end,
  },
}
