#!/bin/bash

CACHE_FILE="/tmp/tmux_brew_cache"
CACHE_DURATION=300

# Try to locate Homebrew dynamically to support varying installations.
if command -v brew >/dev/null 2>&1; then
  BREW_BIN="$(command -v brew)"
else
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      BREW_BIN="$candidate"
      break
    fi
  done
fi

if [ -z "$BREW_BIN" ]; then
  result="#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]􀐛 "
  echo "$result" | tee "$CACHE_FILE"
  exit 0
fi

BREW_PREFIX="$("$BREW_BIN" --prefix 2>/dev/null)"
if [ -n "$BREW_PREFIX" ]; then
  BREW_LOCK="$BREW_PREFIX/var/homebrew/locks/update"
else
  BREW_LOCK=""
fi

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

# Count both formulae and casks without needing Python (works even if CLT isn't installed)
formula_count=$("$BREW_BIN" outdated --formula --quiet 2>/dev/null | awk 'NF{count++} END{print count+0}' 2>/dev/null)
cask_count=$("$BREW_BIN" outdated --cask --quiet 2>/dev/null | awk 'NF{count++} END{print count+0}' 2>/dev/null)

# awk might not print anything if the command fails, so default to zero
if ! [[ "$formula_count" =~ ^[0-9]+$ ]]; then
  formula_count=0
fi
if ! [[ "$cask_count" =~ ^[0-9]+$ ]]; then
  cask_count=0
fi

count=$((formula_count + cask_count))

if ! [[ "$count" =~ ^[0-9]+$ ]]; then
  count=0
fi

if [ -n "$count" ] && [ "$count" -gt 0 ]; then
  result="#[bg=${LIGHT_GRAY},fg=${RED},bold]􀐛 #[bg=${LIGHT_GRAY},fg=${RED},bold]$count"
else
  result="#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold]􀐛 "
fi

echo "$result" | tee "$CACHE_FILE"
