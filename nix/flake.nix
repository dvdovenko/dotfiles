{
  description = "Danylo's nix-darwin + home-manager config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    hostname = "danylo-mbp";
    username = "danylo";
    system = "aarch64-darwin";

    # Standalone home-manager for any Linux box (VPS or otherwise) that has
    # Nix installed but isn't NixOS/nix-darwin-managed — just packages +
    # the same dotfile symlinks as the Mac, no system-level config.
    #
    # Username/home dir come from $USER/$HOME at build time (needs --impure)
    # instead of being hardcoded, so the same "vps@<system>" target works
    # for whichever user Ansible runs home-manager as.
    mkVpsHome = linuxSystem: home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = linuxSystem;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        username = builtins.getEnv "USER";
        homeDirectory = builtins.getEnv "HOME";
      };
      modules = [ ./home/home-linux.nix ];
    };
  in
  {
    darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit username; };
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit username; };
          home-manager.users.${username} = import ./home/home.nix;
        }
      ];
    };

    homeConfigurations = {
      "vps@x86_64-linux" = mkVpsHome "x86_64-linux";
      "vps@aarch64-linux" = mkVpsHome "aarch64-linux";
    };
  };
}
