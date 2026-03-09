#!/bin/bash

set -e

echo "🔗 Linking dotfiles into \$HOME..."

rm -f "$HOME/.config/espanso"  # remove stale symlink if present
mkdir -p "$HOME/.config/espanso"

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
link tmux.conf.local tmux.conf.local
link zprofile zprofile
link gitignore_global gitignore
link espanso.yml config/espanso/match/base.yml

# Non-dotfiles (no leading dot)
ln -sf "$PWD/Brewfile" "$HOME/Brewfile"

# Folders
ln -sfn "$PWD/nvim" "$HOME/.config/nvim"
ln -sfn "$PWD/btop" "$HOME/.config/btop"
ln -sfn "$PWD/sketchybar" "$HOME/.config/sketchybar"
ln -sfn "$PWD/karabiner" "$HOME/.config/karabiner"
ln -sfn "$PWD/lnav" "$HOME/.config/lnav"
ln -sfn "$PWD/gh" "$HOME/.config/gh"
ln -sfn "$PWD/raycast" "$HOME/.config/raycast"
ln -sfn "$PWD/broot" "$HOME/.config/broot"

echo "✨ All symlinks created!"
