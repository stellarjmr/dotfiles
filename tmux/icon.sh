#!/bin/bash
window_name="$1"
window_index="$2"

case "$window_name" in
"zsh")
  icon=" "
  ;;
"yazi")
  icon="󰇥 "
  ;;
"ssh")
  icon="󰢹 "
  ;;
"vim" | "nvim")
  icon=" "
  ;;
"python")
  icon=" "
  ;;
"lazygit")
  icon="󰊢 "
  ;;
esac

echo "$window_index $icon"
