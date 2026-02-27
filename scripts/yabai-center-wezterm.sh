#!/bin/bash
# Balance layout and make WezTerm the biggest window (left, 50%).

yabai -m space --balance

WT_ID=$(yabai -m query --windows --space | \
  jq -r '[.[] | select(.app=="WezTerm" and ."is-minimized"==false)][0].id // empty')

[ -z "$WT_ID" ] && exit 0

yabai -m window "$WT_ID" --swap first 2>/dev/null
yabai -m window "$WT_ID" --ratio abs:0.5
yabai -m window --focus "$WT_ID"
