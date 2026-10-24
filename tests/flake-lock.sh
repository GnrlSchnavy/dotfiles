#!/usr/bin/env bash
# Checks nix/flake.lock: nix-homebrew uses the brew it pins itself. An
# `inputs.brew-src.follows` override pairs nix-homebrew's bin/brew launcher
# with a brew it wasn't written for, which broke every brew call once
# (CI's fresh install didn't run that launcher then).
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

if jq -e '.nodes["nix-homebrew"].inputs["brew-src"] | type == "string"' "$repo/nix/flake.lock" >/dev/null; then
  printf 'ok    flake-lock: nix-homebrew uses its own brew pin\n'
else
  printf 'FAIL  flake-lock: brew-src of nix-homebrew is overridden (see nix/flake.nix)\n'
  failed=1
fi

exit $failed
