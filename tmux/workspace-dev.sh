#!/usr/bin/env bash

WINDOW_NAME="${1:-workspace}"

DEFAULT_SESSION="dev"

if [ -n "$TMUX" ]; then
  SESSION=$(tmux display-message -p '#S')
else
  SESSION="$DEFAULT_SESSION"
fi

attach_or_switch() {
  local target="$1"

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$target"
  else
    tmux attach -t "${target%:*}"
  fi
}

create_layout() {
  local window_target="$1"
  local first_pane="${window_target}.1"

  tmux split-window -v -p 25 -t "$first_pane" 'zsh'
  tmux select-pane -t "$first_pane"
  tmux split-window -h -p 30 -t "$first_pane" 'zsh'
  tmux select-pane -t "$first_pane"
}

window_target=""

if tmux has-session -t "$SESSION" 2>/dev/null; then
  window_target=$(tmux new-window -t "$SESSION" -n "$WINDOW_NAME" -P -F "#{session_name}:#{window_index}" 'nvim')
else
  tmux new-session -d -s "$SESSION" -n "$WINDOW_NAME" 'nvim'
  window_target=$(tmux display-message -p -t "$SESSION:$WINDOW_NAME" "#{session_name}:#{window_index}")
fi

create_layout "$window_target"
tmux select-window -t "$window_target"
attach_or_switch "$window_target"
