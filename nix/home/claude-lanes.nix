# Two Claude Code lanes — shared across all hosts.
#
#   personal → config dir ~/.claude       → Claude Max login
#              (desktop app, `claude`, or `cc-personal`)
#   work     → config dir ~/.claude-work  → TechNL GenAI gateway via DevAI CLI
#              (`cc-work` → `devai-claude`, terminal only)
#
# The Claude desktop app has ONE inference setup for the whole app (Max login
# or a single third-party gateway) and no CLAUDE_CONFIG_DIR, so it can only
# host the personal lane. The work lane is the CLI under `cc-work` — run it in
# any terminal, including the desktop app's own terminal pane.
#
# Gateway vs isolation: DevAI CLI (`devai-claude`, Ahold's sanctioned
# launcher) owns the gateway — Entra ID / key auth, its local compatibility
# proxy, model routing. It does not separate Claude Code's config, so cc-work
# wraps it with the isolation layer below; without that, a work session would
# load the personal plugins, skills and codemem lane (whose observer extracts
# via Max).
#
# Isolation layers:
#   - Separate CLAUDE_CONFIG_DIR per lane: settings, plugins, transcripts,
#     auto-memory and the Keychain credential are all per directory, so the
#     work lane never sees the personal Max login or personal plugins.
#   - cc-work launches devai-claude, and points codemem's work observer at the
#     TechNL proxy (URL from pass-cli); it fails closed if either is missing.
#   - Work hooks (lane-check.sh) block every prompt and tool call unless the
#     session was started by cc-work with a non-Anthropic gateway in place.
#   - Personal hooks (work-lane-guard.sh) block every prompt and tool call that
#     touches a client work tree, so opening an Ahold repo in the desktop app
#     can't send it through Max.
#   - Each lane exports its own codemem DB/config/viewer port and hook
#     spool/lock/context folders (codemem.nix owns the observer configs).
#
# ~/.claude*/settings.json are rewritten by Claude Code at runtime, so they
# can't be Nix-store symlinks. Instead the activation step below merges the
# keys this module owns (env, its hooks, a few settings) into whatever is
# there, leaving everything else alone.
#
# No secrets live in this file: DevAI CLI holds the gateway credential, and
# the TechNL proxy URL (codemem's observer endpoint) is resolved by pass-cli at
# launch.
{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  personalDir = "${home}/.claude";
  workDir = "${home}/.claude-work";

  # Client work trees the personal lane must never touch.
  workRoots = [ "${home}/projects/ahold" ];

  codememEnv = lane: {
    CODEMEM_DB = "${home}/.codemem/${lane}/mem.sqlite";
    CODEMEM_PLUGIN_LOG = "${home}/.codemem/${lane}/plugin.log";
    CODEMEM_CLAUDE_HOOK_SPOOL_DIR = "${home}/.codemem/${lane}/claude-hook-spool";
    CODEMEM_CLAUDE_HOOK_LOCK_DIR = "${home}/.codemem/${lane}/claude-hook-ingest.lock";
    CODEMEM_CLAUDE_HOOK_CONTEXT_DIR = "${home}/.codemem/${lane}/claude-hook-context";
  };

  personalEnv = codememEnv "personal" // {
    CODEMEM_CONFIG = "${home}/.config/codemem/personal.json";
    CODEMEM_VIEWER_PORT = "4747";
    CC_WORK_ROOTS = lib.concatStringsSep ":" workRoots;
  };

  # Non-secret work env, also written to ~/.claude-work/settings.json so
  # codemem stays in the work lane even if devai-claude rebuilds the
  # environment it hands to Claude Code.
  workEnv = codememEnv "work-ahold" // {
    CODEMEM_CONFIG = "${home}/.config/codemem/work-ahold.json";
    CODEMEM_VIEWER_PORT = "4848";
    CODEMEM_PROJECT = "ahold";
    # No telemetry, error reports, auto-updates or feature-flag calls to Anthropic.
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };

  # Model aliases → TechNL model ids, set on the launch env only (never in
  # settings.json, whose env would override whatever devai-claude sets), so
  # DevAI's own model routing wins when it provides one. Agents and /model use
  # the aliases (opus/sonnet/haiku), so tiers resolve inside the gateway.
  workModelEnv = {
    ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5-5";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-6";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5";
  };

  # Everything either launcher sets or must not inherit from the calling shell.
  laneVars = [
    "CLAUDE_CONFIG_DIR" "CC_LANE"
    "ANTHROPIC_BASE_URL" "ANTHROPIC_API_KEY" "ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_CUSTOM_HEADERS" "ANTHROPIC_MODEL" "CLAUDE_CODE_OAUTH_TOKEN"
    "CLAUDE_CODE_USE_BEDROCK" "CLAUDE_CODE_USE_VERTEX" "CLAUDE_CODE_USE_FOUNDRY"
    "CODEMEM_ANTHROPIC_ENDPOINT" "TECHNL_GENAI_KEY" "TECHNL_PROXY_URL"
  ] ++ lib.attrNames workEnv ++ lib.attrNames workModelEnv ++ lib.attrNames personalEnv;

  unsetLaneVars = lib.concatMapStringsSep " " (v: "-u ${v}") (lib.unique laneVars);
  assignments = env: lib.concatStringsSep " "
    (lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}") env);

  hook = command: { type = "command"; inherit command; };

  personalOwned = {
    env = personalEnv;
    hooks = {
      UserPromptSubmit = [ { hooks = [ (hook "${personalDir}/hooks/work-lane-guard.sh") ]; } ];
      PreToolUse = [ { matcher = "*"; hooks = [ (hook "${personalDir}/hooks/work-lane-guard.sh") ]; } ];
    };
  };

  workOwned = {
    env = workEnv;
    hooks = {
      SessionStart = [ { hooks = [ (hook "${workDir}/hooks/agents-md.sh") ]; } ];
      UserPromptSubmit = [ { hooks = [ (hook "${workDir}/hooks/lane-check.sh") ]; } ];
      PreToolUse = [ { matcher = "*"; hooks = [ (hook "${workDir}/hooks/lane-check.sh") ]; } ];
    };
    # WebFetch's preflight sends the target hostname to api.anthropic.com.
    set.skipWebFetchPreflight = true;
    default.model = "opus";
  };

  # merge-claude-settings <settings.json> <owned.json> <managed hook prefix> [seed.json]
  # A missing settings file starts from the seed (the reference snapshot), so
  # a fresh machine gets it even though this runs before setup.sh's seed step.
  # Owned env keys and `set` keys overwrite; owned hooks replace any earlier
  # hooks whose command lives under the managed prefix; `default` keys are
  # written only when absent (so /model and friends keep working).
  mergeSettings = pkgs.writeShellScript "merge-claude-settings" ''
    set -euo pipefail
    file="$1"; owned="$2"; prefix="$3"; seed="''${4:-}"
    mkdir -p "$(dirname "$file")"
    if [ ! -s "$file" ]; then
      if [ -n "$seed" ]; then cat "$seed" >"$file"; else printf '{}\n' >"$file"; fi
    fi
    tmp="$(mktemp "$file.XXXXXX")"
    ${pkgs.jq}/bin/jq --slurpfile owned "$owned" --arg prefix "$prefix" '
      $owned[0] as $o
      | .env = ((.env // {}) + ($o.env // {}))
      | .hooks = (
          ((.hooks // {})
            | with_entries(.value |= map(select(
                ([.hooks[]?.command // ""] | any(startswith($prefix))) | not))))
          as $kept
          | reduce (($o.hooks // {}) | to_entries[]) as $e
              ($kept; .[$e.key] = ((.[$e.key] // []) + $e.value))
          | with_entries(select(.value | length > 0)))
      | . * ($o.set // {})
      | reduce (($o.default // {}) | to_entries[]) as $d
          (.; if has($d.key) then . else .[$d.key] = $d.value end)
    ' "$file" >"$tmp"
    mv "$tmp" "$file"
  '';

  ownedJson = name: value: pkgs.writeText "${name}.json" (builtins.toJSON value);

  overlayDir = ../../system/.claude-work/ahold;
  overlayFiles = lib.sort lib.lessThan (lib.attrNames (lib.filterAttrs
    (name: type: type == "regular" && lib.hasSuffix ".md" name)
    (builtins.readDir overlayDir)));
  workClaudeMd = lib.concatStringsSep "\n\n"
    ([ (builtins.readFile ../../system/.claude/CLAUDE.md) ]
      ++ map (f: builtins.readFile (overlayDir + "/${f}")) overlayFiles);
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "cc-tooling"
      (builtins.readFile ../../system/bin/cc-tooling.sh))
  ];

  home.file = {
    # Personal lane (~/.claude). agents/commands/skills are linked in files.nix.
    ".claude/CLAUDE.md".source = ../../system/.claude/CLAUDE.md;
    ".claude/hooks".source = ../../system/.claude/hooks;

    # Work lane (~/.claude-work). Same agents and commands; no personal skills
    # (the vault-* skills read the personal Obsidian vault).
    ".claude-work/CLAUDE.md".text = workClaudeMd;
    ".claude-work/agents".source = ../../system/.claude/agents;
    ".claude-work/commands".source = ../../system/.claude/commands;
    ".claude-work/hooks".source = ../../system/.claude-work/hooks;
  };

  home.activation.claudeLaneSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${mergeSettings} ${personalDir}/settings.json ${ownedJson "claude-personal-owned" personalOwned} ${personalDir}/hooks/ ${../../system/.claude/settings.json}
    run ${mergeSettings} ${workDir}/settings.json ${ownedJson "claude-work-owned" workOwned} ${workDir}/hooks/
  '';

  programs.zsh.initContent = lib.mkAfter ''
    # Claude Code lanes (see nix/home/claude-lanes.nix)
    cc-personal() {
      env ${unsetLaneVars} ${assignments personalEnv} claude "$@"
    }
    cc-work() {
      # DevAI CLI owns the gateway (auth, local proxy, model routing).
      command -v devai-claude >/dev/null 2>&1 || {
        print -u2 "cc-work: devai-claude not found — install DevAI CLI and run 'devai setup' first"; return 1
      }
      # codemem's work observer calls the TechNL proxy directly (its key comes
      # from the pass-cli auth command in work-ahold.json). Without this
      # endpoint it would default to api.anthropic.com, so fail closed.
      local technl_proxy
      technl_proxy="$(pass-cli item view 'pass://Ahold/TechNLGenAI/proxy_url')" || {
        print -u2 "cc-work: failed to resolve TechNL proxy URL from pass-cli"; return 1
      }
      [[ "$technl_proxy" == https://*/v1 ]] || {
        print -u2 "cc-work: unexpected TechNL proxy URL shape (expected https://…/v1)"; return 1
      }
      # Also pin the endpoint in the work settings env (a local file, never in
      # the repo), which Claude Code applies to its hooks and MCP servers even
      # if devai-claude rebuilds the launch environment.
      local settings=${lib.escapeShellArg "${workDir}/settings.json"} tmp
      tmp="$(mktemp "$settings.XXXXXX")" &&
        ${pkgs.jq}/bin/jq --arg ep "$technl_proxy/messages" \
          '.env.CODEMEM_ANTHROPIC_ENDPOINT = $ep' "$settings" >"$tmp" &&
        mv "$tmp" "$settings" || {
        rm -f "$tmp"; print -u2 "cc-work: failed to update $settings"; return 1
      }
      # codemem <= 0.36 hook ingest posts to 127.0.0.1:38888 regardless of
      # CODEMEM_VIEWER_PORT, so a viewer there would receive work events.
      if lsof -nP -iTCP:38888 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print -u2 "cc-work: a codemem viewer is listening on port 38888 and would receive work events; stop it first (lsof -nP -iTCP:38888)"; return 1
      fi
      env ${unsetLaneVars} \
        CLAUDE_CONFIG_DIR=${lib.escapeShellArg workDir} \
        CC_LANE=work \
        CODEMEM_ANTHROPIC_ENDPOINT="$technl_proxy/messages" \
        ${assignments workEnv} \
        ${assignments workModelEnv} \
        devai-claude -- "$@"
    }
    # One-time per machine, after the first rebuild: install the codemem plugin
    # into both lanes (plugins are per config dir). Personal runs with
    # CLAUDE_CONFIG_DIR unset so its global state stays in ~/.claude.json.
    cc-lanes-setup() {
      local lane
      for lane in personal work; do
        local -a scope=(env -u CLAUDE_CONFIG_DIR)
        [[ $lane == work ]] && scope=(env CLAUDE_CONFIG_DIR=${lib.escapeShellArg workDir})
        print "== $lane lane"
        "''${scope[@]}" claude plugin marketplace add kunickiaj/codemem &&
          "''${scope[@]}" claude plugin install codemem@codemem-marketplace || return 1
      done
    }
  '';
}
