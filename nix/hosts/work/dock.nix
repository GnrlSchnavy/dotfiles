# work's Dock apps: Outlook and Teams come from the client's device
# management, the rest from Homebrew casks. The Dock's behaviour is shared:
# nix/modules/dock.nix.
{ ... }:

let
  # Build a /Applications path from an app name (without `.app`).
  app = name: "/Applications/${name}.app";
in
{
  system.defaults.dock.persistent-apps = map app [
    "Brave Browser"
    "Microsoft Outlook"
    "Microsoft Teams"
    "Slack"
    "IntelliJ IDEA"
  ];
}
