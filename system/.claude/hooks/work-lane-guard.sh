#!/usr/bin/env bash
# Personal-lane guard (UserPromptSubmit + PreToolUse in ~/.claude/settings.json).
# The personal lane runs on Claude Max, so nothing from a client work tree may
# pass through it — exit 2 blocks the prompt or tool call before it is sent.
# Client work belongs in the work lane: `cc-work`.
set -u

payload="$(cat)"

IFS=: read -r -a roots <<<"${CC_WORK_ROOTS:-$HOME/projects/ahold}"
for root in "${roots[@]}"; do
  [ -n "$root" ] || continue
  case "$payload" in
    *"$root/"* | *"$root\""*)
      printf 'Blocked by the personal-lane guard: this session runs on your personal Claude Max account and the request touches %s (client work).\nOpen client repos with cc-work in a terminal instead.\n' "$root" >&2
      exit 2
      ;;
  esac
done
exit 0
