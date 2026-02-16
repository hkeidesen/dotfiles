# ──────────────────────────────────────────────────────────────────────────────
#                      ZSH CONFIG WITH QoL IMPROVEMENTS
# ──────────────────────────────────────────────────────────────────────────────

# Uncomment both lines to measure startup time:
# zmodload zsh/zprof

# ------------------------------------------------------------------------------
# 1) PATH setup
# ------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$HOME/go/bin:$PATH"
export PATH="/Applications/Espanso.app/Contents/MacOS:$PATH"
export PATH="$PATH:/Users/hans-kristian.norum/.local/bin"
export PATH="$HOME/dotfiles/scripts:$PATH"

# Sensible locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# GPG
export GPG_TTY="$(tty)"

# Docker (Colima)
export CTOP_DOCKER_SOCKET="unix://$HOME/.colima/default/docker.sock"

# ------------------------------------------------------------------------------
# 2) Anthropic API key (lazy — only loaded when needed)
# ------------------------------------------------------------------------------
anthropic_api_key() {
  if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    export ANTHROPIC_API_KEY="$(security find-generic-password -a "$USER" -s "anthropic_api_key" -w 2>/dev/null)"
  fi
}
# Hook: load the key before any command that might need it
_maybe_load_api_key() {
  case "$1" in
    claude*|curl*api.anthropic*) anthropic_api_key ;;
  esac
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _maybe_load_api_key

# ------------------------------------------------------------------------------
# 3) Oh My Zsh
# ------------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# Vi-mode settings (before OMZ sources the plugin)
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

# Plugins — keep syntax-highlighting LAST
plugins=(
  git
  vi-mode
  virtualenv
  z
  fzf
  tmux
  autoswitch_virtualenv
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source Oh My Zsh (once!)
source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------------------
# 4) Prompt — Starship (after OMZ, once)
# ------------------------------------------------------------------------------
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ------------------------------------------------------------------------------
# 5) Node (nvm) — lazy loaded for fast startup
# ------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unset -f nvm node npm npx pnpm
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
  fi
}

nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }
pnpm() { _load_nvm; pnpm "$@"; }

# ------------------------------------------------------------------------------
# 6) fzf, zoxide, broot
# ------------------------------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

[ -f "$HOME/.config/broot/launcher/zsh/br" ] && \
  source "$HOME/.config/broot/launcher/zsh/br"

# ------------------------------------------------------------------------------
# 7) History
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ------------------------------------------------------------------------------
# 8) Shell behavior
# ------------------------------------------------------------------------------
setopt AUTO_CD
setopt CORRECT
setopt CDABLE_VARS

# ------------------------------------------------------------------------------
# 9) Completion tweaks
# ------------------------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings'     format '%B%F{yellow}%d%f%b'
zstyle ':completion:*:options'      description 'describe'

# ------------------------------------------------------------------------------
# 10) Key-bindings (after OMZ so plugins don't override)
# ------------------------------------------------------------------------------
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history

# ------------------------------------------------------------------------------
# 11) Aliases
# ------------------------------------------------------------------------------
# Git
alias gst='git status'
alias gl='git pull --rebase'
alias gp='git push'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias glg='git log --graph --oneline --decorate --all'

# Safety
alias rm='rm -i'

# Better tools
command -v lsd >/dev/null 2>&1 && alias ls="lsd"
command -v bat >/dev/null 2>&1 && alias car="bat"

# Docker
alias dps='docker ps'
alias dstop='docker stop'
alias drm='docker rm'
alias ctop='docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest'

# Misc
alias restart-wm="$HOME/restart-wm.sh"
alias timeout="gtimeout"

# ------------------------------------------------------------------------------
# 12) Functions
# ------------------------------------------------------------------------------
# Quick extract
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"   ;;
      *.tar.gz)    tar xzf "$1"   ;;
      *.bz2)       bunzip2 "$1"   ;;
      *.rar)       unrar x "$1"   ;;
      *.gz)        gunzip "$1"    ;;
      *.tar)       tar xf "$1"    ;;
      *.tbz2)      tar xjf "$1"   ;;
      *.tgz)       tar xzf "$1"   ;;
      *.zip)       unzip "$1"     ;;
      *.Z)         uncompress "$1";;
      *.7z)        7z x "$1"      ;;
      *)           echo "extract: unrecognized archive type: $1" ;;
    esac
  else
    echo "extract: '$1' is not a valid file."
  fi
}

# Devcontainer helper
dc() { devcontainer "$@" --workspace-folder "${PWD}"; }

# ------------------------------------------------------------------------------
# 13) Auto-track dotfiles (yadm) — runs in background, non-blocking
# ------------------------------------------------------------------------------
_auto_track_dotfiles() {
  if [[ -d "$HOME/.local/share/yadm/repo.git" ]]; then
    local unstaged
    unstaged=$(yadm status --porcelain | grep -cE '^\s?[MARD]')
    if (( unstaged > 0 )); then
      yadm add -u && \
      yadm commit -m "Auto-update $(date '+%Y-%m-%d %H:%M')" && \
      yadm push
    fi
  fi
}
# Run in background so it never blocks shell startup
[[ $- == *i* ]] && _auto_track_dotfiles &!

# ------------------------------------------------------------------------------
# 14) Profiling output (uncomment if zprof is enabled above)
# ------------------------------------------------------------------------------
# zprof
