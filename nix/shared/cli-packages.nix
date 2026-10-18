# Portable CLI tools + language toolchains, shared between the macOS
# nix-darwin config (darwin/packages.nix, as environment.systemPackages) and
# any standalone Linux/VPS home-manager config (home/home-linux.nix, as
# home.packages). Keep this list to things that build the same way
# everywhere — OS-specific or tap-only tools stay in darwin/homebrew.nix.
{ pkgs, profile ? "core" }:

with pkgs; if profile == "slim" then [
  gitMinimal openssh curl less
  zsh tmux starship chezmoi coreutils gnumake gnused nano
  ripgrep fd fzf jq
] else [
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

  chezmoi

  # Commands used by bootstrap and this repository.
  coreutils
  gnumake
  gnused
  devbox

] ++ lib.optionals stdenv.hostPlatform.isLinux [
  # macOS owns these through Homebrew; Linux core must work without Brew.
  tmux neovim starship
] ++ lib.optionals (profile == "full") [
  # Extra credentials and build tools; macOS runtimes live in Homebrew.
  gnupg
  automake
  libtool
]
