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
cp "$repo/home/dot_config/zsh/dot_zprofile" "$target/.config/zsh/.zprofile"
# Only mkdir is available; optional tools are absent. Installer/network calls fail.
ln -s "$(command -v mkdir)" "$target/bin/mkdir"
for cmd in git curl wget brew sudo apt-get yum apk pacman doppler; do
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

# Login shells may initialize an installed brew, but must not invoke installers.
cat > "$target/bin/brew" <<'EOF'
#!/bin/sh
if [ "$1" != shellenv ]; then
  echo "unexpected brew command: $*" >> "$HOME/forbidden"
  exit 1
fi
printf 'export HOMEBREW_PREFIX=/test/homebrew\nexport PATH=/test/homebrew/bin:/test/homebrew/sbin:$PATH\n'
EOF
HOME="$target" ZDOTDIR="$target/.config/zsh" PATH="$target/bin" "$zsh_bin" -d -i -c '
  # Redirect standard prefix detection to the isolated fixture.
  source <(while IFS= read -r line; do
    line="${line//\/opt\/homebrew/$HOME}"
    print -r -- "${line//\/home\/linuxbrew\/.linuxbrew/$HOME}"
  done < "$ZDOTDIR/.zprofile")
  [[ "$PATH" == "$HOME/bin:"* ]] || exit 1
  [[ "$HOMEBREW_PREFIX" == /test/homebrew ]] || exit 1
  [[ "${path[-2]}" == /test/homebrew/bin ]] || exit 1
  [[ "${path[-1]}" == /test/homebrew/sbin ]] || exit 1
' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
[[ ! -e "$target/forbidden" ]] || { cat "$target/forbidden"; exit 1; }
echo 'Homebrew initialization: inherited PATH first, brew paths available, shellenv only'

# An installed fnm must initialize Node and package-manager commands.
cat > "$target/bin/fnm" <<'EOF'
#!/bin/sh
if [ "$*" != 'env --use-on-cd --shell zsh' ]; then
  echo "unexpected fnm command: $*" >> "$HOME/forbidden"
  exit 1
fi
printf 'export PATH="$HOME/fnm/bin:$PATH"\n'
EOF
chmod +x "$target/bin/fnm"
mkdir -p "$target/fnm/bin"
printf '#!/bin/sh\nprintf "12.8.1\\n"\n' > "$target/fnm/bin/pnpm"
chmod +x "$target/fnm/bin/pnpm"
HOME="$target" ZDOTDIR="$target/.config/zsh" PATH="$target/bin" "$zsh_bin" -d -i -c '
  [[ "$(command -v pnpm)" == "$HOME/fnm/bin/pnpm" ]] || exit 1
  [[ "$(pnpm -v)" == 12.8.1 ]] || exit 1
' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
[[ ! -e "$target/forbidden" ]] || { cat "$target/forbidden"; exit 1; }
echo 'fnm initialization: pnpm available without installing tools'
