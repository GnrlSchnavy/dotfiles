{
  description = "Yvan nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew itself, overriding the release nix-homebrew pins.
    # Casks/formulae come from Homebrew's live API, so brew must keep up
    # with their DSL: 6.0.12 (nix-homebrew's pin) predates the
    # command_wrapper stanza current casks use, breaking brew bundle
    # ("Cask 'firefox' definition is invalid"). Bump the ref when brew
    # bundle hits another unknown-DSL error; drop the override once
    # nix-homebrew's own pin catches up.
    brew-src = {
      url = "github:Homebrew/brew/6.0.13";
      flake = false;
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };

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
      # Modules shared across every host. Per-host divergence (homebrew,
      # packages, dock, git) lives in hosts/<name>/ and is pulled in via
      # the host descriptor's systemModules / homeModules lists.
      sharedModules = [
        ./modules/nix.nix
        ./modules/system.nix
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
      #
      # systemModules / homeModules are the per-host module lists; they
      # default to [ ] so a descriptor can omit either.
      mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = sharedModules ++ (host.systemModules or [ ]) ++ [
            host.module
            { system.configurationRevision = self.rev or self.dirtyRev or null; }

            # Add the per-host parameterized nvim to systemPackages.
            ({ pkgs, ... }: {
              environment.systemPackages = [ (mkNvim pkgs host) ];
            })
          ]
          # nix-homebrew installs/manages the Homebrew prefix itself.
          # Hosts can opt out (manageHomebrew = false) to use a
          # pre-existing Homebrew install — the CI runner ships one in
          # a layout nix-homebrew's autoMigrate can't adopt (not a git
          # checkout). brew bundle still runs either way.
          ++ inputs.nixpkgs.lib.optionals (host.manageHomebrew or true) [
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = host.username;
                autoMigrate = true;
              };
            }
          ]
          ++ [
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
                # Shared home config (./home) plus this host's homeModules.
                users.${host.username} = {
                  imports = [ ./home ] ++ (host.homeModules or [ ]);
                };
              };
            }
          ];
        };

      hosts = {
        m4 = import ./hosts/m4;
        # CI fresh-install test target. Matches the GitHub Actions
        # macos-15 runner environment (user "runner", /Users/runner).
        # Not intended for use on a real machine.
        ci = import ./hosts/ci;
        m5 = import ./hosts/m5;
      };
    in
    {
      darwinConfigurations = builtins.mapAttrs (_: host: mkDarwin host) hosts;
    };
}
