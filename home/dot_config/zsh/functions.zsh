#! /bin/zsh

# Load secrets only for Codex and its children, not the calling shell.
codex() (
  local env_file="${CODEX_HOME:-$HOME/.codex}/.env"
  if [[ -f "$env_file" ]]; then
    set -a
    source "$env_file" || return
    set +a
  fi
  command codex "$@"
)

# Colormap
function colormap() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}
