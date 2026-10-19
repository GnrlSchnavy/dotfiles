# SSH via Proton Pass — the shared plumbing, on every host.
#
# Private keys live only in Proton Pass, never on disk. `pass-cli ssh-agent`
# serves the keys of one vault on a fixed socket, and ~/.ssh/config sends
# each declared host to that agent with the matching key. The profile names
# the vault and the hosts (nix/profiles/*/ssh.nix); each key's public half is
# committed next to it, since public keys aren't secret and ssh needs one to
# pick the right key from the agent. Runbook: docs/ssh.md.
{
  config,
  lib,
  osConfig,
  ...
}:

let
  cfg = config.dotfiles.ssh;
  home = config.home.homeDirectory;
  socket = "${home}/.ssh/proton-pass-agent.sock";
  keyPath = h: "~/.ssh/proton/${baseNameOf h.publicKey}";
in
{
  options.dotfiles.ssh = {
    vault = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "SSH-personal";
      description = "Proton Pass vault whose SSH keys the agent serves. Without one, SSH isn't managed.";
    };
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hostName = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Real host name, for an alias.";
            };
            user = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            publicKey = lib.mkOption {
              type = lib.types.path;
              description = "The key's public half (committed); selects the key in the agent.";
            };
          };
        }
      );
      default = { };
      description = "ssh Host patterns and the key each uses.";
    };
    socket = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = socket;
      description = "The agent's socket.";
    };
  };

  config = lib.mkIf (cfg.vault != null) {
    # Needs a `pass-cli login` first; until then it exits and launchd retries
    # every minute (log below).
    launchd.agents.proton-pass-ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${osConfig.homebrew.prefix}/bin/pass-cli"
          "ssh-agent"
          "start"
          "--vault-name"
          cfg.vault
          "--socket-path"
          socket
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 60;
        StandardOutPath = "${home}/Library/Logs/proton-pass-ssh-agent.log";
        StandardErrorPath = "${home}/Library/Logs/proton-pass-ssh-agent.log";
      };
    };

    home.file = lib.mapAttrs' (
      _: h: lib.nameValuePair ".ssh/proton/${baseNameOf h.publicKey}" { source = h.publicKey; }
    ) cfg.hosts;

    # ~/.ssh/config is a store symlink (ssh never rewrites it). Hosts not
    # declared here go in ~/.ssh/config.local.
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [ "~/.ssh/config.local" ];
      settings = lib.mapAttrs (
        _: h:
        lib.filterAttrs (_: v: v != null) {
          HostName = h.hostName;
          User = h.user;
          IdentityAgent = socket;
          IdentityFile = keyPath h;
          # Only this key: otherwise ssh offers every key in the agent and
          # GitHub logs in as whichever account matches first.
          IdentitiesOnly = true;
        }
      ) cfg.hosts;
    };
  };
}
