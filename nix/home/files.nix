# Dotfiles managed by file-pointer rather than typed home-manager
# modules. The source files live in their original locations in the
# repo (editors/, system/) — home-manager just creates symlinks at the
# right place in $HOME. Claude Code's files are linked in claude-code.nix.
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
    # home-manager. Docker rewrites that file at runtime (Colima's
    # current context, credentials); a Nix-store symlink is read-only,
    # so its atomic rename(2) fails with "cross-device link".

    # NOTE: ~/.claude/settings.json is intentionally NOT symlinked either,
    # for the same reason; claude-code.nix merges its owned keys into it.
  };
}
