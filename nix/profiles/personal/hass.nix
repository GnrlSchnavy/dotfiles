# Home Assistant from the terminal without a token on disk: `hass` runs
# hass-cli with HASS_TOKEN (and HASS_SERVER, unless already set) read from
# Proton Pass, Infra → Home Assistant → token / url, for that call only.
# Needs a `pass-cli login` (docs/secrets.md#home-assistant-token).
{ osConfig, pkgs, ... }:

let
  passCli = "${osConfig.homebrew.prefix}/bin/pass-cli";

  hass = pkgs.writeShellApplication {
    name = "hass";
    runtimeInputs = [ pkgs.home-assistant-cli ];
    text = ''
      field() {
        ${passCli} item view --vault-name Infra --item-title "Home Assistant" --field "$1"
      }
      HASS_SERVER="''${HASS_SERVER:-$(field url)}"
      HASS_TOKEN="$(field token)"
      if [ -z "$HASS_SERVER" ] || [ -z "$HASS_TOKEN" ]; then
        echo "hass: Infra/Home Assistant needs the fields url and token" >&2
        exit 1
      fi
      export HASS_SERVER HASS_TOKEN
      exec hass-cli "$@"
    '';
  };
in
{
  home.packages = [ hass ];
}
