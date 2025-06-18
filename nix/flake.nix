{
  description = "Yvan nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixvim = {
      # url = "github:mikaelfangel/nixvim-config";
      url = "./nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin/d06cf700ee589527fde4bd9b91f899e7137c05a6";
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
      configuration =
        { pkgs, config, ... }:
        {
          # Allow 'paid' applications to be set in flake config
          nixpkgs.config.allowUnfree = true;
          system.keyboard.enableKeyMapping = true;

          environment.systemPackages = [
            inputs.nixvim.packages.aarch64-darwin.default
	    pkgs.minikube
            pkgs.mkalias
            pkgs.git
            pkgs.maven
            pkgs.docker
            pkgs.docker-compose
            pkgs.zulu23
            pkgs.rustc
          ];

          environment.variables = {
            # Might be handy?
            # YVAN_TEST = "TEST";
          };

          homebrew = {
            enable = true;
            casks = [
	      #temp 
	      "teamviewer"
	      "figma"

              "openlens"
              "mindmac"
	      "signal"
              "cyberduck"
	      "postman"
              "docker"
              "alfred"
              "openvpn-connect"
              "rectangle"
              "warp"
              "intellij-idea"
              "1password"
              "google-chrome"
              "slack"
              "visual-studio-code"
              "obsidian"
              "brave-browser"
              "spotify"
              "bruno"
              "1password-cli"
              "whatsapp"
              "mattermost"
      	      "nordvpn"
              "android-studio"
              "crossover"

              # Logius
              "mattermost"
              "webex"
              "citrix-workspace"
              "omnissa-horizon-client"
            ];
            brews = [
	      "pgloader"
	      "p7zip"
	      "jenv"
              "tmux"
              "helm"
              "stow"
              "kdoctor"
              "pyenv"
              "autojump"
              "nvm"
            ];
            masApps = {
              "WireGuard" = 1451685025;
              "Outlook" = 985367838;
	            "Windows Remote Desktop" = 1295203466;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          system.keyboard.remapCapsLockToEscape = true;

          system.defaults = {
            screensaver.askForPassword = true;
            screensaver.askForPasswordDelay = 300;
            loginwindow.LoginwindowText = "Yvan Stemmerik +31610042024";
            WindowManager.EnableStandardClickToShowDesktop = false;
            finder = {
              NewWindowTarget = "Home";
              ShowExternalHardDrivesOnDesktop = false;
              ShowPathbar = true;

            };

            dock = {
              show-recents = false;
              static-only = true;
              minimize-to-application = true;
              mineffect = null;
              autohide-delay = 0.01;
              autohide-time-modifier = 0.1;
              magnification = false;
              launchanim = false;
              orientation = "right";
              tilesize = 36;
              autohide = true;
              persistent-apps = [
                "${pkgs.brave}/Applications/Brave Browser.app"
                "${pkgs.spotify}/Applications/Spotify.app"
                "${pkgs.slack}/Applications/Slack.app"
                "${pkgs.obsidian}/Applications/Obsidian.app"
                "/Applications/IntelliJ IDEA.app"
              ];
            };
            NSGlobalDomain = {
              NSScrollAnimationEnabled = false;
              NSAutomaticInlinePredictionEnabled = false;
              NSAutomaticPeriodSubstitutionEnabled = false;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticSpellingCorrectionEnabled = false;
              NSAutomaticWindowAnimationsEnabled = false;
              NSDocumentSaveNewDocumentsToCloud = false;
              NSNavPanelExpandedStateForSaveMode = true;
              NSNavPanelExpandedStateForSaveMode2 = true;
              AppleShowAllExtensions = true;
              ApplePressAndHoldEnabled = false;
              NSAutomaticCapitalizationEnabled = false;
              AppleInterfaceStyle = "Dark";
              "com.apple.swipescrolldirection" = false;
              KeyRepeat = 2;
              InitialKeyRepeat = 15;
              "com.apple.mouse.tapBehavior" = 1;
              "com.apple.sound.beep.volume" = 0.0;
              "com.apple.sound.beep.feedback" = 0;
            };

            finder.FXPreferredViewStyle = "clmv";
            loginwindow.GuestEnabled = false;

          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # programs.nixvim.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

        };
    in
    {
      darwinConfigurations."m4" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              #Apple Silicon Only
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
