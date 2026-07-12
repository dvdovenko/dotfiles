# Portable CLI tools + language toolchains, shared between the macOS
# nix-darwin config (darwin/packages.nix, as environment.systemPackages) and
# any standalone Linux/VPS home-manager config (home/home-linux.nix, as
# home.packages). Keep this list to things that build the same way
# everywhere — OS-specific or tap-only tools stay in darwin/homebrew.nix.
{ pkgs }:

with pkgs; [
  # core dev tooling
  git
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
  trash-cli
  watchman
  htop

  # editors / multiplexer / prompt
  tmux
  neovim
  starship

  # build essentials
  coreutils
  gnumake
  automake
  libtool
  pkg-config

  # languages / toolchains
  go
  fnm
  nodejs
  rustup
  python311

  # misc
  pass
  uv
  pipx
  sshpass
  mkcert
]
