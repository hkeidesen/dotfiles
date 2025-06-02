
#!/usr/bin/env bash
load=$(top -l1 | awk '/CPU usage/ {printf "%.0f%%", $3 + $5}')
echo "{\"text\":\"CPU ${load}\"}"
