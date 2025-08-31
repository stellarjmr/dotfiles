#!/bin/bash

CACHE_FILE="/tmp/tmux_brew_cache"
CACHE_DURATION=300

if [ -f "$CACHE_FILE" ]; then
  cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)
  current_time=$(date +%s)

  if [ $((current_time - cache_time)) -lt $CACHE_DURATION ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

outdated_list=$(/opt/homebrew/bin/brew outdated 2>/dev/null)

if [ -n "$outdated_list" ]; then
  count=$(echo "$outdated_list" | wc -l | tr -d ' ')
  result="#[fg=red] $count"
else
  result="#[fg=magenta] "
fi

echo "$result" | tee "$CACHE_FILE"
