{ config, pkgs, username, ... }:

{
  imports = [ ./dotfiles.nix ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # No programs.zsh / programs.git / programs.neovim / programs.tmux here —
  # their config files are symlinked directly via dotfiles.nix instead, and
  # home-manager would refuse to manage the same target path twice.
}
