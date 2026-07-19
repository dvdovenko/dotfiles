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
  # ~/.zshenv is symlinked directly by home-manager (nix/home/dotfiles.nix)
  # and exports ZDOTDIR=~/.config/zsh; ~/.zshrc itself is only reached
  # indirectly, via the whole-directory xdg.configFile "zsh" symlink.
  programs.zsh.enable = true;

  system.stateVersion = 6;
}
