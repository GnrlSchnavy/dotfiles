# codemem memory — the shared plumbing, on every host.
#
# codemem gives Claude Code persistent memory. The host's profile names the
# memory lane and its observer (the model call that extracts memories):
# personal extracts via the local Claude (Max) sidecar, work via the TechNL
# proxy so client content never reaches Anthropic directly. Without a lane,
# codemem isn't set up.
#
# This module writes the observer config, creates the lane's folder, and
# hands the plugin and its env to Claude Code's settings; the plugin's hooks
# and MCP server (and the viewer the MCP server auto-starts) inherit the env.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.codemem;
  json = pkgs.formats.json { };
  # toString: mkIf still evaluates the attribute names below when lane is null.
  lane = toString cfg.lane;
  dir = "${config.home.homeDirectory}/.codemem/${lane}";
in
{
  options.dotfiles.codemem = {
    lane = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "personal";
      description = "Memory lane: the folder under ~/.codemem and the observer config's name.";
    };
    observer = lib.mkOption {
      inherit (json) type;
      default = { };
      description = "Observer config, written to ~/.config/codemem/<lane>.json. No secrets.";
    };
  };

  config = lib.mkIf (cfg.lane != null) {
    xdg.configFile."codemem/${lane}.json".source = json.generate "codemem-${lane}.json" cfg.observer;

    # For scripts/backup.sh, which backs up only this lane.
    home.sessionVariables.CODEMEM_LANE = lane;

    home.activation.codememDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p ${dir}
    '';

    # Declared rather than installed by hand: the first interactive session
    # adds the marketplace and fetches the plugin.
    dotfiles.claude.settings = {
      env = {
        CODEMEM_DB = "${dir}/mem.sqlite";
        CODEMEM_PLUGIN_LOG = "${dir}/plugin.log";
        CODEMEM_CLAUDE_HOOK_SPOOL_DIR = "${dir}/claude-hook-spool";
        CODEMEM_CLAUDE_HOOK_LOCK_DIR = "${dir}/claude-hook-ingest.lock";
        CODEMEM_CLAUDE_HOOK_CONTEXT_DIR = "${dir}/claude-hook-context";
        CODEMEM_CONFIG = "${config.xdg.configHome}/codemem/${lane}.json";
      };
      set = {
        enabledPlugins."codemem@codemem-marketplace" = true;
      };
      # The marketplace is declared inline so the plugin's files (hooks, MCP
      # launch command) are pinned to one upstream commit: upstream can't
      # change what runs here until this pin is bumped, in a PR. Not pinned:
      # the codemem npm package those hooks fetch with `npx -y`
      # (docs/claude-code.md#codemem-memory). To bump: a release tag's commit
      # (`git ls-remote https://github.com/kunickiaj/codemem 'refs/tags/vX^{}'`),
      # sha and ref together. Replaced outright, so no key of the old github
      # source lingers.
      replace = [
        {
          path = [
            "extraKnownMarketplaces"
            "codemem-marketplace"
          ];
          value.source = {
            source = "settings";
            name = "codemem-marketplace";
            owner.name = "Adam Kunicki";
            plugins = [
              {
                name = "codemem";
                description = "Persistent memory for Claude Code.";
                source = {
                  source = "git-subdir";
                  url = "kunickiaj/codemem";
                  path = "plugins/claude";
                  ref = "v0.46.3";
                  sha = "80e3126486ad5f4e2e9157e74360645b97266a5a";
                };
              }
            ];
          };
        }
      ];
    };

    # Fallback only: installs the plugin right away (e.g. when only
    # `claude -p` has run so far), from the pinned marketplace above.
    programs.zsh.initContent = lib.mkAfter ''
      codemem-setup() {
        claude plugin install codemem@codemem-marketplace
      }
    '';
  };
}
