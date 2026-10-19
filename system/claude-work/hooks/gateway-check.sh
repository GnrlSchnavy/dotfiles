#!/usr/bin/env bash
# Work gateway self-check (UserPromptSubmit + PreToolUse in ~/.claude/settings.json
# on the work machine). Fails closed (exit 2 blocks the prompt / tool call)
# unless the session talks to a non-Anthropic gateway (DevAI's local proxy, via
# cc-work or the desktop app in gateway mode) and codemem's observer points at
# the TechNL proxy. A personal-mode desktop session gets
# ANTHROPIC_BASE_URL=api.anthropic.com and plain `claude` gets none, so both
# are blocked.
set -u
cat >/dev/null

fail() {
  printf 'Work gateway check failed: %s.\nStart work sessions with cc-work or cc-work-desktop.\n' "$1" >&2
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
exit 0
