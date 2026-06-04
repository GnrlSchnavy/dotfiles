# Dotfiles managed by file-pointer rather than typed home-manager
# modules. The source files live in their original locations in the
# repo (editors/, development/, system/) — home-manager just creates
# symlinks at the right place in $HOME.
#
# Use `home.file` (and not `xdg.configFile`) for paths that are
# relative to $HOME. Use `xdg.configFile` for things under
# ~/.config/ when home-manager has a typed equivalent.
{ ... }:

{
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
    ".claude/settings.local.json".source = ../../system/.claude/settings.local.json;
    ".claude/settings.template.json".source = ../../system/.claude/settings.template.json;
    ".claude/README.md".source = ../../system/.claude/README.md;

    # Custom Claude content — static, never rewritten by the app, so
    # safe to symlink as read-only directories into the Nix store.
    ".claude/agents".source = ../../system/.claude/agents;
    ".claude/commands".source = ../../system/.claude/commands;
    ".claude/skills".source = ../../system/.claude/skills;

    # NOTE: ~/.claude/settings.json and ~/.claude-mem/settings.json are
    # intentionally NOT symlinked. Both are rewritten at runtime (plugin
    # toggles, effortLevel, feedbackSurveyState, etc.); a read-only
    # Nix-store symlink breaks the app's atomic rename(2) — the same
    # failure mode as ~/.docker/config.json above. The copies under
    # system/.claude/settings.json and system/.claude-mem/settings.json
    # are kept as reference snapshots to re-seed a fresh machine; copy
    # them into place manually after the first rebuild (see CLAUDE.md).
  };
}
