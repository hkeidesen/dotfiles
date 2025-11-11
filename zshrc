# ──────────────────────────────────────────────────────────────────────────────
#                      ZSH CONFIG WITH QoL IMPROVEMENTS
# ──────────────────────────────────────────────────────────────────────────────

# 1) Zsh profiling (uncomment to measure startup times)
# zmodload zsh/zprof

# ------------------------------------------------------------------------------
# 2) Basic PATH & Oh My Zsh
# ------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
# Ensure “python” → “python3” (and pip → pip3) work as expected:
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="/Applications/Espanso.app/Contents/MacOS:$PATH"

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"
# NB: It's ZSH_THEME (not SH_THEME)
# ZSH_THEME="robbyrussell"
ZSH_THEME=""
PROMPT=''
RPROMPT=''
# after sourcing OMZ:
source "$ZSH/oh-my-zsh.sh"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Sensible locale (avoids weird tools output)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ------------------------------------------------------------------------------
# 3) Node (nvm) — grouped into one block
# ------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"               # loads nvm
  . "$NVM_DIR/bash_completion"      # loads nvm bash_completion
fi

# ------------------------------------------------------------------------------
# 4) fzf, Starship, zoxide, broot, etc.
# ------------------------------------------------------------------------------
# fzf: source its shell integration (also gives you Ctrl+R history UI)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# starship prompt (fast, shows exit code etc.)
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# zoxide: smarter cd
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# broot: use the zsh launcher (not the bash one)
[ -f "$HOME/.config/broot/launcher/zsh/br" ] && source "$HOME/.config/broot/launcher/zsh/br"

# gpg: avoid TTY issues
export GPG_TTY="$(tty)"

# ------------------------------------------------------------------------------
# 5) History settings (improved)
# ------------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_DUPS          # ignore consecutive dupes
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_EXPIRE_DUPS_FIRST    # expire older dupes first
setopt INC_APPEND_HISTORY        # write commands as they are executed
setopt SHARE_HISTORY             # share history across sessions

# ------------------------------------------------------------------------------
# 6) Enhanced cd behavior & typo correction
# ------------------------------------------------------------------------------
setopt AUTO_CD        # type a directory name to cd into it
setopt CORRECT        # correct minor typos (e.g., gti -> git)
setopt CDABLE_VARS    # allows “cd $MYDIR” if MYDIR is an env var

# ------------------------------------------------------------------------------
# 7) Completion tweaks
#   Put zstyle BEFORE Oh My Zsh runs compinit (OMZ runs compinit for you)
# ------------------------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'    # case-insensitive
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings'     format '%B%F{yellow}%d%f%b'
zstyle ':completion:*:options'      description 'describe'

# ------------------------------------------------------------------------------
# 8) Plugins (Oh My Zsh) — keep syntax-highlighting LAST
# ------------------------------------------------------------------------------
plugins=(
  git
  virtualenv
  z
  fzf
  tmux
  # direnv               # uncomment if you use direnv
  autoswitch_virtualenv  # uncomment if you want auto-venv activation
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh (after ZSH, ZSH_THEME, plugins)
source "$ZSH/oh-my-zsh.sh"

# ------------------------------------------------------------------------------
# 9) Key-bindings (after OMZ so plugins don't override)
# ------------------------------------------------------------------------------
# Make ↑ / ↓ walk full history (not prefix search)
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history

# NOTE: ~/.fzf.zsh already binds Ctrl+R to fuzzy history.
# If you want to force it explicitly, uncomment:
# [[ $+functions[fzf-history-widget] -gt 0 ]] && bindkey '^R' fzf-history-widget

# ------------------------------------------------------------------------------
# 10) Aliases & custom functions
# ------------------------------------------------------------------------------
# Git shortcuts
alias gst='git status'
alias gl='git pull --rebase'
alias gp='git push'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias glg='git log --graph --oneline --decorate --all'

# Safe remove
alias rm='rm -i'

# Override default ls with lsd (requires lsd)
command -v lsd >/dev/null 2>&1 && alias ls="lsd"

# “car” as a shorthand for “bat”
command -v bat >/dev/null 2>&1 && alias car="bat"

# Quick “extract” helper
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

# Docker shortcuts
alias dps='docker ps'
alias dstop='docker stop'
alias drm='docker rm'

# Restart window manager
alias restart-wm="$HOME/restart-wm.sh"

# Devcontainer helper
dc() { devcontainer "$@" --workspace-folder "${PWD}"; }

# ------------------------------------------------------------------------------
# 11) Auto-track changed dotfiles (yadm)
# ------------------------------------------------------------------------------
autoload -Uz vcs_info
auto_track_dotfiles() {
  if [[ -d "$HOME/.local/share/yadm/repo.git" ]]; then
    local unstaged
    unstaged=$(yadm status --porcelain | grep -E '^\s?[MARD]' | wc -l | tr -d ' ')
    if (( unstaged > 0 )); then
      echo "📦 Auto-adding dotfiles..."
      yadm add -u
      yadm commit -m "Auto-update $(date '+%Y-%m-%d %H:%M')"
      yadm push
    fi
  fi
}
# Run only for interactive shells
[[ $- == *i* ]] && auto_track_dotfiles

# ------------------------------------------------------------------------------
# 12) Extras
# ------------------------------------------------------------------------------
export CTOP_DOCKER_SOCKET="unix://$HOME/.colima/default/docker.sock"
alias ctop='docker run --rm -ti -v /var/run/docker.sock:/var/run/docker.sock quay.io/vektorlab/ctop:latest'

# ------------------------------------------------------------------------------
# 13) Zsh profiling output (uncomment if you enabled zprof above)
# ------------------------------------------------------------------------------
# zprof
alias timeout="gtimeout"
