# Git push/pull from Claude Code's Bash sandbox.
#
# The sandbox only reaches unix sockets it allows by fixed path. It gets the
# git agent's (vault SSH-git, nix/home/ssh.nix), which holds only the GitHub
# and GitLab keys, and git in the sandbox reaches github.com over SSH
# tunnelled through the sandbox proxy. The homelab key's agent stays out.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  socket = config.dotfiles.ssh.gitSocket;

  # SSH command for git in sandboxed Bash: tunnels through the sandbox proxy
  # and uses the agent. Set per call by the git() function below, since the
  # sandbox overwrites GIT_SSH_COMMAND with its own SOCKS command, which fails
  # because the proxy wants credentials.
  claudeGitSsh = pkgs.writeShellApplication {
    name = "claude-git-ssh";
    runtimeInputs = [ pkgs.nmap ]; # ncat
    runtimeEnv.CLAUDE_SSH_AGENT_SOCK = socket;
    text = builtins.readFile ../../../system/bin/claude-git-ssh.sh;
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
    # Pass agent (nix/profiles/personal/sandbox-git.nix). A no-op elsewhere.
    git() {
      if [[ -n $SANDBOX_RUNTIME ]]; then
        GIT_SSH_COMMAND=${claudeGitSsh}/bin/claude-git-ssh command git "$@"
      else command git "$@"; fi
    }
  '';
}
