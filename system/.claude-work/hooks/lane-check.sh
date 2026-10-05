#!/usr/bin/env bash
# Work-lane self-check (UserPromptSubmit + PreToolUse in ~/.claude-work/settings.json).
# Fails closed (exit 2 blocks the prompt / tool call) unless the session was
# started by cc-work (devai-claude) with a non-Anthropic gateway in place and
# codemem's observer pointed at the TechNL proxy.
set -u
cat >/dev/null

fail() {
  printf 'Work-lane check failed: %s.\nStart work sessions with cc-work.\n' "$1" >&2
  exit 2
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

[ "${CC_LANE:-}" = work ] || fail "this session was not started by cc-work"
case "$(lower "${ANTHROPIC_BASE_URL:-}")" in
  "" | *anthropic.com*) fail "ANTHROPIC_BASE_URL does not point at the DevAI/TechNL gateway" ;;
esac
case "$(lower "${CODEMEM_ANTHROPIC_ENDPOINT:-}")" in
  "" | *anthropic.com*) fail "codemem's observer endpoint is not the TechNL proxy" ;;
esac
# codemem <= 0.36 hook ingest posts to 127.0.0.1:38888 regardless of
# CODEMEM_VIEWER_PORT, so a viewer there would receive this lane's events.
if (exec 3<>/dev/tcp/127.0.0.1/38888) 2>/dev/null; then
  fail "a codemem viewer is listening on the default port 38888, which would receive work events"
fi
exit 0
