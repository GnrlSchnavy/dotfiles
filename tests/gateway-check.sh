#!/usr/bin/env bash
# Fixtures for the work machine's Claude Code gateway check:
#   system/claude-work/hooks/gateway-check.sh
# Sessions not started through DevAI (no gateway, or Anthropic as the
# gateway) and a codemem observer not on the TechNL proxy must block.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
gateway_check="$repo/system/claude-work/hooks/gateway-check.sh"
failed=0

check() { # <block|allow> <name> <env assignments...>
  local want="$1" name="$2" rc got
  shift 2
  printf '{}' | env -i PATH="$PATH" HOME="$HOME" "$@" bash "$gateway_check" >/dev/null 2>&1
  rc=$?
  case $rc in 2) got=block ;; 0) got=allow ;; *) got="exit $rc" ;; esac
  if [ "$got" = "$want" ]; then
    printf 'ok    gateway-check: %s\n' "$name"
  else
    printf 'FAIL  gateway-check: %s (want %s, got %s)\n' "$name" "$want" "$got"
    failed=1
  fi
}
ep=CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check allow "started by cc-work"           ANTHROPIC_BASE_URL=http://127.0.0.1:8787 "$ep"
check allow "desktop gateway mode"         CLAUDE_CODE_API_BASE_URL=http://127.0.0.1:8787 "$ep"
check block "desktop gateway is Anthropic" CLAUDE_CODE_API_BASE_URL=https://API.anthropic.com "$ep"
check block "no gateway"                   "$ep"
check block "gateway is Anthropic"         ANTHROPIC_BASE_URL=https://api.anthropic.com "$ep"
check block "gateway is Anthropic (case)"  ANTHROPIC_BASE_URL=https://API.Anthropic.COM "$ep"
check block "codemem endpoint Anthropic"   ANTHROPIC_BASE_URL=http://127.0.0.1:8787 CODEMEM_ANTHROPIC_ENDPOINT=https://api.anthropic.com/v1/messages
check block "codemem endpoint unset"       ANTHROPIC_BASE_URL=http://127.0.0.1:8787

exit $failed
