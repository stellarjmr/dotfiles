#!/usr/bin/env bash
# One-shot updater for frequently-used tools.
# Usage: update-all.sh [--skip brew|cask|amp|yazi|nvim|mason|cleanup] ...

set -u

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
BAR_GREEN='\033[38;5;2m'
BAR_GRAY='\033[38;5;238m'
BG_BAR_GREEN='\033[48;5;2m'
BG_BAR_GRAY='\033[48;5;238m'
NC='\033[0m'

WORKDIR_TMP=""
SKIP=()
TOTAL_STEPS=7
STEP_INDEX=0
while [[ $# -gt 0 ]]; do
  case "$1" in
  --skip)
    SKIP+=("$2")
    shift 2
    ;;
  -h | --help)
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "unknown arg: $1" >&2
    exit 2
    ;;
  esac
done

skipped() {
  for s in "${SKIP[@]:-}"; do [[ "$s" == "$1" ]] && return 0; done
  return 1
}

setup_tmpdir() {
  WORKDIR_TMP=$(mktemp -d "${TMPDIR:-/tmp}/update-all.XXXXXX")
  trap 'rm -rf "$WORKDIR_TMP"' EXIT
}

FAILED=()
UPDATED=()

progress_bar() {
  local done="$1"
  local total="$2"
  local width=24
  local filled empty filled_bar empty_bar
  local left_cap=""
  local right_cap=""
  local left_color="$BAR_GRAY"
  local right_color="$BAR_GRAY"

  ((total > 0)) || total=1
  filled=$((done * width / total))
  empty=$((width - filled))
  ((filled > 0)) && left_color="$BAR_GREEN"
  ((empty == 0)) && right_color="$BAR_GREEN"

  printf -v filled_bar '%*s' "$filled" ''
  printf -v empty_bar '%*s' "$empty" ''

  printf '%b%s%b%b%s%b%b%s%b%b%s%b %d/%d' \
    "$left_color" "$left_cap" "$NC" \
    "$BG_BAR_GREEN" "$filled_bar" "$NC" \
    "$BG_BAR_GRAY" "$empty_bar" "$NC" \
    "$right_color" "$right_cap" "$NC" \
    "$done" "$total"
}

render_progress() {
  local done="$1"
  local marker="$2"
  local color="$3"
  local name="$4"

  if [[ -t 1 ]]; then
    printf '\r\033[K%s %b%s%b %s' "$(progress_bar "$done" "$TOTAL_STEPS")" "$color" "$marker" "$NC" "$name"
  else
    printf '%s %b%s%b %s\n' "$(progress_bar "$done" "$TOTAL_STEPS")" "$color" "$marker" "$NC" "$name"
  fi
}

finish_progress_line() {
  [[ -t 1 ]] && printf '\n'
}

render_complete_progress() {
  [[ -t 1 ]] || return 0
  printf '\r\033[K%s %b✓%b' "$(progress_bar "$TOTAL_STEPS" "$TOTAL_STEPS")" "$GREEN" "$NC"
}

render_failed_progress() {
  [[ -t 1 ]] || return 0
  printf '\r\033[K%s %b✗%b' "$(progress_bar "$STEP_INDEX" "$TOTAL_STEPS")" "$RED" "$NC"
}

