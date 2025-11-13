#!/bin/zsh
window_name="$1"
window_index="$2"
window_panes="$3"

case "$window_name" in
zsh | bash | fish | sh)
  icon=" "
  ;;
yazi)
  icon="󰇥 "
  ;;
ssh)
  icon="󰢹 "
  ;;
vim | nvim)
  icon=" "
  ;;
python | python3 | python3.9 | python3.10 | python3.11 | python3.12)
  icon=" "
  ;;
lazygit)
  icon="󰊢 "
  ;;
ruby)
  icon=" "
  ;;
fzf)
  icon=" "
  ;;
node)
  icon="󰫢 "
  ;;
codex | *codex*)
  icon="󰧑 "
  ;;
claude)
  icon=" "
  ;;
*)
  icon="󰊠 "
  ;;
esac
multipanes=" "
if [[ "$window_panes" -gt 1 ]]; then
  echo "#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]$window_index #[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]$multipanes"
else
  echo "#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]$window_index #[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]$icon"
fi
