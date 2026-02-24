#!/usr/bin/env bash
# Replaces __LAST_MODIFIED__ placeholder with git's last commit date for index.qmd
# Usage: ./update-last-modified.sh [restore]
#   restore: replace date back with placeholder (for post-render)
set -e
cd "$(dirname "$0")/.."
if [[ "${1:-}" == "restore" ]]; then
  # Restore placeholder (post-render)
  date=$(git log -1 --format='%ad' --date=short -- index.qmd 2>/dev/null || echo "unknown")
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/Last modified: $date/Last modified: __LAST_MODIFIED__/g" index.qmd
  else
    sed -i "s/Last modified: $date/Last modified: __LAST_MODIFIED__/g" index.qmd
  fi
else
  # Replace placeholder with date (pre-render)
  date=$(git log -1 --format='%ad' --date=short -- index.qmd 2>/dev/null || echo "unknown")
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/__LAST_MODIFIED__/$date/g" index.qmd
  else
    sed -i "s/__LAST_MODIFIED__/$date/g" index.qmd
  fi
fi
