{
  description = "Yvan nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixvim = {
      # url = "github:mikaelfangel/nixvim-config";
      url = "./nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      nixvim,
    }:
    let
      # Host-specific configuration (kept inline as it's unique to this host)
      hostModule = { ... }: {
        # Allow 'paid' applications to be set in flake config
        nixpkgs.config.allowUnfree = true;

        # Necessary for using flakes on this system
        nix.settings.experimental-features = "nix-command flakes";

        # Set Git commit hash for darwin-version
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing
        system.stateVersion = 5;

        # The platform the configuration will be used on
        nixpkgs.hostPlatform = "aarch64-darwin";

        # Primary user for system-wide options
        system.primaryUser = "yvan";
      };

    in
    {
      darwinConfigurations."m4" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # Import modular configurations from files
          ./modules/packages.nix
          ./modules/homebrew.nix
          ./modules/system.nix
          ./modules/dock.nix
          ./modules/environment.nix
          hostModule
          
          # nix-homebrew configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon Only
              enableRosetta = true;
              # User owning the homebrew prefix
              user = "yvan";
              autoMigrate = true;
              # extraFlags = [];
            };
          }
        ];
      };
    };
}

