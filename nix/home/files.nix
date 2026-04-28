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

    # Docker CLI config (Desktop manages credentials, plugins, hooks)
    ".docker/config.json".source = ../../development/.docker/config.json;

    # Claude Code config. Only manage the three files we explicitly
    # version-control; leave everything else under ~/.claude/
    # (transcripts, plugin caches, session state) untouched.
    ".claude/settings.local.json".source = ../../system/.claude/settings.local.json;
    ".claude/settings.template.json".source = ../../system/.claude/settings.template.json;
    ".claude/README.md".source = ../../system/.claude/README.md;
  };
}
