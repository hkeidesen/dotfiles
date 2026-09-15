# Select GitHub authentication independently for each tmux session.
() {
  [[ -n "$TMUX" ]] || return 0

  local session account token
  if ! session="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}')"; then
    print -u2 -- "GitHub authentication: could not determine the tmux session."
    return 1
  fi

  case "$session" in
    dfø) account=hkeidesen-dfo ;;
    trondheim-kommune) account=hkeidesen-sopra ;;
    *) account=hkeidesen ;;
  esac

  if token="$(gh auth token --hostname github.com --user "$account")" && [[ -n "$token" ]]; then
    export GH_TOKEN="$token"
  else
    export GH_TOKEN=tmux-github-auth-unavailable
    print -u2 -- "GitHub authentication: no saved token for $account (tmux session: $session). Unset GH_TOKEN, run gh auth login for that account, then source this script again."
    return 1
  fi
}
