#!/usr/bin/env bash
# merge-claude-settings <settings.json> <owned.json> <managed hook prefix> [seed.json]
#
# Merges the keys a Claude Code lane owns (claude-lanes.nix) into a settings
# file the app also rewrites at runtime:
#   env      owned keys overwrite; keys Nix owned last run but no longer does
#            are removed (tracked in .nix-owned.json next to the file)
#   union    every list gets its missing entries appended; your entries stay
#   hooks    hook entries whose command starts with the prefix are replaced;
#            other hooks stay, even in the same matcher group
#   default  written only where absent, nested keys included
#   set      always written
# A missing file starts from the seed (the reference snapshot). A file that
# isn't valid JSON is moved aside and the merge starts from the seed, so a
# half-written file never aborts the rebuild.
set -euo pipefail

file="$1"; owned="$2"; prefix="$3"; seed="${4:-}"
state="$(dirname "$file")/.nix-owned.json"
tmp=""
trap 'rm -f "$tmp"' EXIT

mkdir -p "$(dirname "$file")"

if [ -s "$file" ] && ! jq empty "$file" 2>/dev/null; then
  aside="$file.invalid-$(date +%Y%m%d-%H%M%S)"
  mv "$file" "$aside"
  echo "merge-claude-settings: $file was not valid JSON; moved it to $aside" >&2
fi
if [ ! -s "$file" ]; then
  if [ -n "$seed" ]; then cat "$seed" >"$file"; else printf '{}\n' >"$file"; fi
fi

prev='[]'
if [ -s "$state" ] && jq -e '.env | type == "array"' "$state" >/dev/null 2>&1; then
  prev="$(jq -c '.env' "$state")"
fi

tmp="$(mktemp "$file.XXXXXX")"
jq --slurpfile owned "$owned" --arg prefix "$prefix" --argjson prev "$prev" '
  $owned[0] as $o
  | ($o.env // {}) as $env
  | .env = ((.env // {})
      | delpaths([$prev[] | select(. as $k | $env | has($k) | not) | [.]])
      | . + $env)
  | reduce (($o.union // {}) | paths(type == "array")) as $p (.;
      setpath($p; reduce ($o.union | getpath($p))[] as $x
        ((getpath($p) // []); if any(.[]; . == $x) then . else . + [$x] end)))
  | .hooks = (
      ((.hooks // {})
        | with_entries(.value |= (
            map(.hooks = ((.hooks // [])
              | map(select((.command // "") | startswith($prefix) | not))))
            | map(select(.hooks | length > 0)))))
      as $kept
      | reduce (($o.hooks // {}) | to_entries[]) as $e
          ($kept; .[$e.key] = ((.[$e.key] // []) + $e.value))
      | with_entries(select(.value | length > 0)))
  | (($o.default // {}) * .)
  | . * ($o.set // {})
' "$file" >"$tmp"
mv "$tmp" "$file"

jq -n --slurpfile owned "$owned" '{env: (($owned[0].env // {}) | keys)}' >"$state"
