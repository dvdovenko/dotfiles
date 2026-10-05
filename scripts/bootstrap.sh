#!/usr/bin/env bash
#
# Bootstrap Nix + this dotfiles repo on a fresh box: installs Nix if it's
# missing, clones (or updates) the repo, installs Homebrew if missing,
# activates the right flake target,
# then applies the dotfiles with chezmoi. Idempotent on re-run.
#
# Remote, nothing cloned yet (VPS, devcontainer, OrbStack VM, ...):
#   curl -fsSL https://raw.githubusercontent.com/dvdovenko/dotfiles/main/scripts/bootstrap.sh | bash
#
# Local, repo already cloned:
#   ./scripts/bootstrap.sh
#   make bootstrap
#
# Env overrides: DOTFILES_DIR (default ~/dotfiles), DOTFILES_REPO,
# DOTFILES_PROFILE (core for VPS, full for home).

set -euo pipefail

nix_only=false
case "${1:-}" in
  '') ;;
  --nix-only) nix_only=true ;;
  *) echo 'Usage: bootstrap.sh [--nix-only]' >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
  echo 'Usage: bootstrap.sh [--nix-only]' >&2
  exit 2
fi

# home-manager's own activation script (and our flake's builtins.getEnv
# "USER") both expect $USER — a real login shell always has it, but a bare
# `docker exec`/cron/some Ansible become setups only guarantee $HOME.
export USER="${USER:-$(id -un)}"
if [ -z "${HOME:-}" ]; then
  HOME="$(getent passwd "$USER" 2>/dev/null | cut -d: -f6)"
  [ -z "$HOME" ] && [ "$(uname -s)" = "Darwin" ] && HOME="/Users/$USER"
  [ -z "$HOME" ] && HOME="/home/$USER"
  export HOME
fi

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/dvdovenko/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

DOTFILES_PROFILE="${DOTFILES_PROFILE:-core}"
case "$DOTFILES_PROFILE" in
  core) profile_suffix="" ;;
  full) profile_suffix="-full" ;;
  *) echo "bootstrap: DOTFILES_PROFILE must be core or full" >&2; exit 1 ;;
esac

os="$(uname -s)"
arch="$(uname -m)"

if [ "$os" = Linux ] && [ "$DOTFILES_PROFILE" != core ]; then
  echo "bootstrap: Linux/VPS supports only DOTFILES_PROFILE=core" >&2
  exit 1
fi

case "$arch" in
  x86_64) vps_arch="x86_64" ;;
  aarch64|arm64) vps_arch="aarch64" ;;
  *)
    echo "bootstrap: unsupported architecture '$arch'" >&2
    exit 1
    ;;
esac

# No /run/systemd/system means no systemd to hand the nix-daemon service
# to (true in a plain Docker/devcontainer base image) — the installer's
# default plan tries to register a systemd unit and fails outright there,
# so fall back to --init none and supervise the daemon ourselves below.
no_systemd=false
if [ "$os" = "Linux" ] && [ ! -d /run/systemd/system ]; then
  no_systemd=true
fi

source_nix() {
  local profile
  for profile in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    # shellcheck disable=SC1090
    [[ ! -e "$profile" ]] || . "$profile"
  done
}
source_nix

if ! command -v nix >/dev/null 2>&1; then
  echo "==> Nix not found, installing (Determinate Systems installer)"
  plan_args=()
  if [ "$no_systemd" = true ]; then
    echo "==> No systemd detected (container?) — installing with --init none"
    plan_args=(linux --init none)
  fi
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install "${plan_args[@]}" --no-confirm
else
  echo "==> Nix already installed ($(nix --version))"
fi

source_nix

# --init none means nothing starts nix-daemon for us (no systemd, no
# launchd) — start it by hand if it isn't already up. Real VPS installs
# use the default plan instead, where systemd owns this.
if [ "$no_systemd" = true ] && ! nix --extra-experimental-features "nix-command flakes" store ping >/dev/null 2>&1; then
  echo "==> Starting nix-daemon manually (no systemd to supervise it)"
  # Absolute path, not just `nix-daemon`: sudo resets $PATH (secure_path),
  # which doesn't include the Nix profile's bin dir.
  sudo /nix/var/nix/profiles/default/bin/nix-daemon >/tmp/nix-daemon.log 2>&1 &
  disown
  sleep 1
fi

if [ -d "$DOTFILES_DIR/.git" ]; then
  echo "==> $DOTFILES_DIR already cloned, pulling latest (fast-forward only)"
  git -C "$DOTFILES_DIR" pull --ff-only || echo "==> pull skipped (local changes or diverged) — continuing with what's on disk"
else
  echo "==> Cloning $DOTFILES_REPO to $DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# nix-darwin also owns declarative Homebrew packages on macOS.
if [ "$nix_only" = false ] || [ "$os" = Darwin ]; then
  bash "$DOTFILES_DIR/scripts/setup-homebrew.sh"
fi

if [ "$os" = "Darwin" ]; then
  # darwin/configuration.nix is tied to one specific machine (hostname +
  # username baked into flake.nix) — this only really applies on that Mac.
  echo "==> Activating nix-darwin config"
  sudo -H "$(command -v nix)" run --inputs-from "path:$DOTFILES_DIR/nix" \
    nix-darwin -- switch --flake "path:$DOTFILES_DIR/nix#danylo-mbp${profile_suffix}"
else
  echo "==> Activating home-manager config (vps@${vps_arch}-linux)"
  nix run --extra-experimental-features "nix-command flakes" \
    --inputs-from "path:$DOTFILES_DIR/nix" home-manager -- switch --flake "./nix#vps@${vps_arch}-linux" --impure
fi

if [ "$nix_only" = false ]; then
  "$DOTFILES_DIR/scripts/apply-dotfiles.sh"
  "$DOTFILES_DIR/scripts/install-plugins.sh"
fi

echo "==> Done."
