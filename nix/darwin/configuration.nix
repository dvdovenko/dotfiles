{ pkgs, username, ... }:

{
  imports = [
    ./packages.nix
    ./homebrew.nix
    ./macos.nix
  ];

  # Nix itself (daemon, nix.conf, GC) is managed by the Determinate Systems
  # installer already present on this machine, not by nix-darwin.
  nix.enable = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  system.primaryUser = username;
  networking.hostName = "danylo-mbp";

  users.users.${username}.home = "/Users/${username}";

  # Lets macOS's /etc/zshenv pick up the nix-installed environment.
  # ~/.zshrc itself is still symlinked from ~/dotfiles by home-manager.
  programs.zsh.enable = true;

  system.stateVersion = 6;
}
