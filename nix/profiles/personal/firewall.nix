# The macOS application firewall on a personal Mac, re-applied on every
# rebuild. Apple's own signed software may accept connections; any other
# app that listens (java running a dev server, Spotify, Steam) gets one
# macOS prompt, and Deny keeps it unreachable from the network (localhost is
# unaffected). Stealth mode: the Mac doesn't answer probes.
{
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true;
    allowSignedApp = false;
  };
}
