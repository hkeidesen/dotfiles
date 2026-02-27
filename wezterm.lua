local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font config
config.font = wezterm.font("Hack Nerd Font Mono")
config.font = wezterm.font_with_fallback({
  "Hack Nerd Font Mono",
  "Symbols Nerd Font",
  "Apple Color Emoji",
})
config.color_scheme = "Ayu Mirage"
-- config.color_scheme = "rose-pine"
-- config.color_scheme = 'Horizon Dark (base16)'
config.font_size = 15.0
config.cell_width = 1.35
config.line_height = 1.50
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20

config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_padding = {
  left = "1cell",
  right = "0cell",
  top = "0cell",
}
config.native_macos_fullscreen_mode = true

config.adjust_window_size_when_changing_font_size = false
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 10000

config.send_composed_key_when_left_alt_is_pressed = true   -- typing: { } [ ] | etc.
config.send_composed_key_when_right_alt_is_pressed = false  -- sends Meta for tmux (M-a, M-b…)

-- Right-opt+hjkl (remapped to F13-F16 by Karabiner) → Meta-hjkl for tmux pane nav
local act = wezterm.action
config.keys = {
  { key = "F13", action = act.SendString("\x1bh") },
  { key = "F14", action = act.SendString("\x1bj") },
  { key = "F15", action = act.SendString("\x1bk") },
  { key = "F16", action = act.SendString("\x1bl") },
}

return config
