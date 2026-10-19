#!/usr/bin/env bash
# Fails when a host declares a Homebrew cask or formula that Homebrew has
# disabled. A disabled one can't be installed, so `brew bundle` fails and
# aborts the activation before home-manager runs — on a fresh machine only,
# since a machine that already has it just reports "Using". CI's fresh
# install drops casks, so it can't catch this; this asks the Homebrew API.
#
# Needs nix, jq, curl and network. Tapped names (with a "/") aren't in the
# API and are skipped. Usage: scripts/check-brew.sh [host ...]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
hosts=("$@")
[ ${#hosts[@]} -gt 0 ] || hosts=(m5 work)

status=0
for host in "${hosts[@]}"; do
  for kind in cask formula; do
    attr=casks
    [ "$kind" = formula ] && attr=brews
    names="$(nix eval --json "$root/nix#darwinConfigurations.$host.config.homebrew.$attr" |
      jq -r '.[] | if type == "string" then . else .name end')"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      case "$name" in */*) continue ;; esac
      info="$(curl -fsS "https://formulae.brew.sh/api/$kind/$name.json")" || {
        printf 'FAIL  %s: %s %s not found in the Homebrew API\n' "$host" "$kind" "$name"
        status=1
        continue
      }
      if jq -e '.disabled == true' <<<"$info" >/dev/null; then
        printf 'FAIL  %s: %s %s is disabled (%s, since %s)\n' "$host" "$kind" "$name" \
          "$(jq -r '.disable_reason // "?"' <<<"$info")" "$(jq -r '.disable_date // "?"' <<<"$info")"
        status=1
      elif jq -e '.deprecated == true' <<<"$info" >/dev/null; then
        printf 'warn  %s: %s %s is deprecated (%s); it will be disabled\n' "$host" "$kind" "$name" \
          "$(jq -r '.deprecation_reason // "?"' <<<"$info")"
      fi
    done <<<"$names"
  done
done
[ $status -eq 0 ] && echo "ok    no disabled casks or formulae"
exit $status
