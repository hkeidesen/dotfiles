# ──────────────────────────────────────────────────────────────────────────────
#                      ZSH CONFIG WITH QoL IMPROVEMENTS
# ──────────────────────────────────────────────────────────────────────────────

# 1) Zsh profiling (uncomment to measure startup times)
#gmodload zsh/zprof

# ------------------------------------------------------------------------------
# 2) Basic environment & Oh My Zsh
# ------------------------------------------------------------------------------
export PATH="/opt/homebrew/bin:$PATH"
# Ensure “python” → “python3” (and pip → pip3) work as expected:
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export PATH="/Applications/Espanso.app/Contents/MacOS:$PATH"

# Oh My Zsh installation path
export ZSH="$HOME/.oh-my-zsh"
SH_THEME="robbyrussell"    # you can switch to "random" or any other theme


# ------------------------------------------------------------------------------
# 3) Node (nvm) — grouped into one block
# ------------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"               # loads nvm
  . "$NVM_DIR/bash_completion"      # loads nvm bash_completion
fi

# ------------------------------------------------------------------------------
# 4) fzf, Starship, zoxide, broot, Espanso, etc.
# ------------------------------------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source /Users/hans-kristian.norum/.config/broot/launcher/bash/br

# ------------------------------------------------------------------------------
# 5) History settings (improved)
# ------------------------------------------------------------------------------

# History file location and size
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# Only drop a new line if it's identical to the *immediately previous* entry
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE        # skip entries that start with a space

# When writing history, remove older duplicates first so the newest copy is always at the end
setopt HIST_EXPIRE_DUPS_FIRST

# Append each command immediately to the history file and share across sessions
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# precmd() {
#   # 1) Reload history so ↑ always sees the latest command
#   fc -R
#
#   # 2) If the last exit code was nonzero AND there's something in /tmp/zsh_stderr, print it
#   if [[ $? -ne 0 && -s /tmp/zsh_stderr ]]; then
#     echo -e "\n%F{red}Error output:%f"
#     cat /tmp/zsh_stderr
#   fi
#
#   # 3) Clear the temp file for the next command
#   > /tmp/zsh_stderr
# }

# ------------------------------------------------------------------------------
# 6) Enhanced cd behavior & typo correction
# ------------------------------------------------------------------------------
setopt AUTO_CD         # type a directory name and hit Enter to cd into it
setopt CORRECT        # correct minor typos in commands (e.g., “gti” → “git”)
setopt CDABLE_VARS    # allows “cd PROJECTS” if PROJECTS is an env var pointing somewhere

# ------------------------------------------------------------------------------
# 7) Completion tweaks
# ------------------------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'    # case-insensitive matching
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings'     format '%B%F{yellow}%d%f%b'
zstyle ':completion:*:options'      description 'describe'
autoload -Uz compinit
compinit -u   # “-u” skips insecure-directory checks if you trust your plugin folders

# ------------------------------------------------------------------------------
# 8) Key-bindings & fzf history search
# ------------------------------------------------------------------------------
# Ensure ↑/↓ go through the full history rather than doing prefix-search by default
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history

# If fzf is installed, bind Ctrl+R to an interactive fuzzy-history search
if type fzf >/dev/null 2>&1; then
  bindkey '^R' fzf-history-widget
fi

# ------------------------------------------------------------------------------
# 9) Plugins (Oh My Zsh)
# ------------------------------------------------------------------------------
plugins=(
  git
  virtualenv
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  tmux
  # direnv           # uncomment if you use direnv for per-project env vars
  autoswitch_virtualenv  # uncomment if you want auto-venv activation
)

# Load Oh My Zsh (after setting ZSH and ZSH_THEME)
source $ZSH/oh-my-zsh.sh
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

# Quick “extract” helper: auto-detect archive type
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

# Restart window manager (from your old alias)
alias restart-wm="~/restart-wm.sh"

# Override default ls with lsd
alias ls="lsd"

# “bat” as a shorthand for “car” (your previous alias)
alias car="bat"

# Devcontainer helper
dc() { devcontainer "$@" --workspace-folder "${PWD}"; }

# # ------------------------------------------------------------------------------
# # stderr‐capture wrapper (only show if exit status ≠ 0)
# # ------------------------------------------------------------------------------
# preexec() {
#   # Redirect stderr of *any* command to /tmp/zsh_stderr
#   exec 2>/tmp/zsh_stderr
# }
#
# precmd() {
#   # 1) Reload history (so ↑ always sees the latest)
#   fc -R
#
#   # 2) Only show “Error output” if the last command's exit code was nonzero
#   if [[ $? -ne 0 && -s /tmp/zsh_stderr ]]; then
#     echo -e "\n%F{red}Error output:%f"
#     cat /tmp/zsh_stderr
#   fi
#
#   # 3) Clear the temp file for the next round
#   > /tmp/zsh_stderr
# }
# ------------------------------------------------------------------------------
# 12) Prompt
# ------------------------------------------------------------------------------
# You’re already using Starship, which shows a red ✗ when the last command failed.
# If you ever switch back to pure Zsh, you could do something like:
#
# PROMPT='%F{green}%n@%m%f %F{blue}%~%f %F{red}%(?: :✗ %?)%f %# '
#
# But since Starship manages your prompt, no need to set PROMPT here.

# ------------------------------------------------------------------------------
# 13) Zsh profiling output (uncomment if you want to inspect startup times)
# ------------------------------------------------------------------------------
#zprof
# Auto-track changed dotfiles (ignores gitignored files)
autoload -Uz vcs_info

function auto_track_dotfiles() {
  if [[ -d "$HOME/.local/share/yadm/repo.git" ]]; then
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
