#!/bin/zsh
window_name="$1"
window_index="$2"
window_panes="$3"

LEFT_ROUND=""
RIGHT_ROUND=""

case "$window_name" in
"zsh" | "bash" | "fish" | "sh")
  icon=" "
  ;;
"yazi")
  icon="󰇥 "
  ;;
"ssh")
  icon="󰢹 "
  ;;
"vim" | "nvim")
  icon=" "
  ;;
"python" | "python3" | "python3.9" | "python3.10" | "python3.11" | "python3.12")
  icon=" "
  ;;
"lazygit")
  icon="󰊢 "
  ;;
"ruby")
  icon=" "
  ;;
"fzf")
  icon=" "
  ;;
esac
multipanes=" "
if [[ "$window_panes" -gt 1 ]]; then
  echo "$LEFT_ROUND#[bold]$window_index $multipanes$RIGHT_ROUND"
else
  echo "$LEFT_ROUND#[bold]$window_index $icon$RIGHT_ROUND"
fi
