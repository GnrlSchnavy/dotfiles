# Dotfiles managed by file-pointer rather than typed home-manager
# modules. The source files live in their original locations in the
# repo (editors/, development/, system/) — home-manager just creates
# symlinks at the right place in $HOME.
#
# Use `home.file` (and not `xdg.configFile`) for paths that are
# relative to $HOME. Use `xdg.configFile` for things under
# ~/.config/ when home-manager has a typed equivalent.
{ config, pkgs, ... }:

let
  # The Obsidian vault: the vault-* skills and the notes/note shell functions.
  vault = "${config.home.homeDirectory}/Documents/Obsidian/Yvan_claude";

  # The skills name the vault as @VAULT@; fill in this machine's path.
  skills = pkgs.runCommand "claude-skills" { } ''
    cp -r ${../../system/.claude/skills} $out
    chmod -R u+w $out
    find $out -name '*.md' -exec sed -i 's|@VAULT@|${vault}|g' {} +
    if grep -rq '@VAULT@' $out; then echo "unsubstituted @VAULT@" >&2; exit 1; fi
  '';
in
{
  home.sessionVariables.OBSIDIAN_VAULT = vault;

  home.file = {
    # IntelliJ IDEA Vim plugin config
    ".ideavimrc".source = ../../editors/.ideavimrc;

    # NOTE: ~/.docker/config.json is intentionally NOT managed by
    # home-manager. Docker Desktop rewrites that file at runtime
    # (current context, credential store, login state); a Nix-store
    # symlink is read-only, so its atomic rename(2) fails with
    # "cross-device link". Let Docker Desktop own the file.
    # development/.docker/config.json stays in the repo as a reference
    # of the values we'd otherwise pin.

    # Claude Code config. Only manage the files/dirs we explicitly
    # version-control; leave everything else under ~/.claude/
    # (transcripts, plugin caches, session state) untouched.
    ".claude/README.md".source = ../../system/.claude/README.md;

    # Custom Claude content — static, never rewritten by the app, so
    # safe to symlink as read-only directories into the Nix store.
    ".claude/agents".source = ../../system/.claude/agents;
    ".claude/commands".source = ../../system/.claude/commands;
    ".claude/skills".source = skills;

    # NOTE: ~/.claude/settings.json is intentionally NOT symlinked. Claude
    # Code rewrites it at runtime (plugin toggles, effortLevel, etc.); a
    # read-only Nix-store symlink breaks the app's atomic rename(2) — the
    # same failure mode as ~/.docker/config.json above. claude-lanes.nix
    # creates it from the system/.claude/settings.json snapshot and merges
    # its owned keys into it on every rebuild.
  };
}
