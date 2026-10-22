# Runs scripts/backup.sh weekly through launchd, so the state git can't
# regenerate (Claude Code settings, codemem databases, Docker config) is
# backed up without anyone remembering to. Mondays at noon; a Mac that's
# asleep then runs it when it wakes. Backups land in ~/.dotfiles-backups
# (the newest five are kept); log: ~/Library/Logs/dotfiles-backup.log.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  log = "${config.home.homeDirectory}/Library/Logs/dotfiles-backup.log";
in
{
  launchd.agents.dotfiles-backup = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.bash}/bin/bash"
        "${../../scripts/backup.sh}"
      ];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 12;
          Minute = 0;
        }
      ];
      # launchd's PATH is just /usr/bin:/bin:/usr/sbin:/sbin; the script also
      # records the brew lists and the nix-darwin generation.
      EnvironmentVariables.PATH = lib.concatStringsSep ":" [
        "/etc/profiles/per-user/${config.home.username}/bin"
        "/run/current-system/sw/bin"
        "${osConfig.homebrew.prefix}/bin"
        "/usr/bin"
        "/bin"
        "/usr/sbin"
        "/sbin"
      ];
      StandardOutPath = log;
      StandardErrorPath = log;
    };
  };
}
