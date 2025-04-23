eval "$(zoxide init zsh)"
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH



export TERM="xterm-kitty"
export COLORTERM=truecolor


# Go air
alias air='/Users/hk/go/bin/air'

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=( git zsh-autosuggestions zsh-syntax-highlighting fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8


# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# alias ls='colorls --sd --gs'
alias mv4='z /Users/hk/Projects/mlink-vue3-frontend'
alias backend='z /Users/hk/Projects/mlink-monorepo/backend/mlink'

if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [[ $SSH_TTY ]]; then
  tmux attach -t default || tmux new -s default
fi
export TMUX_PROGRAM=$(which tmux)

export HISTFILE=~/.zsh-history-sync/.zsh_history_shared
export HISTSIZE=10000
export SAVEHIST=10000

# append history entries..
# setopt -s histappend

# After each command, save and reload history
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
setopt inc_append_history  # Write to history immediately
setopt share_history       # Share history across sessions
setopt hist_ignore_dups    # Ignore duplicated commands in history
# setopt hist_ignore_space   # Ignore commands that start with space
setopt hist_reduce_blanks  # Remove superfluous blanks before storing in history
# setopt hist_verify         # Don't execute immediately upon history expansion

# Set paths
export PATH=/opt/homebrew/bin:$PATH
export GCLOUD_CONFIG_PATH="$HOME/.config/gcloud"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/hk/google-cloud-sdk/path.zsh.inc' ]; then
    source '/Users/hk/google-cloud-sdk/path.zsh.inc'
fi
export PATH=$HOME/go/bin:$PATH

# functions
code() {
    open -a "Visual Studio Code.app" "$@"
}

alias inv='nvim $(fzf -m --preview="bat --color=always {}")'

export VISUAL='nvim'
EDITOR='nvim'
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PIPENV_PYTHON="$PYENV_ROOT/shims/python"

plugin=(
  pyenv
)

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
source ~/.nvm/nvm.sh
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# Bind Ctrl-r to fzf history search
# fzf-history-widget() {
#   local selected_command
#   selected_command=$(fc -rl 1 | fzf --height 40% --reverse --tac) && LBUFFER=$selected_command
#   zle redisplay
# }
# zle -N fzf-history-widget
# bindkey '^R' fzf-history-widget

. "$HOME/.local/bin/env"

# Auto-start or attach to an existing tmux session
if [[ -z "$TMUX" ]] && [[ $SSH_TTY ]]; then
    tmux attach -t default || tmux new -s default
fi


alias pbpush="pbpaste | ssh hk@datadragon 'tmux load-buffer -'"
(( ! ${+functions[p10k]} )) || p10k finalize
