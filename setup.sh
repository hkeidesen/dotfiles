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

# App watchdogs via launchd
for watchdog in raycast paste secure-input; do
  PLIST_SRC="$DOTFILES/launchd/com.user.${watchdog}-watchdog.plist"
  PLIST_DEST="$HOME/Library/LaunchAgents/com.user.${watchdog}-watchdog.plist"
  if [ ! -f "$PLIST_DEST" ] || ! cmp -s "$PLIST_SRC" "$PLIST_DEST"; then
    cp "$PLIST_SRC" "$PLIST_DEST"
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
    launchctl load "$PLIST_DEST"
    echo "${watchdog} watchdog loaded"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────
echo ""
echo "Setup complete!"
echo "  Homebrew packages: installed via Brewfile"
echo "  Oh My Tmux:        ~/.tmux"
echo "  Symlinks:          created by link.sh"
echo "  Neovim plugins:    synced via Lazy"
echo "  Default shell:     zsh"
echo "  Services:          Raycast"
