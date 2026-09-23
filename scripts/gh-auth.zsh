# GitHub identity for this shell, re-derived on every directory change.
#
# Two signals, highest priority first:
#   1. the GitHub org of the current repo's origin remote
#   2. the tmux session name, and the fallback when neither applies
#
# _GH_ORG_ACCOUNTS is the same table gitconfig keys its includeIf rules on. Add
# an org here and add the matching includeIf block in ~/dotfiles/gitconfig, or
# commits will be authored by the wrong identity in that org's repos.

typeset -gA _GH_ORG_ACCOUNTS=(
  getstemne              hkeidesen
  trondheim-kommune-tip  hkeidesen-sopra
  dfo-no                 hkeidesen-dfo
)

typeset -gA _GH_SESSION_ACCOUNTS=(
  dfø                hkeidesen-dfo
  trondheim-kommune  hkeidesen-sopra
)

: ${_GH_DEFAULT_ACCOUNT:=hkeidesen}

# Org segment of a github remote URL, lowercased. Handles all four forms:
#   https://github.com/ORG/repo      ssh://git@github.com/ORG/repo
#   git@github.com:ORG/repo          git@github-alias:ORG/repo
_gh_org_from_url() {
  local url=$1 path
  case $url in
    *github.com/*|*github.com:*|*github-*:*) ;;
    *) return 1 ;;
  esac
  path=${url##*github.com/}
  [[ $path == "$url" ]] && path=${url##*:}
  path=${path#/}
  [[ -n $path ]] || return 1
  print -r -- ${(L)path%%/*}
}

_gh_account_for_pwd() {
  local url org account session
  url=$(command git config --get remote.origin.url 2>/dev/null)
  if [[ -n $url ]] && org=$(_gh_org_from_url $url); then
    account=${_GH_ORG_ACCOUNTS[$org]}
  fi
  if [[ -z $account && -n $TMUX ]]; then
    session=$(command tmux display-message -p -t "$TMUX_PANE" '#{session_name}' 2>/dev/null)
    account=${_GH_SESSION_ACCOUNTS[$session]}
  fi
  print -r -- ${account:-$_GH_DEFAULT_ACCOUNT}
}

# Point this shell at the right account. Runs on every cd, so the keyring is
# only touched when the selection actually changes.
gh-auth-sync() {
  (( _GH_PINNED )) && return 0
  local account token
  account=$(_gh_account_for_pwd)
  [[ $account == "$_GH_APPLIED_ACCOUNT" ]] && return 0
  if token=$(command gh auth token --hostname github.com --user $account 2>/dev/null) && [[ -n $token ]]; then
    export GH_TOKEN=$token GH_AUTH_USER=$account
  else
    # Fail closed. A bogus token 401s loudly; silently falling back to whichever
    # account gh has active would act as the wrong identity, which is worse. The
    # "!" suffix surfaces the broken state in the prompt instead of hiding it.
    export GH_TOKEN=no-token-for-$account GH_AUTH_USER="$account!"
    print -u2 -- "gh: no saved token for $account — run: gh auth login --hostname github.com"
  fi
  _GH_APPLIED_ACCOUNT=$account
}

# `gh auth switch` cannot work while GH_TOKEN is exported — it refuses rather
# than fight the environment. This is the replacement. The choice is pinned
# (prompt shows a trailing "*") until `ghuse -a` hands control back to the
# automatic selection above.
ghuse() {
  local account=$1 token
  case $account in
    -a|--auto)
      _GH_PINNED=0
      _GH_APPLIED_ACCOUNT=
      gh-auth-sync
      return
      ;;
    "")
      print -u2 -- "usage: ghuse <account> | ghuse -a   (known: ${(vou)_GH_ORG_ACCOUNTS})"
      return 1
      ;;
  esac
  if ! token=$(command gh auth token --hostname github.com --user $account 2>/dev/null) || [[ -z $token ]]; then
    print -u2 -- "gh: no saved token for $account"
    return 1
  fi
  export GH_TOKEN=$token GH_AUTH_USER="$account*"
  _GH_APPLIED_ACCOUNT=$account
  _GH_PINNED=1
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd gh-auth-sync
gh-auth-sync
