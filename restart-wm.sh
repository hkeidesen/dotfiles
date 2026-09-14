#!/usr/bin/env sh
yabai --stop-service
skhd --stop-service
yabai --start-service
skhd --start-service

# skhd hard-aborts on launch while macOS Secure Keyboard Entry is on, which
# silently kills every hotkey. Warn (naming the holder) instead of failing quietly.
holder=$(ioreg -l -w 0 | grep -o '"kCGSSessionSecureInputPID"=[0-9]*' | head -1 | cut -d= -f2)
if [ -n "$holder" ] && [ "$holder" != "0" ]; then
  app=$(ps -p "$holder" -o comm= 2>/dev/null | sed 's#.*/##')
  echo "⚠️  Secure Keyboard Entry is on (held by ${app:-pid $holder}) — skhd will abort."
  echo "    Quit that app (or lock/unlock: Ctrl+Cmd+Q), then run restart-wm again."
fi
