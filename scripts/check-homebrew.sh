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
echo 'homebrew: macOS/Linux reuse, shellenv, bundle/check flags, failure propagation, invalid action and unsupported OS passed'
