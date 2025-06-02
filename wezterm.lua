local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Font config
config.font = wezterm.font("Hack Nerd Font Propo")
-- config.color_scheme = "Ayu Mirage"
config.color_scheme = "rose-pine"
config.font_size = 15.0
config.cell_width = 1.20
config.line_height = 1.10
-- config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

-- Appearance
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_padding = {
  left = 6,
  right = 6,
  top = 4,
  bottom = 4,
}
-- config.window_background_opacity = 0.95
config.native_macos_fullscreen_mode = true

-- Behavior
config.adjust_window_size_when_changing_font_size = false
config.hide_mouse_cursor_when_typing = true
config.scrollback_lines = 10000
-- Optional: Auto-start tmux on launch
-- config.default_prog = { "/opt/homebrew/bin/tmux" }

config.send_composed_key_when_left_alt_is_pressed = true
return config
