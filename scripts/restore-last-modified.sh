#!/usr/bin/env bash
# Restores __LAST_MODIFIED__ placeholder in index.qmd (post-render)
"$(dirname "$0")/update-last-modified.sh" restore
