
#!/usr/bin/env bash
ssid=$(networksetup -getairportnetwork en0 | cut -d: -f2- | xargs)
[ -z "$ssid" ] && ssid="Off"
echo "{\"text\":\"${ssid}\"}"