collect_step_summary() {
  local log="$1"
  local line
  [[ -s "$log" ]] || return 0

  while IFS= read -r line; do
    UPDATED+=("$line")
  done < <(awk '
    /^updated brew formula / ||
    /^updated brew cask / ||
    /^updated amp$/ ||
    /^updated yazi plugin / ||
    /^installed yazi plugin / ||
    /^updated nvim plugin / ||
    /^installed nvim plugin / ||
    /^updated mason package / {
      print
    }
  ' "$log")
}

step() {
  local name="$1"
  shift
  STEP_INDEX=$((STEP_INDEX + 1))
  if skipped "$name"; then
    render_progress "$STEP_INDEX" "[skip]" "$YELLOW" "$name"
    return
  fi

  local log="$WORKDIR_TMP/${name}.step.log"
  local status
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local frame=0

  if [[ -t 1 ]]; then
    "$@" >"$log" 2>&1 &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
      render_progress "$((STEP_INDEX - 1))" "${frames[$frame]}" "$CYAN" "$name"
      frame=$(((frame + 1) % ${#frames[@]}))
      sleep 0.12
    done
    wait "$pid"
    status=$?
  else
    "$@" >"$log" 2>&1
    status=$?
  fi

  if [[ $status -eq 0 ]]; then
    render_progress "$STEP_INDEX" "[ok]" "$GREEN" "$name"
    collect_step_summary "$log"
  else
    render_progress "$STEP_INDEX" "[fail]" "$RED" "$name (exit $status)"
    finish_progress_line
    cat "$log"
    FAILED+=("$name")
  fi
}

brew_update() {
  local formulae_file="$WORKDIR_TMP/brew-formulae.outdated"
  local formulae=()
  local formula

  brew update
  if ! brew outdated --quiet --formula 2>/dev/null >"$formulae_file"; then
    return 1
  fi
  while IFS= read -r formula; do
    [[ -n "$formula" ]] && formulae+=("$formula")
  done <"$formulae_file"

  [[ ${#formulae[@]} -eq 0 ]] && return 0

  brew upgrade "${formulae[@]}"

  for formula in "${formulae[@]}"; do
    printf 'updated brew formula %s\n' "$formula"
  done
}

brew_cask() {
  local casks_file="$WORKDIR_TMP/brew-casks.outdated"
  local casks=()
  local cask

  if ! brew outdated --quiet --cask 2>/dev/null >"$casks_file"; then
    return 1
  fi
  while IFS= read -r cask; do
    [[ -n "$cask" ]] && casks+=("$cask")
  done <"$casks_file"

  [[ ${#casks[@]} -eq 0 ]] && return 0

  brew upgrade --cask "${casks[@]}"

  for cask in "${casks[@]}"; do
    printf 'updated brew cask %s\n' "$cask"
  done
}

amp_update() {
  local before after
  before=$(amp --version 2>/dev/null || true)
  amp update
  after=$(amp --version 2>/dev/null || true)

  if [[ -n "$before" && -n "$after" && "$before" != "$after" ]]; then
    printf 'updated amp\n'
  fi
}

load_yazi_plugins() {
  local file="$1"
  ya pkg list 2>/dev/null | awk '
    /^Plugins:/ { in_plugins = 1; next }
    /^Flavors:/ { in_plugins = 0 }
    in_plugins && NF {
      line = $0
      gsub(/^[[:space:]]+/, "", line)
      name = line
      sub(/ \([^)]*\)$/, "", name)
      hash = line
      sub(/^.*\(/, "", hash)
      sub(/\)$/, "", hash)
      print name "\t" hash
    }
  ' >"$file"
}

yazi_update() {
  command -v ya >/dev/null 2>&1 || {
    echo "ya not found"
    return 0
  }

  local before_revs="$WORKDIR_TMP/yazi.before.tsv"
  local after_revs="$WORKDIR_TMP/yazi.after.tsv"
  local log="$WORKDIR_TMP/yazi-update.log"

  load_yazi_plugins "$before_revs"

  if ! ya pkg upgrade >"$log" 2>&1; then
    cat "$log"
    return 1
  fi

  load_yazi_plugins "$after_revs"

  local name old_rev new_rev printed=0
  while IFS=$'\t' read -r name old_rev; do
    [[ -n "$name" ]] || continue
    new_rev=$(awk -F $'\t' -v plugin="$name" '$1 == plugin { print $2; exit }' "$after_revs")
    if [[ -n "$new_rev" && "$new_rev" != "$old_rev" ]]; then
      printf 'updated yazi plugin %s\n' "$name"
      printed=1
    fi
  done <"$before_revs"

  while IFS=$'\t' read -r name new_rev; do
    [[ -n "$name" ]] || continue
    old_rev=$(awk -F $'\t' -v plugin="$name" '$1 == plugin { print $2; exit }' "$before_revs")
    if [[ -z "$old_rev" ]]; then
      printf 'installed yazi plugin %s\n' "$name"
      printed=1
    fi
  done <"$after_revs"

  [[ $printed -eq 1 ]] || true
}

parse_nvim_pack_lock() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '
    /^    ".*": \{$/ {
      name = $0
      sub(/^    "/, "", name)
      sub(/": \{$/, "", name)
      next
    }
    /^[[:space:]]+"rev": "/ && name != "" {
      rev = $0
      sub(/^[[:space:]]+"rev": "/, "", rev)
      sub(/",?$/, "", rev)
      print name "\t" rev
      name = ""
    }
  ' "$file" | sort
}

nvim_update() {
  command -v nvim >/dev/null 2>&1 || {
    echo "nvim not found"
    return 0
  }

  local lock="$HOME/.config/nvim/nvim-pack-lock.json"
  local before="$WORKDIR_TMP/nvim-pack-lock.before.json"
  local after="$WORKDIR_TMP/nvim-pack-lock.after.json"
  local before_revs="$WORKDIR_TMP/nvim-pack-lock.before.tsv"
  local after_revs="$WORKDIR_TMP/nvim-pack-lock.after.tsv"

  [[ -f "$lock" ]] && cp "$lock" "$before" || : >"$before"

  local log="$WORKDIR_TMP/nvim-update.log"
  if ! nvim --headless -i NONE "+lua vim.pack.update(nil, { force = true })" +qa >"$log" 2>&1; then
    cat "$log"
    return 1
  fi

  [[ -f "$lock" ]] && cp "$lock" "$after" || : >"$after"
  parse_nvim_pack_lock "$before" >"$before_revs"
  parse_nvim_pack_lock "$after" >"$after_revs"

  local name old_rev new_rev printed=0
  while IFS=$'\t' read -r name old_rev; do
    [[ -n "$name" ]] || continue
    new_rev=$(awk -F $'\t' -v plugin="$name" '$1 == plugin { print $2; exit }' "$after_revs")
    if [[ -n "$new_rev" && "$new_rev" != "$old_rev" ]]; then
      printf 'updated nvim plugin %s\n' "$name"
      printed=1
    fi
  done <"$before_revs"

  while IFS=$'\t' read -r name new_rev; do
    [[ -n "$name" ]] || continue
    old_rev=$(awk -F $'\t' -v plugin="$name" '$1 == plugin { print $2; exit }' "$before_revs")
    if [[ -z "$old_rev" ]]; then
      printf 'installed nvim plugin %s\n' "$name"
      printed=1
    fi
  done <"$after_revs"

  [[ $printed -eq 1 ]] || true
}

mason_update() {
  command -v nvim >/dev/null 2>&1 || {
    echo "nvim not found"
    return 0
  }

  local mason_lua
  mason_lua=$(cat <<'EOF'
local pip_args = {}
local proxy = os.getenv('PIP_PROXY')
if proxy then
  pip_args = { '--proxy', proxy }
end

vim.pack.add({ 'https://github.com/williamboman/mason.nvim' })
require('mason').setup({
  pip = {
    upgrade_pip = false,
    install_args = pip_args,
  },
  ui = {
    border = 'single',
    backdrop = 40,
    width = 0.7,
    height = 0.7,
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
})

local a = require('mason-core.async')
local registry = require('mason-registry')

a.run_blocking(function()
  local ok, result = a.wait(registry.update)
  a.scheduler()
  if not ok then
    error(('Failed to update Mason registries: %s'):format(vim.inspect(result)))
  end

  local outdated = {}
  for _, pkg in ipairs(registry.get_installed_packages()) do
    local current_version = pkg:get_installed_version()
    local latest_version = pkg:get_latest_version()
    if current_version ~= latest_version then
      table.insert(outdated, pkg)
    end
  end

  if #outdated == 0 then
    vim.api.nvim_out_write('MASON_NO_UPDATES\n')
    return
  end

  for _, pkg in ipairs(outdated) do
    a.wait(function(resolve, reject)
      pkg:install({}, function(success, install_result)
        (success and resolve or reject)(install_result)
      end)
    end)
    a.scheduler()
    vim.api.nvim_out_write(('MASON_UPDATED:%s\n'):format(pkg.name))
  end
end)
EOF
)

  local log="$WORKDIR_TMP/mason-update.log"
  if ! nvim --headless -i NONE "+lua $mason_lua" +qa >"$log" 2>&1; then
    cat "$log"
    return 1
  fi

  local printed=0 line
  while IFS= read -r line; do
    [[ "$line" == MASON_UPDATED:* ]] || continue
    printf 'updated mason package %s\n' "${line#MASON_UPDATED:}"
    printed=1
  done <"$log"

  [[ $printed -eq 1 ]] || true
}

brew_cleanup() { brew cleanup; }

setup_tmpdir
step brew brew_update
step cask brew_cask
step amp amp_update
step yazi yazi_update
step nvim nvim_update
step mason mason_update
step cleanup brew_cleanup

if [[ ${#FAILED[@]} -eq 0 ]]; then
  render_complete_progress
else
  render_failed_progress
fi
finish_progress_line
if [[ ${#UPDATED[@]} -ne 0 ]]; then
  printf '%s\n' "${UPDATED[@]}"
fi

if [[ ${#FAILED[@]} -eq 0 ]]; then
  :
else
  exit 1
fi
