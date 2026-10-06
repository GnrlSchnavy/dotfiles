# Two-lane codemem memory — shared across all hosts.
#
# codemem gives Claude Code persistent memory. It runs in two isolated lanes
# so client (Ahold) content is NEVER extracted via Anthropic directly — only
# through the sanctioned TechNL proxy:
#
#   personal → DB ~/.codemem/personal     → extract via local Claude (Max)
#   work     → DB ~/.codemem/work-ahold   → extract via TechNL proxy
#
# This module owns the codemem side: the per-lane observer configs and runtime
# folders. Which lane a session uses is decided by the Claude Code lane it runs
# in (see claude-lanes.nix): each lane exports its own CODEMEM_DB /
# CODEMEM_CONFIG / CODEMEM_VIEWER_PORT and hook spool/lock/context folders, and
# the codemem plugin's hooks + MCP server (and the viewer the MCP server
# auto-starts) inherit them.
#
# Isolation is by separate DB *folders* (the viewer lock is keyed on the DB's
# directory), separate observer configs, and separate viewer ports.
#
# No secrets live in this file: the TechNL key AND the proxy URL are resolved at
# runtime via pass-cli (Proton Pass) — the proxy hostname is intentionally kept
# out of these public dotfiles.
{ config, lib, ... }:

let
  home = config.home.homeDirectory;
in
{
  # ── codemem observer configs (no secrets) ──
  xdg.configFile."codemem/personal.json".text = builtins.toJSON {
    observer_runtime = "claude_sidecar";
    observer_model = "claude-haiku-4-5";
  };

  # NOTE: with observer_provider="anthropic", codemem's _callAnthropicDirect
  # IGNORES observer_base_url — it uses a hardcoded api.anthropic.com unless the
  # env var CODEMEM_ANTHROPIC_ENDPOINT is set (done by cc-work). So the TechNL
  # endpoint is supplied via that env var, NOT via observer_base_url here.
  # The api-key header (what the TechNL proxy expects) is supplied via
  # observer_headers; the token comes from the pass-cli command below
  # (observer_auth_source = "command"), cached for five minutes.
  xdg.configFile."codemem/work-ahold.json".text = builtins.toJSON {
    observer_runtime = "api_http";
    observer_provider = "anthropic";
    observer_model = "claude-haiku-4-5";
    observer_auth_source = "command";
    observer_auth_command = [ "pass-cli" "item" "view" "pass://Ahold/TechNLGenAI/api_key" ];
    observer_auth_cache_ttl_s = 300;
    # literal ${auth.token} — escaped so Nix doesn't interpolate it.
    observer_headers."api-key" = "\${auth.token}";
  };

  # ── Per-lane runtime folders (separate dirs → separate viewer locks) ──
  home.activation.codememDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${home}/.codemem/personal ${home}/.codemem/work-ahold
  '';
}
