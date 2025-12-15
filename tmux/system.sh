#!/bin/bash

cpu=$(top -l 1 -n 0 | grep "CPU usage" | awk '{gsub(/%/,"",$3); printf "%.0f%%", $3}' 2>/dev/null || echo "0%")
memory=$(vm_stat | awk '/Pages free/ {free = $3} /Pages active/ {active = $3} /Pages inactive/ {inactive = $3} /Pages speculative/ {spec = $3} /Pages wired/ {wired = $3} /Pages occupied by compressor/ {compressed = $5} END {gsub(/\./, "", free); gsub(/\./, "", active); gsub(/\./, "", inactive); gsub(/\./, "", spec); gsub(/\./, "", wired); gsub(/\./, "", compressed); free=free+0; active=active+0; inactive=inactive+0; spec=spec+0; wired=wired+0; compressed=compressed+0; total = free + active + inactive + spec + wired + compressed; used = active + wired + compressed; available = free + inactive + spec; print int((used/total)*100) "%"}')

echo "#[bg=${LIGHT_GRAY},fg=${BLUE},bold]􀧖 $memory #[bg=${LIGHT_GRAY},fg=${GREEN},bold]􀫥 $cpu"
