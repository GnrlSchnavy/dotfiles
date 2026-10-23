# Claude Code — the shared plumbing, on every host.
#
# One config dir per machine, ~/.claude. The host's profile decides what it
# talks to (personal: Claude Max; work: the DevAI gateway) and contributes
# through the two options below. This module links the shared content
# (agents, commands, global CLAUDE.md) and merges the owned settings.
#
# ~/.claude/settings.json is rewritten by Claude Code at runtime, so it can't
# be a Nix-store symlink. Instead the activation step below merges the keys
# Nix owns into whatever is there, leaving everything else alone.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.claude;
  claudeDir = "${config.home.homeDirectory}/.claude";
  json = pkgs.formats.json { };

  # The dotfiles' lint tools, for the pre-commit hook in the Bash sandbox,
  # where `nix develop` can't run (.githooks/pre-commit).
  lintTools = pkgs.buildEnv {
    name = "dotfiles-lint-tools";
    paths = import ../lint-tools.nix pkgs;
  };

  mergeSettings = pkgs.writeShellApplication {
    name = "merge-claude-settings";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../system/bin/merge-claude-settings.sh;
  };
in
{
  options.dotfiles.claude = {
    settings = lib.mkOption {
      inherit (json) type;
      default = { };
      description = ''
        Keys Nix owns in ~/.claude/settings.json, grouped by how they merge:
        env, union, hooks, default, set (see system/bin/merge-claude-settings.sh).
        Hooks are only managed under ~/.claude/hooks/.
      '';
    };
    instructions = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Files appended, in order, to the global ~/.claude/CLAUDE.md.";
    };
  };

  config = {
    home.file = {
      ".claude/CLAUDE.md".text = lib.concatMapStringsSep "\n\n" builtins.readFile (
        [ ../../system/.claude/CLAUDE.md ] ++ cfg.instructions
      );
      ".claude/README.md".source = ../../system/.claude/README.md;
      # Static, never rewritten by the app, so safe as read-only store links.
      ".claude/agents".source = ../../system/.claude/agents;
      ".claude/commands".source = ../../system/.claude/commands;
    };

    dotfiles.claude.settings.env.DOTFILES_LINT_PATH = "${lintTools}/bin";

    # Secrets Claude has no reason to read, on every host. The Read tool (and
    # Grep/Glob) gets them all; the Bash sandbox only those its commands
    # never need: sandboxed git reads ~/.ssh/config and known_hosts (no key
    # files: those stay in Proton Pass), sandboxed kubectl ~/.kube, and builds
    # ~/.m2/settings.xml. .env.example and committed .env.<mode> stay readable.
    dotfiles.claude.settings.union = {
      permissions.deny = [
        "Read(~/.ssh/**)"
        "Read(~/.kube/**)"
        "Read(~/.dotfiles-backups/**)"
        "Read(~/.codemem/**)"
        "Read(~/.zsh_history)"
        "Read(~/.m2/settings.xml)"
        "Read(~/.docker/config.json)"
        "Read(**/.env)"
        "Read(**/.env.local)"
        "Read(**/.env.*.local)"
      ];
      sandbox.filesystem.denyRead = [
        "~/.dotfiles-backups"
        "~/.codemem"
        "~/.zsh_history"
      ];
    };

    home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${mergeSettings}/bin/merge-claude-settings ${claudeDir}/settings.json ${json.generate "claude-owned.json" cfg.settings} ${claudeDir}/hooks/ ${../../system/.claude/settings.json}
    '';
  };
}
