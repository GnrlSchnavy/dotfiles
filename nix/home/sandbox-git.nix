# Git push/pull from Claude Code's Bash sandbox.
#
# The sandbox only reaches unix sockets it allows by fixed path. It gets the
# agent git signs through (nix/home/ssh.nix): on m5 the git agent (vault
# SSH-git: GitHub and GitLab keys only, the homelab key's agent stays out),
# on the work Mac the one agent (vault SSH-work: its two GitHub keys only).
# Git in the sandbox reaches github.com over SSH tunnelled through the
# sandbox proxy.
#
# The sandbox can't read ~/.ssh, so ssh gets its own config from the store:
# the hosts that agent serves, their public keys (to pick the key) and
# GitHub's pinned host key.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.ssh;
  socket = cfg.signingSocket;

  # GitHub's published host key (docs.github.com, "GitHub's SSH key
  # fingerprints"); github.com is the only SSH host the sandbox may reach.
  knownHosts = pkgs.writeText "claude-git-known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
  '';

  # ~/.ssh/config's hosts whose key the sandbox's agent serves.
  sshConfig = pkgs.writeText "claude-git-ssh-config" (
    lib.concatStrings (
      lib.mapAttrsToList (
        name: h:
        ''
          Host ${name}
            IdentityFile ${h.publicKey}
            IdentitiesOnly yes
        ''
        + lib.optionalString (h.hostName != null) "  HostName ${h.hostName}\n"
        + lib.optionalString (h.user != null) "  User ${h.user}\n"
      ) (lib.filterAttrs (_: h: h.git || cfg.gitVault == null) cfg.hosts)
    )
    + ''
      Host *
        IdentityAgent ${socket}
        UserKnownHostsFile ${knownHosts}
        StrictHostKeyChecking yes
    ''
  );

  # SSH command for git in sandboxed Bash: tunnels through the sandbox proxy
  # and uses the agent. Set per call by the git() function below, since the
  # sandbox overwrites GIT_SSH_COMMAND with its own SOCKS command, which fails
  # because the proxy wants credentials.
  claudeGitSsh = pkgs.writeShellApplication {
    name = "claude-git-ssh";
    runtimeInputs = [ pkgs.nmap ]; # ncat
    runtimeEnv = {
      CLAUDE_SSH_AGENT_SOCK = socket;
      CLAUDE_SSH_CONFIG = sshConfig;
    };
    text = builtins.readFile ../../system/bin/claude-git-ssh.sh;
  };
in
{
  dotfiles.claude.settings = {
    union.sandbox.network.allowedDomains = [ "github.com" ];
    # Owned outright (set): a socket dropped from here leaves the sandbox on
    # the next rebuild, where a union entry would stay forever.
    set.sandbox.network.allowUnixSockets = [ socket ];
  };

  programs.zsh.initContent = lib.mkAfter ''
    # Claude's Bash sandbox: git over SSH through the proxy and the Proton
    # Pass agent (nix/home/sandbox-git.nix). A no-op elsewhere.
    git() {
      if [[ -n $SANDBOX_RUNTIME ]]; then
        GIT_SSH_COMMAND=${claudeGitSsh}/bin/claude-git-ssh command git "$@"
      else command git "$@"; fi
    }
  '';
}
