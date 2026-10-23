# SSH via Proton Pass — the shared plumbing, on every host.
#
# Private keys live only in Proton Pass, never on disk. `pass-cli ssh-agent`
# serves the keys of one vault on a fixed socket, and ~/.ssh/config sends
# each declared host to that agent with the matching key. The profile names
# the vault and the hosts (nix/profiles/*/ssh.nix); each key's public half is
# committed next to it, since public keys aren't secret and ssh needs one to
# pick the right key from the agent. A profile can keep its git-hosting keys
# in a second vault with its own agent (gitVault): the one Claude's Bash
# sandbox may reach, so it never gets the other keys. Runbook: docs/ssh.md.
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
  gitSocket = "${home}/.ssh/proton-pass-git-agent.sock";
  keyPath = h: "~/.ssh/proton/${baseNameOf h.publicKey}";

  agent = name: vault: sock: {
    enable = true;
    config = {
      ProgramArguments = [
        "${osConfig.homebrew.prefix}/bin/pass-cli"
        "ssh-agent"
        "start"
        "--vault-name"
        vault
        "--socket-path"
        sock
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 60;
      StandardOutPath = "${home}/Library/Logs/${name}.log";
      StandardErrorPath = "${home}/Library/Logs/${name}.log";
    };
  };
in
{
  options.dotfiles.ssh = {
    vault = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "SSH-personal";
      description = "Proton Pass vault whose SSH keys the agent serves. Without one, SSH isn't managed.";
    };
    gitVault = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "SSH-git";
      description = "Vault with only the git-hosting keys, served by a second agent on gitSocket: hosts with `git = true` and commit signing use it.";
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
            git = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "The key is in gitVault, so the git agent serves it.";
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
    gitSocket = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = gitSocket;
      description = "The git agent's socket (gitVault).";
    };
    signingSocket = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = if cfg.gitVault != null then gitSocket else socket;
      description = "The agent git signs commits through: the signing key is a git-hosting key.";
    };
  };

  config = lib.mkIf (cfg.vault != null) {
    assertions = [
      {
        assertion = cfg.gitVault != null || lib.all (h: !h.git) (lib.attrValues cfg.hosts);
        message = "dotfiles.ssh: hosts with `git = true` need dotfiles.ssh.gitVault.";
      }
    ];

    # Need a `pass-cli login` first; until then they exit and launchd retries
    # every minute (logs in ~/Library/Logs).
    launchd.agents = {
      proton-pass-ssh-agent = agent "proton-pass-ssh-agent" cfg.vault socket;
    }
    // lib.optionalAttrs (cfg.gitVault != null) {
      proton-pass-git-agent = agent "proton-pass-git-agent" cfg.gitVault gitSocket;
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
          IdentityAgent = if h.git then gitSocket else socket;
          IdentityFile = keyPath h;
          # Only this key: otherwise ssh offers every key in the agent and
          # GitHub logs in as whichever account matches first.
          IdentitiesOnly = true;
        }
      ) cfg.hosts;
    };
  };
}
