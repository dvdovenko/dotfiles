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
  [[ "$EDITOR" == nano && "$VISUAL" == nano && "$aliases[vim]" == nano ]] || exit 1
  [[ "$saliases[md]" == cat && "$saliases[yaml]" == cat ]] || exit 1
  (( ! $+aliases[flushdns] && ! $+galiases[C] )) || [[ "$OSTYPE" == darwin* ]] || exit 1
' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
[[ ! -e "$target/forbidden" ]] || { cat "$target/forbidden"; exit 1; }
if grep -E 'command not found|no such file|not found:' "$target/output"; then exit 1; fi
echo 'shell startup: optional tools absent, inherited PATH preserved, no installers/network calls'

# Codex loads a trusted shell-compatible .env only when invoked.
mkdir -p "$target/.codex" "$target/custom-codex"
printf 'CODEX_ENV_TEST=default\n' > "$target/.codex/.env"
printf 'CODEX_ENV_TEST=custom\n' > "$target/custom-codex/.env"
cat > "$target/bin/codex" <<'EOF'
#!/bin/sh
[ "${CODEX_ENV_TEST:-missing}" = "$1" ] && [ "$2" = 'argument with spaces' ]
EOF
chmod +x "$target/bin/codex"
HOME="$target" ZDOTDIR="$target/.config/zsh" PATH="$target/bin" CODEX_ENV_TEST= "$zsh_bin" -d -i -c '
  unset CODEX_HOME
  [[ -z "$CODEX_ENV_TEST" ]] || exit 1
  codex default "argument with spaces" || exit 1
  [[ -z "$CODEX_ENV_TEST" ]] || exit 1
  CODEX_HOME="$HOME/custom-codex" codex custom "argument with spaces" || exit 1
  CODEX_HOME="$HOME/absent" codex missing "argument with spaces" || exit 1
  print -r -- "return 7" > "$HOME/custom-codex/.env"
  CODEX_HOME="$HOME/custom-codex" codex custom "argument with spaces"
  [[ $? == 7 ]] || exit 1
' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
echo 'Codex: scoped env loading, CODEX_HOME, argument forwarding, missing file and source failure'

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

# Exercise both tool sets, including a file name that needs quoting.
export SHELL_TEST_LOG="$target/commands.log"
for cmd in nano cat less git; do
  printf '#!/bin/sh\nprintf "%%s\\n" "%s${*:+ }$*" >> "$SHELL_TEST_LOG"\n' "$cmd" > "$target/bin/$cmd"
  chmod +x "$target/bin/$cmd"
