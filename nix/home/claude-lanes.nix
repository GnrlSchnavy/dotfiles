# Two Claude Code lanes — shared across all hosts.
#
#   personal → config dir ~/.claude       → Claude Max login
#              (desktop app, `claude`, or `cc-personal`)
#   work     → config dir ~/.claude-work  → TechNL GenAI gateway via DevAI CLI
#              (`cc-work` → `devai-claude` in a terminal, or
#               `cc-work-desktop` → `devai-claude-desktop` for the desktop app)
#
# The Claude desktop app runs in ONE deployment mode at a time: 1p (Claude
# account, profile dir "Claude") or 3p (gateway, profile dir "Claude-3p").
# Switching relaunches the app. So the desktop app is either the personal lane
# or — via cc-work-desktop — the work lane, never both at once; personal work
# can move to another Claude Code front end (e.g. T3 Code) while it's in 3p.
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
#     session's gateway URL is not Anthropic (1p desktop sessions get
#     api.anthropic.com, plain `claude` gets none) and codemem's observer
#     points at the TechNL proxy.
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
{
  config,
  lib,
  pkgs,
  ...
}:

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

  # Non-secret work env, also written to ~/.claude-work/settings.json so every
  # work session gets it — CLI (devai-claude may rebuild the launch env) and
  # the desktop app's Code tab in gateway mode alike.
  workEnv = codememEnv "work-ahold" // {
    CODEMEM_CONFIG = "${home}/.config/codemem/work-ahold.json";
    CODEMEM_VIEWER_PORT = "4848";
    CODEMEM_PROJECT = "ahold";
    CC_LANE = "work";
    # Model aliases → TechNL model ids. Agents and /model use the aliases
    # (opus/sonnet/haiku), so tiers resolve inside the gateway; /model can
    # still pick any other id the gateway serves.
    ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5-5";
    ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5-5";
    ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5";
    # No telemetry, error reports, auto-updates or feature-flag calls to Anthropic.
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
  };

  # Everything either launcher sets or must not inherit from the calling shell.
  laneVars = [
    "CLAUDE_CONFIG_DIR"
    "CC_LANE"
    "ANTHROPIC_BASE_URL"
    "ANTHROPIC_API_KEY"
    "ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_CUSTOM_HEADERS"
    "ANTHROPIC_MODEL"
    "CLAUDE_CODE_OAUTH_TOKEN"
    "CLAUDE_CODE_USE_BEDROCK"
    "CLAUDE_CODE_USE_VERTEX"
    "CLAUDE_CODE_USE_FOUNDRY"
    "CODEMEM_ANTHROPIC_ENDPOINT"
    "TECHNL_GENAI_KEY"
    "TECHNL_PROXY_URL"
  ]
  ++ lib.attrNames workEnv
  ++ lib.attrNames personalEnv;

  unsetLaneVars = lib.concatMapStringsSep " " (v: "-u ${v}") (lib.unique laneVars);
  assignments =
    env: lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}") env);

  hook = command: {
    type = "command";
    inherit command;
  };

  # Plugins are declared rather than installed by hand: when an interactive
  # session starts, Claude Code adds the declared marketplaces and fetches
  # any enabled plugin it doesn't have yet (Anthropic's official marketplace
  # is added on its own). false disables an installed plugin. A /plugin
  # toggle on a plugin listed here lasts until the next rebuild.
  codememPlugin = {
    extraKnownMarketplaces.codemem-marketplace.source = {
      source = "github";
      repo = "kunickiaj/codemem";
    };
    enabledPlugins."codemem@codemem-marketplace" = true;
  };

  personalOwned = {
    env = personalEnv;
    union = {
      # The boundary for the file tools: Claude Code resolves these paths itself
      # (relative, ~, symlinks), and Read rules also cover Grep and Glob.
      permissions.deny = lib.concatMap (root: [
        "Read(/${root}/**)"
        "Edit(/${root}/**)"
      ]) workRoots;
      # The boundary for Bash (macOS Seatbelt). Sandbox paths are plain
      # absolute or ~/ — not the // form permission rules use. Builds still
      # need their caches and registries.
      sandbox.filesystem.denyRead = workRoots;
      sandbox.filesystem.allowWrite = [
        "~/.m2"
        "~/.gradle"
        "~/.npm"
      ];
      sandbox.network.allowedDomains = [
        "repo.maven.apache.org"
        "repo1.maven.org"
        "services.gradle.org"
        "plugins.gradle.org"
        "downloads.gradle.org"
        "registry.npmjs.org"
        "192.168.1.106:6443" # k3s API (kubectl/flux, via the sandbox proxy)
        "github.com" # git over SSH, tunnelled through the proxy
        "api.cloudflare.com" # wrangler
      ];
    };
    set = lib.recursiveUpdate codememPlugin {
      # Forced on every rebuild: a failed sandboxed command may not be
      # retried outside the sandbox, so the boundary holds in auto mode too.
      sandbox = {
        enabled = true;
        allowUnsandboxedCommands = false;
      };
      enabledPlugins = {
        "superpowers@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "context7@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "skill-creator@claude-plugins-official" = true;
        "playwright@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "kotlin-lsp@claude-plugins-official" = true;
        # Not for JVM work.
        "clangd-lsp@claude-plugins-official" = false;
        "swift-lsp@claude-plugins-official" = false;
      };
    };
    # Keep Bash permission prompts as they were (only written when unset).
    default.sandbox.autoAllowBashIfSandboxed = false;
    # work-lane-guard.sh adds prompts, MCP tools and case-insensitive matching.
    hooks = {
      UserPromptSubmit = [ { hooks = [ (hook "${personalDir}/hooks/work-lane-guard.sh") ]; } ];
      PreToolUse = [
        {
          matcher = "*";
          hooks = [ (hook "${personalDir}/hooks/work-lane-guard.sh") ];
        }
      ];
    };
  };

  workOwned = {
    env = workEnv;
    hooks = {
      SessionStart = [ { hooks = [ (hook "${workDir}/hooks/agents-md.sh") ]; } ];
      UserPromptSubmit = [ { hooks = [ (hook "${workDir}/hooks/lane-check.sh") ]; } ];
      PreToolUse = [
        {
          matcher = "*";
          hooks = [ (hook "${workDir}/hooks/lane-check.sh") ];
        }
      ];
    };
    set = codememPlugin // {
      # WebFetch's preflight sends the target hostname to api.anthropic.com.
      skipWebFetchPreflight = true;
    };
    default.model = "opus";
  };

  # Merges each lane's owned keys into its settings.json on every rebuild;
  # what it owns and how is described at the top of the script.
  mergeSettings = pkgs.writeShellApplication {
    name = "merge-claude-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../system/bin/merge-claude-settings.sh;
  };

  ownedJson = name: value: pkgs.writeText "${name}.json" (builtins.toJSON value);

  overlayDir = ../../system/.claude-work/ahold;
  overlayFiles = lib.sort lib.lessThan (
    lib.attrNames (
      lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (
        builtins.readDir overlayDir
      )
    )
  );
  workClaudeMd = lib.concatStringsSep "\n\n" (
    [ (builtins.readFile ../../system/.claude/CLAUDE.md) ]
    ++ map (f: builtins.readFile (overlayDir + "/${f}")) overlayFiles
  );
