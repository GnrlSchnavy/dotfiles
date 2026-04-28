{
  description = "Yvan nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim framework. We build the nvim derivation per-host inline
    # below so we can parameterize flakePath/darwinHost without
    # hardcoding them in nixvim/config/.
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nix-homebrew,
      home-manager,
      nixvim,
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

      # Build a per-host nvim. flakePath and darwinHost are derived from
      # the host descriptor so a different user/host doesn't require
      # editing nixvim/config/default.nix.
      mkNvim =
        pkgs: host:
        nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
          inherit pkgs;
          module = import ./nixvim/config;
          extraSpecialArgs = {
            flakePath = "/Users/${host.username}/.dotfiles/nix";
            darwinHost = host.hostname;
          };
        };

      # Build a darwin configuration from a host descriptor.
      # See hosts/m4/default.nix for the expected shape.
      mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = sharedModules ++ [
            host.module
            { system.configurationRevision = self.rev or self.dirtyRev or null; }

            # Add the per-host parameterized nvim to systemPackages.
            ({ pkgs, ... }: {
              environment.systemPackages = [ (mkNvim pkgs host) ];
            })

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
                # Auto-back up files home-manager would otherwise refuse
                # to overwrite (e.g. an existing ~/.zshenv from nix-darwin
                # or a stale Stow symlink). Backups land alongside the
                # original with the .hm-backup suffix.
                backupFileExtension = "hm-backup";
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