done
cat > "$target/bin/fzf" <<'EOF'
#!/bin/sh
[ "$1" != --zsh ] || exit 0
exit 1
EOF
chmod +x "$target/bin/fzf"
git_bin="$(command -v git)"
for tools in slim core; do
  if [[ "$tools" = core ]]; then
    mkdir -p "$target/.local/bin"
    printf '#!/bin/sh\nprintf "%%s\\n" "nvim${*:+ }$*" >> "$SHELL_TEST_LOG"\n' > "$target/.local/bin/nvim"
    chmod +x "$target/.local/bin/nvim"
    for cmd in bat delta lazygit; do
      printf '#!/bin/sh\nprintf "%%s\\n" "%s${*:+ }$*" >> "$SHELL_TEST_LOG"\n' "$cmd" > "$target/bin/$cmd"
      chmod +x "$target/bin/$cmd"
    done
  fi
  : > "$SHELL_TEST_LOG"
  HOME="$target" ZDOTDIR="$target/.config/zsh" PATH="$target/bin" "$zsh_bin" -d -i -c '
    if (( $+commands[nvim] )); then
      [[ "$(command -v nvim)" == "$HOME/.local/bin/nvim" ]] || exit 1
      [[ "$EDITOR" == nvim && "$VISUAL" == nvim && "$aliases[vim]" == nvim ]] || exit 1
      for suffix in go js jsx ts tsx; do
        [[ "$saliases[$suffix]" == nvim ]] || exit 1
      done
      [[ "$saliases[md]" == bat && "$saliases[yaml]" == "bat -l yaml" ]] || exit 1
      [[ "$_FZF_PREVIEW_CMD" == "bat "* ]] || exit 1
    else
      [[ "$EDITOR" == nano && "$aliases[vim]" == nano ]] || exit 1
      [[ "$_FZF_PREVIEW_CMD" == "cat {}" ]] || exit 1
    fi
    eval "${_FZF_PREVIEW_CMD//\{\}/\"file with spaces\"}"
  ' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
  editor="$(GIT_CONFIG_GLOBAL="$repo/home/dot_gitconfig" GIT_CONFIG_NOSYSTEM=1 "$git_bin" config core.editor)"
  pager="$(GIT_CONFIG_GLOBAL="$repo/home/dot_gitconfig" GIT_CONFIG_NOSYSTEM=1 "$git_bin" config core.pager)"
  filter="$(GIT_CONFIG_GLOBAL="$repo/home/dot_gitconfig" GIT_CONFIG_NOSYSTEM=1 "$git_bin" config interactive.diffFilter)"
  PATH="$target/bin:$target/.local/bin:/usr/bin:/bin" sh -c "$editor \"file with spaces\""
  PATH="$target/bin:/usr/bin:/bin" sh -c "$pager"
  PATH="$target/bin:/usr/bin:/bin" sh -c "$filter"
  popup="$(sed -n "/^bind g /s/.*80% '\(.*\)'$/\1/p" "$repo/home/dot_config/tmux/tmux.conf")"
  [[ -n "$popup" ]]
  PATH="$target/bin:/usr/bin:/bin" sh -c "$popup"
  if [[ "$tools" = slim ]]; then
    grep -qx 'nano file with spaces' "$SHELL_TEST_LOG"
    grep -qx 'cat file with spaces' "$SHELL_TEST_LOG"
    grep -qx less "$SHELL_TEST_LOG"
    grep -qx cat "$SHELL_TEST_LOG"
    grep -qx 'less -R' "$SHELL_TEST_LOG"
  else
    grep -qx 'nvim file with spaces' "$SHELL_TEST_LOG"
    grep -qx 'bat --color=always --style=plain,numbers --line-range=:500 file with spaces' "$SHELL_TEST_LOG"
    grep -qx delta "$SHELL_TEST_LOG"
    grep -qx 'delta --color-only' "$SHELL_TEST_LOG"
    grep -qx lazygit "$SHELL_TEST_LOG"
  fi
done
[[ "$(GIT_CONFIG_GLOBAL="$repo/home/dot_gitconfig" GIT_CONFIG_NOSYSTEM=1 "$git_bin" config filter.lfs.required)" = true ]]
# Required LFS filters must reject checkout when git-lfs is absent.
ln -s /bin/sh "$target/bin/sh"
"$git_bin" init -q "$target/lfs"
printf '*.bin filter=lfs\n' > "$target/lfs/.gitattributes"
blob="$(printf 'version https://git-lfs.github.com/spec/v1\noid sha256:%064d\nsize 1\n' 0 | "$git_bin" -C "$target/lfs" hash-object -w --stdin)"
"$git_bin" -C "$target/lfs" update-index --add --cacheinfo "100644,$blob,payload.bin"
if GIT_CONFIG_GLOBAL="$repo/home/dot_gitconfig" GIT_CONFIG_NOSYSTEM=1 PATH="$target/bin" \
  "$git_bin" -C "$target/lfs" checkout-index -a > "$target/output" 2>&1; then
  echo 'LFS checkout unexpectedly succeeded without git-lfs' >&2
  exit 1
fi
grep -q git-lfs "$target/output"
echo 'shell, Git, fzf preview and tmux popup: slim fallbacks and core tools'

if command -v fzf >/dev/null 2>&1; then
  HOME="$target" ZDOTDIR="$target/.config/zsh" "$zsh_bin" -d -i -c '
    [[ -n "$widgets[fzf-file-widget]" && -n "$FZF_CTRL_T_OPTS" ]] || exit 1
    [[ "$(printf "match\nother\n" | fzf --filter "^match$")" == match ]] || exit 1
  ' > "$target/output" 2>&1 || { cat "$target/output"; exit 1; }
  echo 'fzf: installed zsh integration and file filtering'
fi

# Parse the actual tmux config on an isolated server; no personal plugins run.
if command -v tmux >/dev/null 2>&1; then
  HOME="$target" tmux -S "$target/tmux.sock" -f "$repo/home/dot_config/tmux/tmux.conf" new-session -d -s check
  tmux -S "$target/tmux.sock" list-keys | grep -q 'git -c color.ui=always log'
  tmux -S "$target/tmux.sock" kill-server
  echo 'tmux: config loaded on isolated server'
fi
