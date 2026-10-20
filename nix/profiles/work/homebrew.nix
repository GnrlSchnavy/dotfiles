# Work apps. Outlook, Teams and the other Microsoft apps come preinstalled
# by the client's device management — don't declare them: brew refuses to
# install over an app it didn't install, which fails the rebuild. (zap only
# removes what Homebrew installed, so it leaves them alone.)
{ ... }:

{
  homebrew.casks = [
    "github-copilot-app"
    "signal"
    "slack"
    "tailscale-app"
    "whatsapp"
  ];
}
