{ pkgs, ... }:

{
  # Everything tap-based, versioned/pinned, or brew-specific stays on
  # Homebrew instead (see ./homebrew.nix). The portable list is shared with
  # the Linux/VPS home-manager config — see ../shared/cli-packages.nix.
  environment.systemPackages = import ../shared/cli-packages.nix { inherit pkgs; };
}
