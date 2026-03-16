#!/bin/bash

echo "Restarting yabai..."
yabai --stop-service
sleep 1
yabai --start-service

echo "Restarting skhd..."
skhd --stop-service
sleep 1
skhd --start-service

echo "✅ Window manager restarted."
sleep 1 && ~/dotfiles/scripts/yabai-center-wezterm.sh

