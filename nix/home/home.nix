{ config, pkgs, username, inputs, ... }:

{
  imports = [ ./nvf.nix ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # chezmoi deploys dotfiles after the Nix switch.
}
