{ config, pkgs, username, homeDirectory, ... }:

{
  imports = [ ./dotfiles.nix ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  home.packages = import ../shared/cli-packages.nix { inherit pkgs; };

  programs.home-manager.enable = true;

  # Standalone home-manager on a non-NixOS Linux box (plain Ubuntu/Debian
  # VPS with just Nix installed) needs this so things like fontconfig and
  # XDG paths resolve the way packages expect on a "real" NixOS.
  targets.genericLinux.enable = true;
}
