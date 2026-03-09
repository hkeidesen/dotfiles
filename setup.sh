#!/bin/bash
#
# Idempotent macOS setup — run from ~/dotfiles
#

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES"

# ── Homebrew ──────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [ -f "$DOTFILES/Brewfile" ]; then
  echo "Running brew bundle..."
  brew bundle --file="$DOTFILES/Brewfile"
fi

# ── Oh My Tmux ────────────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux" ]; then
  echo "Cloning Oh My Tmux..."
  git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -sf "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
else
  echo "Oh My Tmux already installed"
fi

# ── Symlinks ──────────────────────────────────────────────────────────
echo "Creating symlinks..."
bash "$DOTFILES/link.sh"

# ── Neovim plugins ────────────────────────────────────────────────────
if command -v nvim &>/dev/null; then
  echo "Syncing Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa
fi

# ── Default shell ─────────────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# ── Services & Login Items ─────────────────────────────────────────────
echo "Starting services..."

# yabai / skhd via LaunchAgents (idempotent)
if ! launchctl list 2>/dev/null | grep -q "com.koekeishiya.yabai"; then
  yabai --start-service
fi
if ! launchctl list 2>/dev/null | grep -q "com.koekeishiya.skhd"; then
  skhd --start-service
fi

# Raycast as login item (idempotent)
if [ -d "/Applications/Raycast.app" ]; then
  if ! osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null | grep -q "Raycast"; then
    osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Raycast.app", hidden:false}'
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "Setup complete!"
echo "  Homebrew packages: installed via Brewfile"
echo "  Oh My Tmux:        ~/.tmux"
echo "  Symlinks:          created by link.sh"
echo "  Neovim plugins:    synced via Lazy"
echo "  Default shell:     zsh"
echo "  Services:          yabai, skhd, Raycast"
