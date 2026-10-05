#!/usr/bin/env bash
# Work-lane self-check (UserPromptSubmit + PreToolUse in ~/.claude-work/settings.json).
# Fails closed (exit 2 blocks the prompt / tool call) unless the session talks
# to a non-Anthropic gateway (DevAI's local proxy, via cc-work or the desktop
# app in gateway mode) and codemem's observer points at the TechNL proxy.
# A personal-mode desktop session gets ANTHROPIC_BASE_URL=api.anthropic.com
# and plain `claude` gets none, so both are blocked.
set -u
cat >/dev/null

fail() {
  printf 'Work-lane check failed: %s.\nStart work sessions with cc-work or cc-work-desktop.\n' "$1" >&2
  exit 2
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

gateway=""
for url in "${ANTHROPIC_BASE_URL:-}" "${CLAUDE_CODE_API_BASE_URL:-}"; do
  case "$(lower "$url")" in
    "") ;;
    *anthropic.com*) fail "the gateway URL points at Anthropic ($url)" ;;
    *) gateway="$url" ;;
  esac
done
[ -n "$gateway" ] || fail "no gateway URL is set (not started through DevAI)"

case "$(lower "${CODEMEM_ANTHROPIC_ENDPOINT:-}")" in
  "" | *anthropic.com*) fail "codemem's observer endpoint is not the TechNL proxy" ;;
esac
# codemem <= 0.36 hook ingest posts to 127.0.0.1:38888 regardless of
# CODEMEM_VIEWER_PORT, so a viewer there would receive this lane's events.
if (exec 3<>/dev/tcp/127.0.0.1/38888) 2>/dev/null; then
  fail "a codemem viewer is listening on the default port 38888, which would receive work events"
fi
exit 0
