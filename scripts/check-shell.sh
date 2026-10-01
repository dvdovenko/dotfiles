#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
zsh_bin="$(command -v zsh)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT
mkdir -p "$target/.config/zsh" "$target/bin"
cp "$repo/home/dot_zshenv" "$target/.zshenv"
cp "$repo/home/dot_config/zsh/"*.zsh "$target/.config/zsh/"
cp "$repo/home/dot_config/zsh/dot_zshrc" "$target/.config/zsh/.zshrc"
cp "$repo/home/dot_config/zsh/dot_zshenv" "$target/.config/zsh/.zshenv"
# Only mkdir is available; optional tools are absent. Installer/network calls fail.
ln -s "$(command -v mkdir)" "$target/bin/mkdir"
for cmd in git curl wget brew sudo apt-get yum apk pacman doppler fnm; do
  printf '#!/bin/sh\necho "%s called" >> "$HOME/forbidden"\nexit 1\n' "$cmd" > "$target/bin/$cmd"
  chmod +x "$target/bin/$cmd"
done
HOME="$target" ZDOTDIR="$target/.config/zsh" PATH="$target/bin" "$zsh_bin" -d -i -c '
  [[ "$PATH" == "$HOME/bin:"* ]] || exit 1
  [[ "$EDITOR" == nvim ]] || exit 1
  (( ! $+aliases[flushdns] && ! $+galiases[C] )) || [[ "$OSTYPE" == darwin* ]] || exit 1
' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
[[ ! -e "$target/forbidden" ]] || { cat "$target/forbidden"; exit 1; }
if grep -E 'command not found|no such file|not found:' "$target/output"; then exit 1; fi
echo 'shell startup: optional tools absent, inherited PATH preserved, no installers/network calls'
