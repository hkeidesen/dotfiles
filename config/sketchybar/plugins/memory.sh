
#!/usr/bin/env bash
used=$(vm_stat | awk '
  /Pages active/ {a=$3}
  /Pages inactive/ {i=$3}
  /Pages speculative/ {s=$3}
  END {printf "%.0f%%", (a+i+s)*4096/$(sysctl -n hw.memsize)*100}')
echo "{\"text\":\"RAM ${used}\"}"
