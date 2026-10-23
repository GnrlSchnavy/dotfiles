#!/usr/bin/env bash
# Checks every skill in system/.claude/skills/: its `allowed-tools` (run
# without asking) never include Bash, Write or Edit unscoped. Skills read
# untrusted notes, so a bare `Bash` would hand any command a free pass.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

for f in "$repo"/system/.claude/skills/*/SKILL.md; do
  skill="$(basename "$(dirname "$f")")"
  tools="$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1' "$f" |
    sed -n 's/^allowed-tools: *//p')"
  bare=""
  for t in $tools; do
    case "$t" in Bash | Write | Edit) bare="$bare $t" ;; esac
  done
  if [ -n "$bare" ]; then
    printf 'FAIL  skills: %s allows%s unscoped\n' "$skill" "$bare"
    failed=1
  else
    printf 'ok    skills: %s\n' "$skill"
  fi
done

exit $failed
