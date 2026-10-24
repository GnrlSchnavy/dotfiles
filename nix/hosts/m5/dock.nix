# m5's Dock apps (all installed via Homebrew casks). The Dock's behaviour is
# shared: nix/modules/dock.nix.
{ ... }:

let
  # Build a /Applications path from an app name (without `.app`).
  app = name: "/Applications/${name}.app";
in
{
  system.defaults.dock.persistent-apps = map app [
    "Brave Browser"
    "Spotify"
    "Slack"
    "Obsidian"
    "IntelliJ IDEA"
  ];
}
