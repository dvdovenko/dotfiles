#!/usr/bin/env bash
# Fuzzy-pick a Host from ~/.ssh/config and ssh into it.
# Bound to `prefix + S` in tmux.conf.

set -euo pipefail

host=$(awk '/^[Hh]ost[[:space:]]/ {for (i=2;i<=NF;i++) if ($i !~ /[*?]/) print $i}' ~/.ssh/config 2>/dev/null | sort -u | fzf --prompt="ssh> ")

if [[ -z "${host:-}" ]]; then
  exit 0
fi

exec ssh "$host"
