#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Skhd Cheatsheet
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon ⌨️
# @raycast.packageName skhd

# Documentation:
# @raycast.description Show all skhd keybindings from skhdrc

SKHDRC="$HOME/dotfiles/skhdrc"

awk '
  BEGIN { after_blank = 1 }
  /^[[:space:]]*$/ { after_blank = 1; next }
  /^#/ {
    if (after_blank) {
      section = $0
      sub(/^# ?/, "", section)
      printf "\n%s\n", section
      dashes = ""
      for (i = 0; i < length(section); i++) dashes = dashes "-"
      print dashes
    }
    after_blank = 0
    next
  }
  {
    after_blank = 0
    if (index($0, " : ") == 0) next
    split($0, parts, " : ")
    key = parts[1]
    cmd = parts[2]
    gsub(/yabai -m /, "", cmd)
    gsub(/^[ \t]+|[ \t]+$/, "", key)
    printf "  %-26s %s\n", key, cmd
  }
' "$SKHDRC"
