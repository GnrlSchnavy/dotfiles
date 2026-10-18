# Git push/pull from Claude Code's Bash sandbox.
#
# The sandbox can only reach unix sockets at fixed paths, but the launchd
# ssh-agent's socket path changes every login. A relay at a fixed path
# forwards each connection to the agent's current socket, and git in the
# sandbox reaches github.com over SSH tunnelled through the sandbox proxy.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  relay = "${config.home.homeDirectory}/.ssh/claude-agent.sock";

  # SSH command for git in sandboxed Bash: tunnels through the sandbox proxy
  # and uses the relay. Set per call by the git() function below, since the
  # sandbox overwrites GIT_SSH_COMMAND with its own SOCKS command, which fails
  # because the proxy wants credentials.
  claudeGitSsh = pkgs.writeShellApplication {
    name = "claude-git-ssh";
    runtimeInputs = [ pkgs.nmap ]; # ncat
    runtimeEnv.CLAUDE_SSH_AGENT_RELAY = relay;
    text = builtins.readFile ../../../system/bin/claude-git-ssh.sh;
  };
in
{
  dotfiles.claude.settings.union.sandbox.network = {
    allowedDomains = [ "github.com" ];
    allowUnixSockets = [ relay ];
  };

  # First loads the keys whose passphrase is in the login Keychain (stored
  # once with `ssh-add --apple-use-keychain`), since the sandbox can't prompt.
  launchd.agents.claude-ssh-agent-relay = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''/usr/bin/ssh-add --apple-load-keychain >/dev/null 2>&1; exec ${pkgs.socat}/bin/socat UNIX-LISTEN:${relay},fork,unlink-early,mode=600 UNIX-CONNECT:"$SSH_AUTH_SOCK"''
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  programs.zsh.initContent = lib.mkAfter ''
    # Claude's Bash sandbox: git over SSH through the proxy and the ssh-agent
    # relay (nix/profiles/personal/ssh-agent-relay.nix). A no-op elsewhere.
    git() {
      if [[ -n $SANDBOX_RUNTIME ]]; then
        GIT_SSH_COMMAND=${claudeGitSsh}/bin/claude-git-ssh command git "$@"
      else command git "$@"; fi
    }
  '';
}
