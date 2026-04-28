{
  description = "Yvan nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixvim = {
      # url = "github:mikaelfangel/nixvim-config";
      url = "./nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nix-homebrew,
      home-manager,
      ...
    }:
    let
      # Modules shared across every host. Anything machine-specific
      # (hostname, primary user, arch) lives in hosts/<name>/default.nix.
      sharedModules = [
        ./modules/packages.nix
        ./modules/homebrew.nix
        ./modules/nix.nix
        ./modules/system.nix
        ./modules/dock.nix
        ./modules/environment.nix
      ];

      # Build a darwin configuration from a host descriptor.
      # See hosts/m4/default.nix for the expected shape.
      mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = sharedModules ++ [
            host.module
            { system.configurationRevision = self.rev or self.dirtyRev or null; }

            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = host.username;
                autoMigrate = true;
              };
            }

            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs; };
                users.${host.username} = import ./home;
              };
            }
          ];
        };

      hosts = {
        m4 = import ./hosts/m4;
        # Add additional hosts here, e.g.:
        # m5 = import ./hosts/m5;
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs (_: host: mkDarwin host) hosts;
    };
}
