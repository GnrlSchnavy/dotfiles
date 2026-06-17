# Two-lane codemem memory for OpenCode — shared across all hosts (m4, m5).
#
# codemem gives OpenCode persistent memory. We run it in two isolated lanes
# so client (Ahold) content is NEVER extracted via Anthropic directly — only
# through the sanctioned TechNL proxy:
#
#   oc-personal  → DB ~/.codemem/personal     → extract via local Claude (Max)
#   oc-work      → DB ~/.codemem/work-ahold    → extract via TechNL proxy
#
# Isolation is by separate DB *folders* (the viewer lock is keyed on the DB's
# directory), separate observer configs, and separate viewer ports — all set
# per-lane by the oc-* functions below. The OpenCode plugin forwards
# CODEMEM_DB / CODEMEM_CONFIG / CODEMEM_VIEWER_PORT into the viewer it
# auto-starts, and the extraction sweeper runs inside that per-lane viewer, so
# work extraction provably stays in the TechNL channel.
#
# No secrets live in this file: the TechNL key is resolved at runtime via
# pass-cli (Proton Pass). Paths use config.home.homeDirectory so the same
# module works for both /Users/yvan (m4) and /Users/yvan-sytac (m5).
{ config, lib, ... }:

let
  home = config.home.homeDirectory;
  codememVersion = "0.36.0";
  pluginSpec = "@codemem/opencode-plugin@${codememVersion}";
  technlBase = "https://api-ai.digitaldev.nl/anthropic/v1";

  # codemem MCP server entry — identical in both lanes. It inherits
  # CODEMEM_DB / CODEMEM_CONFIG from the launching oc-* function, so recall is
  # automatically scoped to the active lane.
  codememMcp.codemem = {
    type = "local";
    command = [ "npx" "-y" "codemem@${codememVersion}" "mcp" ];
    enabled = true;
  };
in
{
  # ── Personal OpenCode config (Max via the opencode-with-claude proxy) ──
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ "opencode-with-claude" pluginSpec ];
    mcp = codememMcp;
    provider.anthropic.options = {
      baseURL = "http://127.0.0.1:3456";
      apiKey = "dummy";
    };
    model = "anthropic/claude-sonnet-4-5";
  };

  # ── Work OpenCode config (direct TechNL provider, codemem only) ──
  # Lives outside ~/.config, so home.file (not xdg.configFile). The api-key
  # header is resolved by OpenCode from $TECHNL_GENAI_KEY (set by oc-work).
  home.file."projects/ahold/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    plugin = [ pluginSpec ];
    mcp = codememMcp;
    provider.technl = {
      npm = "@ai-sdk/anthropic";
      name = "TechNL GenAI (work)";
      options = {
        baseURL = technlBase;
        apiKey = "dummy";
        headers."api-key" = "{env:TECHNL_GENAI_KEY}";
      };
      models."claude-sonnet-4-5" = {
        name = "Claude Sonnet 4.5 (TechNL)";
        limit = {
          context = 200000;
          output = 64000;
        };
      };
    };
    model = "technl/claude-sonnet-4-5";
  };

  # ── codemem observer configs (no secrets) ──
  xdg.configFile."codemem/personal.json".text = builtins.toJSON {
    observer_runtime = "claude_sidecar";
    observer_model = "claude-haiku-4-5";
  };

  # NOTE: with observer_provider="anthropic", codemem's _callAnthropicDirect
  # IGNORES observer_base_url — it uses a hardcoded api.anthropic.com unless the
  # env var CODEMEM_ANTHROPIC_ENDPOINT is set (done in oc-work below). So the
  # TechNL endpoint is supplied via that env var, NOT via observer_base_url here.
  # The api-key header (what the TechNL proxy expects) is supplied via
  # observer_headers; the token resolves from ANTHROPIC_API_KEY (set in oc-work),
  # with the pass-cli command as a fallback.
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

  # ── Launch functions (appended to the shared zsh initContent) ──
  programs.zsh.initContent = lib.mkAfter ''
    # codemem two-lane launchers (see nix/home/codemem.nix)
    oc-personal() {
      CODEMEM_DB="${home}/.codemem/personal/mem.sqlite" \
      CODEMEM_CONFIG="${home}/.config/codemem/personal.json" \
      CODEMEM_VIEWER_PORT=4747 \
      CODEMEM_PLUGIN_LOG="${home}/.codemem/personal/plugin.log" \
      OPENCODE_CONFIG="${home}/.config/opencode/opencode.json" \
      opencode "$@"
    }
    oc-work() {
      # Resolve the TechNL key once (used for both coding + observer auth).
      local technl_key
      technl_key="$(pass-cli item view 'pass://Ahold/TechNLGenAI/api_key')" || {
        print -u2 "oc-work: failed to resolve TechNL key from pass-cli"; return 1
      }
      CODEMEM_DB="${home}/.codemem/work-ahold/mem.sqlite" \
      CODEMEM_CONFIG="${home}/.config/codemem/work-ahold.json" \
      CODEMEM_VIEWER_PORT=4848 \
      CODEMEM_PROJECT=ahold \
      CODEMEM_PLUGIN_LOG="${home}/.codemem/work-ahold/plugin.log" \
      CODEMEM_ANTHROPIC_ENDPOINT="${technlBase}/messages" \
      TECHNL_GENAI_KEY="$technl_key" \
      ANTHROPIC_API_KEY="$technl_key" \
      OPENCODE_CONFIG="${home}/projects/ahold/opencode.json" \
      opencode "$@"
    }
  '';

  # ── Per-lane runtime folders (separate dirs → separate viewer locks) ──
  home.activation.codememDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${home}/.codemem/personal ${home}/.codemem/work-ahold
  '';
}
