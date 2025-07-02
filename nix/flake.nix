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
      # Modular configuration - organized for clarity and maintainability
      
      # Package configuration module
      packagesModule = { pkgs, ... }: {
        environment.systemPackages = [
          # Nixvim configuration
          inputs.nixvim.packages.aarch64-darwin.default
          
          # Core development tools (prefer Nix for reproducibility)
          pkgs.git                    # Version control
          pkgs.maven                  # Java build tool
          pkgs.rustc                  # Rust compiler
          pkgs.nodejs_20              # Node.js runtime
          
          # Container ecosystem
          # pkgs.docker               # Docker CLI - provided by Docker Desktop
          # pkgs.docker-compose       # Container orchestration - provided by Docker Desktop  
          pkgs.minikube               # Local Kubernetes
          
          # Language runtimes and compilers
          pkgs.zulu23                 # Java 23 JDK
          pkgs.python3                # Python runtime
          
          # System utilities (Nix for cross-platform consistency)
          pkgs.tree                   # Directory tree visualization
          pkgs.jq                     # JSON processor
          pkgs.curl                   # HTTP client
          pkgs.wget                   # File downloader
          pkgs.ripgrep               # Fast text search
          pkgs.fd                     # Fast file finder
          pkgs.bat                    # Better cat with syntax highlighting
          
          # Archive and compression
          pkgs.unzip                  # ZIP extraction
          pkgs.p7zip                  # 7zip support
          
          # Development utilities
          pkgs.mkalias                # macOS alias creation
          pkgs.htop                   # Process monitor
          pkgs.neofetch               # System information
        ];
      };

      # Homebrew configuration module
      homebrewModule = { ... }: {
        homebrew = {
          enable = true;
          casks = [
            # Temporary applications
            "teamviewer"
	          "claude"
            "figma"
            "openlens"
            "mindmac"
            "signal"
            "cyberduck"
            "postman"
            
            # Core applications  
            "docker-desktop"            # Docker Desktop (GUI + CLI)
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
            
            # Logius specific
            "webex"
            "citrix-workspace"
            "omnissa-horizon-client"
          ];
          
          brews = [
            "sshpass"
            "kubeseal"
            "tree"
            "fluxcd/tap/flux"
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
          
          onActivation = {
            cleanup = "zap";
            autoUpdate = true;
            upgrade = true;
          };
        };
      };

      # System defaults configuration module
      systemModule = { ... }: {
        # System keyboard configuration
        system.keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
        };

        # macOS system defaults
        system.defaults = {
          # Screen saver settings
          screensaver = {
            askForPassword = true;
            askForPasswordDelay = 300;
          };
          
          # Login window configuration
          loginwindow = {
            LoginwindowText = "Yvan Stemmerik +31610042024";
            GuestEnabled = false;
          };
          
          # Window manager settings
          WindowManager.EnableStandardClickToShowDesktop = false;
          
          # Finder configuration
          finder = {
            NewWindowTarget = "Home";
            ShowExternalHardDrivesOnDesktop = false;
            ShowPathbar = true;
            FXPreferredViewStyle = "clmv";
          };
          
          # Global system preferences
          NSGlobalDomain = {
            # Animation and UI settings
            NSScrollAnimationEnabled = false;
            NSAutomaticWindowAnimationsEnabled = false;
            
            # Text input settings
            NSAutomaticInlinePredictionEnabled = false;
            NSAutomaticPeriodSubstitutionEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
            NSAutomaticSpellingCorrectionEnabled = false;
            NSAutomaticCapitalizationEnabled = false;
            ApplePressAndHoldEnabled = false;
            
            # File and document settings
            NSDocumentSaveNewDocumentsToCloud = false;
            NSNavPanelExpandedStateForSaveMode = true;
            NSNavPanelExpandedStateForSaveMode2 = true;
            AppleShowAllExtensions = true;
            
            # Interface settings
            AppleInterfaceStyle = "Dark";
            "com.apple.swipescrolldirection" = false;
            
            # Keyboard settings
            KeyRepeat = 2;
            InitialKeyRepeat = 15;
            
            # Mouse and sound settings
            "com.apple.mouse.tapBehavior" = 1;
            "com.apple.sound.beep.volume" = 0.0;
            "com.apple.sound.beep.feedback" = 0;
          };
        };
      };

      # Dock configuration module
      dockModule = { pkgs, ... }: {
        system.defaults.dock = {
          # Dock behavior
          show-recents = false;
          static-only = true;
          minimize-to-application = true;
          mineffect = null;
          launchanim = false;
          autohide = true;
          
          # Dock appearance
          orientation = "right";
          tilesize = 36;
          magnification = false;
          
          # Dock timing
          autohide-delay = 0.01;
          autohide-time-modifier = 0.1;
          
          # Persistent applications (using Homebrew-installed apps)
          persistent-apps = [
            "${pkgs.brave}/Applications/Brave Browser.app"  # Nix package
            "/Applications/Spotify.app"                     # Homebrew cask
            "/Applications/Slack.app"                       # Homebrew cask  
            "/Applications/Obsidian.app"                    # Homebrew cask
            "/Applications/IntelliJ IDEA.app"               # Homebrew cask
          ];
        };
      };

      # Environment configuration module
      environmentModule = { ... }: {
        environment.variables = {
          # Placeholder for future environment variables
          # Example:
          # YVAN_TEST = "TEST";
        };
      };

      # Host-specific configuration
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
      };

    in
    {
      darwinConfigurations."m4" = nix-darwin.lib.darwinSystem {
        modules = [
          # Import all modular configurations
          packagesModule
          homebrewModule
          systemModule
          dockModule
          environmentModule
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
