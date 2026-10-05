#!/usr/bin/env bash
# Runs every test file in tests/; exits non-zero if any of them fails.
# Needs bash, jq and git (no Nix, no macOS).
set -u
cd "$(dirname "$0")" || exit 1
status=0
for t in ./*.sh; do
  [ "$t" = ./run.sh ] && continue
  bash "$t" || status=1
done
exit $status