in
{
  home.packages = [
    # writeShellApplication shellchecks the script at build time and pins its tools.
    (pkgs.writeShellApplication {
      name = "cc-tooling";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gawk
        pkgs.git
      ];
      text = builtins.readFile ../../system/bin/cc-tooling.sh;
    })
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
    run ${mergeSettings}/bin/merge-claude-settings ${personalDir}/settings.json ${ownedJson "claude-personal-owned" personalOwned} ${personalDir}/hooks/ ${../../system/.claude/settings.json}
    run ${mergeSettings}/bin/merge-claude-settings ${workDir}/settings.json ${ownedJson "claude-work-owned" workOwned} ${workDir}/hooks/
  '';

  programs.zsh.initContent = lib.mkAfter ''
    # Claude Code lanes (see nix/home/claude-lanes.nix)
    cc-personal() {
      env ${unsetLaneVars} ${assignments personalEnv} claude "$@"
    }
    # Shared work-lane preparation for cc-work and cc-work-desktop. Sets
    # $technl_proxy in the caller (declare it local there).
    _cc_work_prepare() {
      # DevAI CLI owns the gateway (auth, local proxy, model routing).
      command -v devai-claude >/dev/null 2>&1 || {
        print -u2 "cc-work: DevAI CLI not found — install it and run 'devai setup' first"; return 1
      }
      # codemem's work observer calls the TechNL proxy directly (its key comes
      # from the pass-cli auth command in work-ahold.json). Without this
      # endpoint it would default to api.anthropic.com, so fail closed.
      # pass-get (secrets.nix) fails closed, empty values included.
      technl_proxy="$(pass-get 'pass://Ahold/TechNLGenAI/proxy_url')" || {
        print -u2 "cc-work: failed to resolve the TechNL proxy URL"; return 1
      }
      [[ "$technl_proxy" == https://*/v1 ]] || {
        print -u2 "cc-work: unexpected TechNL proxy URL shape (expected https://…/v1)"; return 1
      }
      # Pin the endpoint in the work settings env (a local file, never in the
      # repo), which Claude Code applies to its hooks and MCP servers however
      # the session was launched. Written only when it differs, so a launch
      # doesn't race a running work session saving the same file.
      local settings=${lib.escapeShellArg "${workDir}/settings.json"} tmp
      local ep="$technl_proxy/messages"
      if [[ "$(${pkgs.jq}/bin/jq -r '.env.CODEMEM_ANTHROPIC_ENDPOINT // empty' "$settings" 2>/dev/null)" != "$ep" ]]; then
        tmp="$(mktemp "$settings.XXXXXX")" &&
          ${pkgs.jq}/bin/jq --arg ep "$ep" \
            '.env.CODEMEM_ANTHROPIC_ENDPOINT = $ep' "$settings" >"$tmp" &&
          mv "$tmp" "$settings" || {
          rm -f "$tmp"; print -u2 "cc-work: failed to update $settings"; return 1
        }
      fi
      # codemem <= 0.36 hook ingest posts to 127.0.0.1:38888 regardless of
      # CODEMEM_VIEWER_PORT, so a viewer there would receive work events.
      if lsof -nP -iTCP:38888 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print -u2 "cc-work: a codemem viewer is listening on port 38888 and would receive work events; stop it first (lsof -nP -iTCP:38888)"; return 1
      fi
    }
    cc-work() {
      local technl_proxy
      _cc_work_prepare || return 1
      env ${unsetLaneVars} \
        CLAUDE_CONFIG_DIR=${lib.escapeShellArg workDir} \
        CODEMEM_ANTHROPIC_ENDPOINT="$technl_proxy/messages" \
        ${assignments workEnv} \
        devai-claude -- "$@"
    }
    # Work lane in the Claude desktop app: devai-claude-desktop switches the
    # whole app to its gateway profile (Claude-3p) and RESTARTS it, so run this
    # from a regular terminal, not the app's own terminal pane. --detach keeps
    # DevAI's proxy running after this shell exits. The Code tab must also use
    # ~/.claude-work: set CLAUDE_CONFIG_DIR in the work profile's local
    # environment (see docs/claude-code.md) unless the launch env reaches it.
    cc-work-desktop() {
      local technl_proxy
      _cc_work_prepare || return 1
      env ${unsetLaneVars} \
        CLAUDE_CONFIG_DIR=${lib.escapeShellArg workDir} \
        CODEMEM_ANTHROPIC_ENDPOINT="$technl_proxy/messages" \
        ${assignments workEnv} \
        devai-claude-desktop --detach "$@"
    }
    # Fallback only: the codemem plugin is declared in both lanes' settings and
    # fetched by the first interactive session. This installs it right away
    # (e.g. when a lane has only run `claude -p` so far). Personal runs with
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
