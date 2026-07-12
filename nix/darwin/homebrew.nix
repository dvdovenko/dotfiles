{ ... }:

{
  # Homebrew stays declarative but non-destructive: cleanup = "none" means
  # `darwin-rebuild switch` only ever adds what's listed here, it never
  # uninstalls anything you install by hand with `brew install`.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };

    taps = [
      "dopplerhq/doppler"
      "homebrew/cask-versions"
      "localstack/tap"
      "mongodb/brew"
      "ngrok/ngrok"
      "oven-sh/bun"
    ];

    # Formulae that are tap-based, versioned/pinned, or otherwise stay on
    # Homebrew rather than nixpkgs (see ./packages.nix for what moved to Nix).
    brews = [
      "ansible"
      "ansible-lint"
      "bazel"
      "doppler"
      "ffmpeg"
      "ios-deploy"
      "jpeg"
      "minikube"
      "mole"
      "openssl@1.1"
      "podman"
      "rclone"
      "rtk"
      "zsh"
    ];

    casks = [
      "font-jetbrains-mono-nerd-font"
      "ghostty"
      "kap"
      "obsidian"
      "orbstack"
      "podman-desktop"
      "redis-insight"
      "spotify"
      "vlc"
    ];
  };
}
