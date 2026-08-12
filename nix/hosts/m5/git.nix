# Git configuration.
#
# Writes ~/.config/git/config (XDG path) and ~/.config/git/ignore for
# global ignore patterns. `core.excludesfile` is intentionally not set
# — git reads ~/.config/git/ignore by default, so we don't need the
# legacy ~/.gitignore_global path that the Stow-managed setup used.
#
# m5 is both the work and the personal machine (m4 was sold in August
# 2026), so the identity is conditional: work by default, personal for
# the paths listed in `includes` below.
{ ... }:

let
  personal = {
    name = "yvan";
    email = "yvanstemmerik@gmail.com";
  };
in
{
  programs.git = {
    enable = true;

    # Personal identity for personal checkouts. BOTH paths matter: this
    # dotfiles repo is cloned twice — ~/projects/personal/dotfiles for
    # editing and ~/.dotfiles for rebuilds (see docs/hosts.md) — and
    # without the second entry, commits made from ~/.dotfiles would go
    # out under the work identity.
    #
    # A trailing slash makes `gitdir:` match recursively, so every repo
    # beneath the directory is covered. Git evaluates includes in order
    # and last-wins, so these override the `user` block below.
    includes = [
      {
        condition = "gitdir:~/projects/personal/";
        contents.user = personal;
      }
      {
        condition = "gitdir:~/.dotfiles/";
        contents.user = personal;
      }
    ];

    settings = {
      # Work identity — the default for anything not matched above.
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
