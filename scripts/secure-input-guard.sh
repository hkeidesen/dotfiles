#!/bin/sh
# secure-input-guard.sh
#
# macOS "Secure Keyboard Entry" (EnableSecureEventInput) is a global flag. While
# it's on, the OS bypasses CGEventTaps — so skhd stops seeing hotkeys and keys
# like Opt+Shift+M fall through to the app (typing " on the Norwegian layout).
#
# Apps sometimes enable it and never release it (a leak); the holder then shows
# up as `loginwindow`. This guard polls the flag and notifies when it looks stuck
# so hotkeys never silently die. Run periodically via launchd.

STATE_FILE="/tmp/secure-input-guard.state"
COOLDOWN=1800   # min seconds between repeat notifications for the same leak

# Current holder PID of Secure Keyboard Entry (0 = off).
pid=$(ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*' | head -1 | cut -d= -f2)
pid=${pid:-0}

now=$(date +%s)

# Previous state: "<last_pid> <last_notify_ts>"
if [ -f "$STATE_FILE" ]; then
  read -r prev_pid last_notify < "$STATE_FILE"
else
  prev_pid=0
  last_notify=0
fi
prev_pid=${prev_pid:-0}
last_notify=${last_notify:-0}

# Fire a macOS notification naming the app that holds the flag.
notify() {
  app=$(ps -p "$1" -o comm= 2>/dev/null | sed 's#.*/##')
  osascript -e "display notification \"Held by ${app:-pid $1}. Lock screen (Ctrl+Cmd+Q) to clear.\" with title \"skhd hotkeys disabled\" subtitle \"Secure Keyboard Entry is stuck on\" sound name \"Basso\""
}

if [ "$pid" -eq 0 ]; then
  # Secure Input is off — nothing stuck. Reset so the next "on" is a fresh event.
  last_notify=0
elif [ "$pid" -eq "$prev_pid" ] && [ $((now - last_notify)) -ge "$COOLDOWN" ]; then
  # Held across two consecutive polls (>=30s) — too long for a password prompt,
  # so treat it as a leak. Cooldown prevents re-alerting every run.
  notify "$pid"
  last_notify=$now
fi

echo "$pid $last_notify" > "$STATE_FILE"
