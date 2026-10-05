#!/usr/bin/env bash
# Checks every subagent in system/.claude/agents/:
#   - `name` matches the file name and a description is present;
#   - every `tools:` entry is a real Claude Code tool (an unknown name stops
#     the subagent from launching at all);
#   - `model:` is absent or an alias, never a full model id — aliases resolve
#     per lane, so a full id would route client work out of its channel.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
known=" Read Write Edit Bash Grep Glob NotebookEdit WebFetch WebSearch TodoWrite "
failed=0

for f in "$repo"/system/.claude/agents/*.md; do
  file="$(basename "$f" .md)"
  fm="$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1' "$f")"
  field() { printf '%s\n' "$fm" | sed -n "s/^$1: *//p" | head -1; }
  problems=""

  [ "$(field name)" = "$file" ] || problems="$problems name≠file;"
  [ -n "$(field description)" ] || problems="$problems no description;"

  tools="$(field tools)"
  [ -n "$tools" ] || problems="$problems no tools;"
  IFS=',' read -r -a list <<<"$tools"
  for t in "${list[@]}"; do
    t="${t// /}"
    case "$t" in mcp__*) continue ;; esac
    case "$known" in *" $t "*) ;; *) problems="$problems unknown tool '$t';" ;; esac
  done

  case "$(field model)" in "" | opus | sonnet | haiku | inherit) ;; *) problems="$problems model is not an alias;" ;; esac

  if [ -z "$problems" ]; then
    printf 'ok    agents: %s\n' "$file"
  else
    printf 'FAIL  agents: %s:%s\n' "$file" "$problems"
    failed=1
  fi
done

exit $failed
