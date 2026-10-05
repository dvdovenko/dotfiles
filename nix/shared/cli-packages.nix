# Portable CLI tools + language toolchains, shared between the macOS
# nix-darwin config (darwin/packages.nix, as environment.systemPackages) and
# any standalone Linux/VPS home-manager config (home/home-linux.nix, as
# home.packages). Keep this list to things that build the same way
# everywhere — OS-specific or tap-only tools stay in darwin/homebrew.nix.
{ pkgs, profile ? "core" }:

with pkgs; [
  # VPS/devcontainers: project runtimes come from Devbox.
  git
  git-lfs
  openssh
  unzip
  less
  file
  rtk
  gh
  curl
  delta
  watchman
  tree
  just
  ncdu
  htop

  # shell/CLI ergonomics
  ripgrep
  fd
  fzf
  bat
  eza
  zoxide
  jq
  lazygit

  # editors / multiplexer / prompt
  tmux
  neovim
  starship
  chezmoi

  # Commands used by bootstrap and this repository.
  coreutils
  gnumake

] ++ lib.optionals (profile == "full") [
  # Home setup: extra diagnostics, credentials and standalone toolchains.
  rsync
  gnupg
  tig
  pass
  uv
  sshpass
  mkcert

  devbox
  codex
  claude-code
  trash-cli
  automake
  libtool
  pkg-config
  go
  fnm
  nodejs
  rustup
  python311
  pipx
]
