#!/usr/bin/env bash
#
# Bootstrap Nix + this dotfiles repo on a fresh box: installs Nix if it's
# missing, clones (or updates) the repo, then activates the right flake
# target for the current OS/arch. Idempotent — safe to re-run to pick up
# updates.
#
# Remote, nothing cloned yet (VPS, devcontainer, OrbStack VM, ...):
#   curl -fsSL https://raw.githubusercontent.com/dvdovenko/dotfiles/main/scripts/bootstrap.sh | bash
#
# Local, repo already cloned:
#   ./scripts/bootstrap.sh
#   make bootstrap
#
# Env overrides: DOTFILES_DIR (default ~/dotfiles — must stay ~/dotfiles,
# see the check below), DOTFILES_REPO.

set -euo pipefail

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

# home/dotfiles.nix derives the symlink source from home.homeDirectory +
# "/dotfiles", not from this script's DOTFILES_DIR — so an override that
# doesn't land at exactly $HOME/dotfiles produces dangling symlinks after
# activation succeeds (it won't error, so this is easy to miss).
if [ "$DOTFILES_DIR" != "$HOME/dotfiles" ]; then
  echo "==> WARNING: DOTFILES_DIR=$DOTFILES_DIR but the flake symlinks always" >&2
  echo "    target \$HOME/dotfiles ($HOME/dotfiles). Activation will 'succeed'" >&2
  echo "    but the symlinks it creates will dangle unless these match." >&2
fi

os="$(uname -s)"
arch="$(uname -m)"

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

# Pick up the daemon profile in this non-login shell so `nix` is on PATH
# for the rest of this script without needing a fresh shell.
for profile in \
  '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' \
  "$HOME/.nix-profile/etc/profile.d/nix.sh"
do
  # shellcheck disable=SC1090
  [ -e "$profile" ] && . "$profile"
done

# --init none means nothing starts nix-daemon for us (no systemd, no
# launchd) — start it by hand if it isn't already up. Real VPS installs
# use the default plan instead, where systemd owns this.
if [ "$no_systemd" = true ] && [ ! -S /nix/var/nix/daemon-socket/socket ]; then
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

if [ "$os" = "Darwin" ]; then
  # darwin/configuration.nix is tied to one specific machine (hostname +
  # username baked into flake.nix) — this only really applies on that Mac.
  echo "==> Activating nix-darwin config"
  nix run nix-darwin -- switch --flake ./nix
else
  echo "==> Activating home-manager config (vps@${vps_arch}-linux)"
  nix run --extra-experimental-features "nix-command flakes" \
    home-manager -- switch --flake "./nix#vps@${vps_arch}-linux" --impure
fi

echo "==> Done."
