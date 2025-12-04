#!/bin/bash

# Locate brew
if ! command -v brew >/dev/null 2>&1; then
  echo "#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold] "
  exit 0
fi

# Count outdated packages (formulae + casks)
count=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
count=${count:-0}

# Display result
if [ "$count" -gt 0 ]; then
  echo "#[bg=${LIGHT_GRAY},fg=${RED},bold] #[bg=${LIGHT_GRAY},fg=${RED},bold]$count"
else
  echo "#[bg=${LIGHT_GRAY},fg=${MAGENTA},bold] "
fi
