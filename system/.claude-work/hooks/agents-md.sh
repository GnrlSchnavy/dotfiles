#!/usr/bin/env bash
# SessionStart hook (work lane): Ahold repos keep their instructions in
# AGENTS.md, which Claude Code does not auto-load. Print the repo-root file so
# it is added to the session context.
set -u
cat >/dev/null

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$dir")"
[ -f "$root/AGENTS.md" ] || exit 0
# A CLAUDE.md that already imports AGENTS.md loads it itself.
if [ -f "$root/CLAUDE.md" ] && grep -q '@AGENTS.md' "$root/CLAUDE.md"; then
  exit 0
fi

printf '# Repository instructions (%s/AGENTS.md)\n\n' "$(basename "$root")"
cat "$root/AGENTS.md"
