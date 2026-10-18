# Personal apps — never on a client machine.
{ ... }:

{
  homebrew = {
    casks = [
      # Browsers
      "tor-browser"

      # Communication
      "discord"
      "signal"
      "slack"
      "whatsapp"

      # Media
      "jellyfin-media-player"
      "spotify"
      "vlc"

      # Proton
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"

      # Networking
      "protonvpn"
      "tailscale-app"

      # Dictation
      "handy"
      "wispr-flow"

      # Games
      "crossover"
      "steam"

      # Utilities and security tools
      "balenaetcher"
      "knockknock"
      "little-snitch"
      "oversight"
      "taskexplorer"
    ];

    brews = [
      "ansible"
      "clamav"
      "nmap"
      "stripe-cli"
    ];
  };
}
