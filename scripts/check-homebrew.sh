#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
target="$(mktemp -d)"
trap 'rm -rf "$target"' EXIT
mkdir -p "$target/bin" "$target/home"
export BREW_TEST_LOG="$target/log"
cat > "$target/bin/brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
[ "${BREW_TEST_FAIL:-0}" = 0 ] || exit 7
if [ "$1" = shellenv ]; then
  printf 'export HOMEBREW_PREFIX=/test/homebrew\n'
else
  [ "$HOMEBREW_PREFIX" = /test/homebrew ] || exit 1
  [ "$HOMEBREW_NO_AUTO_UPDATE" = 1 ] || exit 1
fi
EOF
cat > "$target/bin/uname" <<'EOF'
#!/bin/sh
echo "${BREW_TEST_OS:-Linux}"
EOF
cat > "$target/bin/curl" <<'EOF'
#!/bin/sh
echo unexpected-download >> "$BREW_TEST_LOG"
exit 1
EOF
chmod +x "$target/bin/"*
for os in Linux Darwin; do
  for action in install bundle check; do
    : > "$BREW_TEST_LOG"
    HOME="$target/home" PATH="$target/bin:$PATH" BREW_TEST_OS="$os" \
      bash "$repo/scripts/setup-homebrew.sh" "$action" > "$target/output"
    case "$action" in
      install) expected='shellenv' ;;
      bundle) expected=$(printf 'shellenv\nbundle install --file=%s/Brewfile --no-upgrade' "$repo") ;;
      check) expected=$(printf 'shellenv\nbundle check --file=%s/Brewfile --no-upgrade' "$repo") ;;
    esac
    [[ "$(cat "$BREW_TEST_LOG")" = "$expected" ]]
  done
done
if PATH="$target/bin:$PATH" BREW_TEST_FAIL=1 bash "$repo/scripts/setup-homebrew.sh" bundle > "$target/output" 2>&1; then
  echo 'brew failure unexpectedly succeeded' >&2
  exit 1
else
  [[ "$?" = 7 ]]
fi
: > "$BREW_TEST_LOG"
if PATH="$target/bin:$PATH" bash "$repo/scripts/setup-homebrew.sh" invalid > "$target/output" 2>&1; then
  echo 'invalid action unexpectedly succeeded' >&2
  exit 1
fi
[[ ! -s "$BREW_TEST_LOG" ]]
if PATH="$target/bin:$PATH" BREW_TEST_OS=FreeBSD bash "$repo/scripts/setup-homebrew.sh" > "$target/output" 2>&1; then
  echo 'unsupported OS unexpectedly succeeded' >&2
  exit 1
fi
[[ ! -s "$BREW_TEST_LOG" ]]

# Reproduce a container with Nix installed but curl absent from the outer PATH.
mkdir -p "$target/isolated" "$target/download"
for tool in bash dirname mktemp rm; do
  ln -s "$(command -v "$tool")" "$target/isolated/$tool"
done
cp "$target/bin/uname" "$target/isolated/uname"
printf '#!/bin/sh\necho 1000\n' > "$target/isolated/id"
cat > "$target/isolated/nix" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$BREW_TEST_LOG"
while [ "$1" != --command ]; do shift; done
shift
PATH="$BREW_TEST_DOWNLOAD:$PATH" exec "$@"
EOF
cat > "$target/download/curl" <<'EOF'
#!/bin/sh
for arg do installer="$arg"; done
/bin/cat > "$installer" <<'INSTALL'
[ "$NONINTERACTIVE" = 1 ] || exit 1
/bin/mkdir -p "$HOME/.linuxbrew/bin"
/bin/cp "$BREW_TEST_BREW" "$HOME/.linuxbrew/bin/brew"
INSTALL
EOF
chmod +x "$target/isolated/id" "$target/isolated/nix" "$target/download/curl"
: > "$BREW_TEST_LOG"
HOME="$target/home" PATH="$target/isolated" BREW_TEST_DOWNLOAD="$target/download" \
  BREW_TEST_BREW="$target/bin/brew" /bin/bash "$repo/scripts/setup-homebrew.sh" bundle > "$target/output"
expected=$(printf '%s\nshellenv\nbundle install --file=%s/Brewfile --no-upgrade' \
  "--extra-experimental-features nix-command flakes shell --inputs-from path:$repo/nix nixpkgs#curl --command bash $repo/scripts/setup-homebrew.sh bundle" "$repo")
[[ "$(cat "$BREW_TEST_LOG")" = "$expected" ]]
echo 'homebrew: macOS/Linux reuse, shellenv, bundle/check flags, failure propagation, invalid action and unsupported OS passed'
echo 'homebrew: missing curl supplied through pinned Nix shell passed'
