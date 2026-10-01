# Portable CLI tools + language toolchains, shared between the macOS
# nix-darwin config (darwin/packages.nix, as environment.systemPackages) and
# any standalone Linux/VPS home-manager config (home/home-linux.nix, as
# home.packages). Keep this list to things that build the same way
# everywhere — OS-specific or tap-only tools stay in darwin/homebrew.nix.
{ pkgs, profile ? "core" }:

with pkgs; [
  # core dev tooling
  git
  git-lfs
  openssh
  rsync
  unzip
  less
  file
  rtk
  devbox
  codex
  claude-code
  gh
  curl
  delta
  gnupg

  # shell/CLI ergonomics
  ripgrep
  fd
  fzf
  bat
  eza
  zoxide
  tree
  jq
  just
  ncdu
  tig
  lazygit
  htop

  # editors / multiplexer / prompt
  tmux
  neovim
  starship
  chezmoi

  # build essentials
  coreutils
  gnumake

  # misc
  pass
  uv
  sshpass
  mkcert
] ++ lib.optionals (profile == "full") [
  trash-cli
  watchman
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
