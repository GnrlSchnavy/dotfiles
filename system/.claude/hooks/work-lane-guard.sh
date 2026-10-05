#!/usr/bin/env bash
# Personal-lane guard (UserPromptSubmit + PreToolUse in ~/.claude/settings.json).
# The personal lane runs on Claude Max, so nothing from a client work tree may
# pass through it — exit 2 blocks the prompt or tool call before it is sent.
# Client work belongs in the work lane: `cc-work`.
#
# Second line of defence: the Read/Edit deny rules claude-lanes.nix merges into
# settings.json are the boundary for the file tools. This hook covers what they
# can't express — prompts, Bash, case-insensitive paths, and searches started
# from a folder that contains a work tree. The decisions live in
# work-lane-guard.jq; if that can't be evaluated the request is blocked.
# Runs under macOS /bin/bash 3.2.
set -u

block() {
  printf 'Blocked by the personal-lane guard: %s.\nThis session runs on your personal Claude Max account; open client repos with cc-work in a terminal instead.\n' "$1" >&2
  exit 2
}

payload="$(cat)"
[ -n "$payload" ] || block "the hook received no input"

here="$(cd "$(dirname "$0")" && pwd)"

jq_bin=""
for c in /run/current-system/sw/bin/jq "$(command -v jq 2>/dev/null)" /usr/bin/jq; do
  if [ -n "$c" ] && [ -x "$c" ]; then jq_bin="$c"; break; fi
done
[ -n "$jq_bin" ] || block "jq was not found, so the request could not be checked"

roots=""
rest="${CC_WORK_ROOTS:-$HOME/projects/ahold}:"
while [ -n "$rest" ]; do
  r="${rest%%:*}"; rest="${rest#*:}"
  [ -n "$r" ] || continue
  roots="$roots$r"$'\n'
  # A root that is itself a symlink is also matched by its physical path.
  p="$(cd -P "$r" 2>/dev/null && pwd -P)" && roots="$roots$p"$'\n'
done

cwd="$(printf '%s' "$payload" | "$jq_bin" -r '.cwd // empty' 2>/dev/null)" \
  || block "the hook input is not valid JSON"
pcwd=""
if [ -n "$cwd" ]; then pcwd="$(cd -P "$cwd" 2>/dev/null && pwd -P)" || pcwd=""; fi

reason="$(printf '%s' "$payload" | "$jq_bin" -r -f "$here/work-lane-guard.jq" \
  --arg roots "$roots" --arg home "$HOME" --arg pwd "$PWD" --arg pcwd "$pcwd")" \
  || block "the guard could not evaluate the request"
[ -z "$reason" ] || block "${reason%%$'\n'*}"
exit 0
