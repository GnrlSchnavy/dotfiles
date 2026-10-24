{
  description = "Yvan nix-darwin system flake";

  inputs = {
    # The -darwin branch is the one Hydra tests and caches for macOS.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Its bin/brew launcher is written for the brew it pins (brew-src), so
    # don't override that pin (6.0.13 under the 7.0.4 launcher died with
    # `key not found: "HOMEBREW_ORIGINAL_BREW_FILE"`); for a newer brew,
    # update nix-homebrew. tests/flake-lock.sh fails on an override.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim framework. We build the nvim derivation per-host inline
    # below so we can parameterize flakePath/darwinHost without
    # hardcoding them in nixvim/config/.
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
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
      # Modules shared across every host. What differs per role (apps, git
      # identity, Claude Code) lives in profiles/<name>/, picked by the host
      # descriptor's `profiles` list; what differs per machine lives in
      # hosts/<name>/ (systemModules / homeModules).
      sharedModules = [
        ./modules/nix.nix
        ./modules/system.nix
        ./modules/environment.nix
        ./modules/homebrew.nix
      ];

      # A host's modules of one kind ("systemModules" or "homeModules"): its
      # profiles' first, then its own. See profiles/README.md.
      hostModules =
        kind: host:
        builtins.concatMap (p: (import ./profiles/${p}).${kind} or [ ]) (host.profiles or [ ])
        ++ (host.${kind} or [ ]);

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
      # See hosts/m5/default.nix for the expected shape.
      #
      # profiles, systemModules and homeModules default to [ ] so a
      # descriptor can omit any of them.
      mkDarwin =
        host:
        nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules =
            sharedModules
            ++ hostModules "systemModules" host
            ++ [
              host.module
              {
                system.configurationRevision = self.rev or self.dirtyRev or null;
                # Which darwinConfiguration this machine is. Rebuild commands
                # and scripts prefer it over `scutil --get LocalHostName`, so
                # a Mac whose hostname is managed (the work Mac) still finds
                # its host.
                environment.variables.DOTFILES_HOST = host.hostname;
              }

              # Add the per-host parameterized nvim to systemPackages.
              ({ pkgs, ... }: {
                environment.systemPackages = [ (mkNvim pkgs host) ];
              })
            ]
            # nix-homebrew installs/manages the Homebrew prefix itself.
            # Hosts can opt out (manageHomebrew = false) to use a
            # pre-existing Homebrew install; brew bundle still runs either
            # way. None do: CI moves the runner's own Homebrew aside.
            ++ inputs.nixpkgs.lib.optionals (host.manageHomebrew or true) [
              nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  enable = true;
                  # No Intel prefix (/usr/local): nothing here needs x86-only
                  # brews. Rosetta itself, for x86 apps, is separate.
                  enableRosetta = false;
                  user = host.username;
                  autoMigrate = true;
                  # Set in the brew launcher itself, so it holds for
                  # activation and the shell alike.
                  extraEnv.HOMEBREW_NO_ANALYTICS = "1";
                };
              }
              ./modules/homebrew-trust.nix
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
                  # Shared home config (./home) plus the profiles' and the
                  # host's homeModules.
                  users.${host.username} = {
                    imports = [ ./home ] ++ hostModules "homeModules" host;
                  };
                };
              }
            ];
        };

      hosts = {
        # Personal Mac.
        m5 = import ./hosts/m5;
        # Client-issued work Mac.
        work = import ./hosts/work;
        # CI fresh-install test targets on the GitHub Actions xcode-27
        # (macOS 27) runner (user "runner", /Users/runner): m5's profiles,
        # and the work Mac's. Not intended for use on a real machine.
        ci = import ./hosts/ci;
        ci-work = import ./hosts/ci-work;
      };

      # The Mac, plus Linux for the CI runner.
      forAllSystems =
        f:
        inputs.nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (
          system: f inputs.nixpkgs.legacyPackages.${system}
        );
    in
    {
      darwinConfigurations = builtins.mapAttrs (_: mkDarwin) hosts;

      # `nix fmt` formats every .nix file in the repo.
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      # `nix develop ./nix`: the tools scripts/lint.sh runs (the pre-commit
      # hook and CI use it too).
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = import ./lint-tools.nix pkgs;
        };
      });

      # `nix flake check` skips darwinConfigurations entirely; exposing each
      # host's system here is what makes `nix flake check --no-build` evaluate
      # it (add --all-systems on a machine of another platform, e.g. Linux CI).
      # The onboarding template is checked too, the way onboarding uses it:
      # with a dock copied in (its step 2) and its REPLACE_ME_* placeholders
      # as they are, which are valid values.
      checks =
        inputs.nixpkgs.lib.foldlAttrs
          (
            acc: name: cfg:
            inputs.nixpkgs.lib.recursiveUpdate acc {
              ${cfg.pkgs.stdenv.hostPlatform.system}.${name} = cfg.system;
            }
          )
          {
            aarch64-darwin.template =
              (mkDarwin (import ./hosts/template // { systemModules = [ ./hosts/m5/dock.nix ]; })).system;
          }
          self.darwinConfigurations;
    };
}
