#!/usr/bin/env bash
# Install Homebrew explicitly; shell startup only initializes it.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
action="${1:-install}"
case "$action" in
  install|bundle|check) ;;
  *) echo "Usage: $0 [install|bundle|check]" >&2; exit 2 ;;
esac

case "$(uname -s)" in
  Darwin) prefixes=(/opt/homebrew /usr/local) ;;
  Linux) prefixes=(/home/linuxbrew/.linuxbrew "$HOME/.linuxbrew") ;;
  *) echo "homebrew: only macOS and Linux are supported" >&2; exit 1 ;;
esac

find_brew() {
  brew_bin="$(command -v brew || true)"
  if [ -z "$brew_bin" ]; then
    for prefix in "${prefixes[@]}"; do
      if [ -x "$prefix/bin/brew" ]; then
        brew_bin="$prefix/bin/brew"
        break
      fi
    done
  fi
}

find_brew
if [ -z "$brew_bin" ]; then
  if [ "$action" = check ]; then
    echo "homebrew: not installed; run make brew-install" >&2
    exit 1
  fi
  if [ "$(id -u)" -eq 0 ]; then
    echo "homebrew: run setup as a non-root user with sudo access" >&2
    exit 1
  fi
  echo "==> Installing Homebrew"
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  NONINTERACTIVE=1 /bin/bash "$installer"
  find_brew
  if [ -z "$brew_bin" ]; then
    echo "homebrew: installation finished but brew was not found" >&2
    exit 1
  fi
fi

brew_env="$("$brew_bin" shellenv)"
eval "$brew_env"
case "$action" in
  install) echo "==> Homebrew available at $brew_bin" ;;
  bundle) HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" bundle install --file="$repo/Brewfile" --no-upgrade ;;
  check) HOMEBREW_NO_AUTO_UPDATE=1 "$brew_bin" bundle check --file="$repo/Brewfile" --no-upgrade ;;
esac
