#!/bin/bash

set -e

echo "🔗 Linking dotfiles into \$HOME..."

link() {
  src="$PWD/$1"
  dest="$HOME/.$2"
  ln -sf "$src" "$dest"
  echo "✅ Linked $dest → $src"
}

# Files
link zshrc zshrc
link wezterm.lua wezterm.lua
link gitconfig gitconfig
link skhdrc skhdrc
link yabairc yabairc
link starship.toml config/starship.toml  # symlink into ~/.config/starship.toml
link restart-wm.sh restart-wm.sh

# Folders
ln -sfn "$PWD/nvim" "$HOME/.config/nvim"
ln -sfn "$PWD/btop" "$HOME/.config/btop"
ln -sfn "$PWD/espanso" "$HOME/.config/espanso"
ln -sfn "$PWD/sketchybar" "$HOME/.config/sketchybar"
ln -sfn "$PWD/karabiner" "$HOME/.config/karabiner"
ln -sfn "$PWD/lnav" "$HOME/.config/lnav"
ln -sfn "$PWD/gh" "$HOME/.config/gh"
ln -sfn "$PWD/raycast" "$HOME/.config/raycast"
ln -sfn "$PWD/plugins" "$HOME/.config/plugins"

echo "✨ All symlinks created!"
