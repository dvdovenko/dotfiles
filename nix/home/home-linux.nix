{ config, pkgs, username, homeDirectory, profile, ... }:

{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  home.packages = (import ../shared/cli-packages.nix { inherit pkgs profile; })
    ++ pkgs.lib.optionals (profile != "slim") [ pkgs.zsh ];

  programs.home-manager.enable = profile != "slim";
  manual = pkgs.lib.mkIf (profile == "slim") {
    html.enable = false;
    manpages.enable = false;
    json.enable = false;
  };
  systemd.user.enable = profile != "slim";

  # Standalone home-manager on a non-NixOS Linux box (plain Ubuntu/Debian
  # VPS with just Nix installed) needs this so things like fontconfig and
  # XDG paths resolve the way packages expect on a "real" NixOS.
  targets.genericLinux.enable = profile != "slim";
  targets.genericLinux.gpu.enable = false;
  xdg.mime.enable = false;
  xdg.mimeApps.enable = false;
}
