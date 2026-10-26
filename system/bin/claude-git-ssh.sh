#!/usr/bin/env bash
#
# claude-git-ssh — the SSH command git uses in Claude Code's Bash sandbox
# (set by the git() function in nix/home/sandbox-git.nix), so Claude can push
# and pull.
#
# Inside the Bash sandbox ($SANDBOX_RUNTIME set) ssh can't resolve or reach
# github.com: the sandbox's own GIT_SSH_COMMAND uses its SOCKS port without
# credentials, which the proxy refuses. There, this routes ssh through the
# sandbox's HTTP proxy with ncat (127.0.0.1, not localhost: the proxy refuses
# that) and points it at the Proton Pass SSH agent's socket, which the sandbox
# allows ($CLAUDE_SSH_AGENT_SOCK; ~/.ssh/config names it too). Anywhere else
# it is plain ssh.
set -euo pipefail

if [ -z "${SANDBOX_RUNTIME:-}" ] || [ -z "${HTTP_PROXY:-}" ]; then
  exec ssh "$@"
fi

# HTTP_PROXY looks like http://user:pass@localhost:58055 (per-command creds).
proxy="${HTTP_PROXY#*://}"
proxy="${proxy%%/*}"
port="${proxy##*:}"
auth=()
if [[ "$proxy" == *@* ]]; then
  auth=(--proxy-auth "${proxy%@*}")
fi

export SSH_AUTH_SOCK="$CLAUDE_SSH_AGENT_SOCK"
# ssh runs ProxyCommand through a shell, so quote every word.
exec ssh -o "ProxyCommand=$(printf '%q ' ncat --proxy "127.0.0.1:$port" --proxy-type http "${auth[@]}") %h %p" "$@"
