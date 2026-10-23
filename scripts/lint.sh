#!/usr/bin/env bash
# Repo lint: Nix formatting and lint, shell scripts, and a secrets scan of
# the working tree (this repo is public), plus what's staged when the
# pre-commit hook in .githooks/ runs it and every commit when CI does. Needs the tools from `nix develop ./nix`;
# without them it re-runs itself inside that shell.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [ -z "${DOTFILES_LINT_SHELL:-}" ]; then
  for tool in nixfmt statix deadnix shellcheck gitleaks; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      DOTFILES_LINT_SHELL=1 exec nix develop "$root/nix" --command "$0" "$@"
    fi
  done
fi

status=0
step() { printf '== %s\n' "$1"; }
run() { "$@" || status=1; }

step "nixfmt (fix with: cd nix && nix fmt)"
git ls-files -z '*.nix' | xargs -0 nixfmt --check || status=1

step "statix"
run statix check nix --config nix/statix.toml

step "deadnix"
run deadnix --fail nix

step "shellcheck"
run shellcheck -s bash -S style system/claude-work/hooks/*.sh \
  system/bin/*.sh tests/*.sh scripts/lint.sh .githooks/pre-commit
run shellcheck -s bash -S error setup.sh scripts/*.sh

step "gitleaks"
run gitleaks dir . --no-banner --redact
if [ -n "${DOTFILES_LINT_STAGED:-}" ]; then
  run gitleaks git --pre-commit --staged --no-banner --redact .
fi
# A secret added and removed again within one push is still public.
if [ -n "${CI:-}" ]; then
  run gitleaks git --no-banner --redact .
fi

exit $status
