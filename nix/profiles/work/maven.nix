# Maven's ~/.m2/settings.xml, from Proton Pass instead of a file only this
# Mac has. The whole file is a note in the client vault: it holds the
# client's registry URLs and GitHub Packages token, and neither belongs in
# this public repo. `m2-render` writes it (0600, via a temp file, so a
# failed fetch keeps the old one); a launchd agent runs it at login and
# daily, so after `pass-cli login` a fresh install or a rotated token needs
# no manual step. Runbook: docs/secrets.md#maven-settingsxml.
{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  passCli = "${osConfig.homebrew.prefix}/bin/pass-cli";
  log = "${config.home.homeDirectory}/Library/Logs/m2-render.log";

  # Where the note lives. Refs resolve by name: rename it in Proton Pass and
  # this must change too.
  vault = "Ahold";
  item = "Maven settings.xml (backup)";

  m2Render = pkgs.writeShellApplication {
    name = "m2-render";
    text = ''
      mkdir -p "$HOME/.m2"
      tmp="$HOME/.m2/settings.xml.render.$$"
      trap 'rm -f "$tmp"' EXIT
      (umask 077 && ${passCli} item view --vault-name ${vault} --item-title "${item}" --field note >"$tmp")
      if ! grep -q '<settings' "$tmp"; then
        echo "m2-render: ${vault}/${item} isn't a settings.xml; kept the old ~/.m2/settings.xml" >&2
        exit 1
      fi
      mv -f "$tmp" "$HOME/.m2/settings.xml"
      echo "m2-render: wrote ~/.m2/settings.xml"
    '';
  };
in
{
  home.packages = [ m2Render ];

  # Fails (and retries the next day) while pass-cli isn't logged in; the log
  # says so.
  launchd.agents.m2-render = {
    enable = true;
    config = {
      ProgramArguments = [ "${m2Render}/bin/m2-render" ];
      RunAtLoad = true;
      StartInterval = 86400;
      StandardOutPath = log;
      StandardErrorPath = log;
    };
  };
}
