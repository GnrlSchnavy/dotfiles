# Git configuration.
#
# Writes ~/.config/git/config (XDG path) and ~/.config/git/ignore for
# global ignore patterns. `core.excludesfile` is intentionally not set
# — git reads ~/.config/git/ignore by default, so we don't need the
# legacy ~/.gitignore_global path that the Stow-managed setup used.
{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "yvanstemmerik-ah";
        email = "yvan.stemmerik@ah.nl";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "diff3";
      diff.algorithm = "histogram";
      rerere.enabled = true;
    };

    # Global ignore patterns (writes ~/.config/git/ignore).
    # Combines what was previously split between ~/.gitignore_global
    # and ~/.config/git/ignore in the Stow layout.
    ignores = [
      # macOS
      ".DS_Store"
      "._*"
      ".Spotlight-V100"
      ".Trashes"

      # Editors
      ".idea/"
      ".vscode/"
      "*.swp"
      "*.swo"
      "*~"

      # Environment files
      ".env"
      ".env.local"
      ".env.*.local"

      # Vim
      "*.un~"

      # Claude Code
      "**/.claude/settings.local.json"
      "**/CLAUDE.local.md"
    ];
  };
}
