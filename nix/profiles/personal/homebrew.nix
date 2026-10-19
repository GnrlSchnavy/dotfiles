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

      # Development
      "lens"

      # Utilities and security tools
      "balenaetcher"
      "knockknock"
      "little-snitch"
      "oversight"
      "taskexplorer"
    ];

    # CLI tools come from nixpkgs (packages.nix). ClamAV stays here: brew
    # keeps freshclam's config and signature database in its user-writable
    # prefix, where the Nix build reads /etc/clamav and defaults the
    # database to the read-only store.
    brews = [ "clamav" ];
  };
}
