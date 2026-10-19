# Claude Code, work: everything goes through the TechNL GenAI gateway via
# DevAI CLI (`devai-claude`, Ahold's sanctioned launcher), which owns the
# gateway auth, its local proxy and model routing.
#
#   cc-work          → devai-claude in a terminal
#   cc-work-desktop  → devai-claude-desktop: switches the desktop app to its
#                      gateway profile (Claude-3p)
#
# Fail-closed layers:
#   - cc-work points codemem's observer at the TechNL proxy (URL from
#     pass-cli) and refuses to start if DevAI or the URL is missing.
#   - The gateway-check hook blocks every prompt and tool call unless the
#     session's gateway URL isn't Anthropic (plain `claude` has none) and
#     codemem's observer points at the proxy.
#   - codemem's observer config calls the proxy, never api.anthropic.com.
#
# The plumbing is in nix/home/claude-code.nix and codemem.nix. No secrets
# live here: DevAI CLI holds the gateway credential, and the TechNL key and
# proxy URL are resolved by pass-cli at runtime.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  settingsFile = "${config.home.homeDirectory}/.claude/settings.json";
  hooks = "${config.home.homeDirectory}/.claude/hooks";

  hook = command: {
    type = "command";
    inherit command;
  };

  # Every *.md in the Ahold overlay folder, in name order, appended to the
  # global CLAUDE.md.
  overlayDir = ../../../system/claude-work/ahold;
  overlay = map (f: overlayDir + "/${f}") (
    lib.sort lib.lessThan (
      lib.attrNames (
        lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
          builtins.readDir overlayDir
        )
      )
    )
  );
in
{
  # NOTE: with observer_provider="anthropic", codemem's _callAnthropicDirect
  # IGNORES observer_base_url — it uses a hardcoded api.anthropic.com unless the
  # env var CODEMEM_ANTHROPIC_ENDPOINT is set (done by cc-work). So the TechNL
  # endpoint is supplied via that env var, NOT via observer_base_url here.
  # The api-key header (what the TechNL proxy expects) is supplied via
  # observer_headers; the token comes from the pass-cli command below
  # (observer_auth_source = "command"), cached for five minutes.
  dotfiles.codemem = {
    lane = "work";
    observer = {
      observer_runtime = "api_http";
      observer_provider = "anthropic";
      observer_model = "claude-haiku-4-5";
      observer_auth_source = "command";
      observer_auth_command = [
        "pass-cli"
        "item"
        "view"
        "pass://Ahold/TechNLGenAI/api_key"
      ];
      observer_auth_cache_ttl_s = 300;
      # literal ${auth.token} — escaped so Nix doesn't interpolate it.
      observer_headers."api-key" = "\${auth.token}";
    };
  };

  dotfiles.claude.instructions = overlay;

  dotfiles.claude.settings = {
    # Written to settings.json so every session gets it — CLI (devai-claude
    # may rebuild the launch env) and the desktop app's Code tab alike.
    env = {
      CODEMEM_PROJECT = "ahold";
      # Model aliases → TechNL model ids. Agents and /model use the aliases
      # (opus/sonnet/haiku), so tiers resolve inside the gateway; /model can
      # still pick any other id the gateway serves.
      ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5-5";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5-5";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5";
      # No telemetry, error reports, auto-updates or feature-flag calls to Anthropic.
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
    };
    hooks = {
      SessionStart = [ { hooks = [ (hook "${hooks}/agents-md.sh") ]; } ];
      UserPromptSubmit = [ { hooks = [ (hook "${hooks}/gateway-check.sh") ]; } ];
      PreToolUse = [
        {
          matcher = "*";
          hooks = [ (hook "${hooks}/gateway-check.sh") ];
        }
      ];
    };
    # WebFetch's preflight sends the target hostname to api.anthropic.com.
    set.skipWebFetchPreflight = true;
    default.model = "opus";
  };

  home.file.".claude/hooks".source = ../../../system/claude-work/hooks;

  home.packages = [
    # Per-client Claude Code tooling for client checkouts (docs/client-tooling.md).
    # writeShellApplication shellchecks the script at build time and pins its tools.
    (pkgs.writeShellApplication {
      name = "cc-tooling";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gawk
        pkgs.git
      ];
      text = builtins.readFile ../../../system/bin/cc-tooling.sh;
    })
  ];

  programs.zsh.initContent = lib.mkAfter ''
    # Work Claude Code launchers (nix/profiles/work/claude.nix). Sets
    # $technl_proxy in the caller (declare it local there).
    _cc_work_prepare() {
      # DevAI CLI owns the gateway (auth, local proxy, model routing).
      command -v devai-claude >/dev/null 2>&1 || {
        print -u2 "cc-work: DevAI CLI not found — install it and run 'devai setup' first"; return 1
      }
      # codemem's observer calls the TechNL proxy directly (its key comes from
      # the pass-cli auth command in the observer config). Without this
      # endpoint it would default to api.anthropic.com, so fail closed.
      # pass-get (secrets.nix) fails closed, empty values included.
      technl_proxy="$(pass-get 'pass://Ahold/TechNLGenAI/proxy_url')" || {
        print -u2 "cc-work: failed to resolve the TechNL proxy URL"; return 1
      }
      [[ "$technl_proxy" == https://*/v1 ]] || {
        print -u2 "cc-work: unexpected TechNL proxy URL shape (expected https://…/v1)"; return 1
      }
      # Pin the endpoint in the settings env (a local file, never in the
      # repo), which Claude Code applies to its hooks and MCP servers however
      # the session was launched. Written only when it differs, so a launch
      # doesn't race a running session saving the same file.
      local settings=${lib.escapeShellArg settingsFile} tmp
      local ep="$technl_proxy/messages"
      if [[ "$(${pkgs.jq}/bin/jq -r '.env.CODEMEM_ANTHROPIC_ENDPOINT // empty' "$settings" 2>/dev/null)" != "$ep" ]]; then
        tmp="$(mktemp "$settings.XXXXXX")" &&
          ${pkgs.jq}/bin/jq --arg ep "$ep" \
            '.env.CODEMEM_ANTHROPIC_ENDPOINT = $ep' "$settings" >"$tmp" &&
          mv "$tmp" "$settings" || {
          rm -f "$tmp"; print -u2 "cc-work: failed to update $settings"; return 1
        }
      fi
    }
    cc-work() {
      local technl_proxy
      _cc_work_prepare || return 1
      CODEMEM_ANTHROPIC_ENDPOINT="$technl_proxy/messages" devai-claude -- "$@"
    }
    # devai-claude-desktop switches the whole desktop app to its gateway
    # profile (Claude-3p) and RESTARTS it, so run this from a regular terminal,
    # not the app's own terminal pane. --detach keeps DevAI's proxy running
    # after this shell exits.
    cc-work-desktop() {
      local technl_proxy
      _cc_work_prepare || return 1
      CODEMEM_ANTHROPIC_ENDPOINT="$technl_proxy/messages" devai-claude-desktop --detach "$@"
    }
  '';
}
