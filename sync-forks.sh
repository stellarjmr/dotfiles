#!/usr/bin/env bash
# Sync all forks under GitHub account stellarjmr with their upstreams.
set -euo pipefail

OWNER="stellarjmr"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not found" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh not authenticated. Run: gh auth login" >&2
  exit 1
fi

FORKS=$(gh repo list "$OWNER" --fork --limit 500 \
  --json nameWithOwner,defaultBranchRef \
  -q '.[] | "\(.nameWithOwner)\t\(.defaultBranchRef.name)"')

if [ -z "$FORKS" ]; then
  echo "No forks found under $OWNER."
  exit 0
fi

total=$(printf '%s\n' "$FORKS" | wc -l | tr -d ' ')
echo "Found $total forks. Syncing..."
fail=0
while IFS=$'\t' read -r repo branch; do
  [ -z "$repo" ] && continue
  printf '  %-50s %-15s ' "$repo" "$branch"
  err=$(gh repo sync "$repo" -b "$branch" --force 2>&1 >/dev/null) && rc=0 || rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "ok"
  else
    echo "FAILED: $err"
    fail=$((fail + 1))
  fi
done <<< "$FORKS"

echo
echo "Done. $total total, $fail failed."
