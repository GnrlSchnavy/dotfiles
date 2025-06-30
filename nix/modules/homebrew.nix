{ ... }:

{
  homebrew = {
    enable = true;
    
    casks = [
      # Temporary applications
      "teamviewer"
      "figma"
      "openlens"
      "mindmac"
      "signal"
      "cyberduck"
      "postman"
      
      # Core applications
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
}