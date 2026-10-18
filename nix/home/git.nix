# Git configuration.
#
# Writes ~/.config/git/config (XDG path) and ~/.config/git/ignore for
# global ignore patterns. `core.excludesfile` is intentionally not set
# — git reads ~/.config/git/ignore by default, so we don't need the
# legacy ~/.gitignore_global path that the Stow-managed setup used.
#
# The personal identity is the default; the work profile overrides it
# (nix/profiles/work/git.nix). The dotfiles themselves always commit as
# personal, on every machine.
{ lib, ... }:

let
  personal = {
    user = {
      name = "yvan";
      email = "yvanstemmerik@gmail.com";
    };
    # The macOS keychain helper keeps one github.com login per username.
    credential."https://github.com".username = "GnrlSchnavy";
  };
in
{
  programs.git = {
    enable = true;

    # Both dotfiles clones — ~/.dotfiles for rebuilds and
    # ~/projects/personal/dotfiles for editing (docs/hosts.md) — commit as
    # personal and run the repo's pre-commit hook (.githooks/: lint + secrets
    # scan; a relative hooksPath resolves from the repo root). The trailing
    # slash makes `gitdir:` match recursively.
    includes =
      map
        (dir: {
          condition = "gitdir:${dir}";
          contents = personal // {
            core.hooksPath = ".githooks";
          };
        })
        [
          "~/.dotfiles/"
          "~/projects/personal/dotfiles/"
        ];

    settings = lib.mapAttrsRecursive (_: lib.mkDefault) personal // {
      # Use SSH for GitHub instead of HTTPS. This avoids credential helper
      # prompts entirely. ssh://git@github.com is converted transparently.
      url."ssh://git@github.com".insteadOf = "https://github.com";

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
