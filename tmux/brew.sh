#!/bin/bash

CACHE_FILE="/tmp/tmux_brew_cache"
CACHE_DURATION=300
BREW_LOCK="/opt/homebrew/var/homebrew/locks/update"

# If brew update is running, use cache to avoid inconsistent results
if [ -f "$BREW_LOCK" ] && [ -f "$CACHE_FILE" ]; then
  cat "$CACHE_FILE"
  exit 0
fi

if [ -f "$CACHE_FILE" ]; then
  cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null)
  current_time=$(date +%s)

  if [ $((current_time - cache_time)) -lt $CACHE_DURATION ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Only check formulae (packages), not casks which auto-update
outdated_list=$(/opt/homebrew/bin/brew outdated --formula 2>/dev/null)

# Filter out empty lines and count properly
if [ -n "$outdated_list" ]; then
  count=$(echo "$outdated_list" | grep -c '^[^[:space:]]')
  if [ "$count" -gt 0 ]; then
    result="#[bg=${LIGHT_GRAY},fg=${RED},bold]􀐛 #[bg=${LIGHT_GRAY},fg=${RED},bold]$count"
  else
    result="#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]􀐛 "
  fi
else
  result="#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]􀐛 "
fi

echo "$result" | tee "$CACHE_FILE"
