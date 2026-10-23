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
#
# Commits and tags are signed with an SSH key from the Proton Pass agent
# (docs/ssh.md#commit-signing): the profiles pick the key per identity.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.git;
  signing = cfg.personalSigningKey != null;

  personal = {
    user = {
      name = "yvan";
      email = "yvanstemmerik@gmail.com";
    };
    # The macOS keychain helper keeps one github.com login per username.
    credential."https://github.com".username = "GnrlSchnavy";
  };

  # ssh-keygen with the Proton Pass agent: git signs through SSH_AUTH_SOCK,
  # which points at macOS's own agent, in the shell and in apps like IntelliJ.
  sshKeygen = pkgs.writeShellApplication {
    name = "git-ssh-keygen";
    runtimeInputs = [ pkgs.openssh ];
    runtimeEnv.SSH_AUTH_SOCK = config.dotfiles.ssh.signingSocket;
    text = ''exec ssh-keygen "$@"'';
  };
in
{
  options.dotfiles.git = {
    personalSigningKey = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./ssh/github.pub";
      description = "Public half of the SSH key the personal identity signs with on this Mac (its private half is in the Proton Pass agent). Without one, nothing is signed.";
    };
    allowedSigners = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Email → public key: the signatures `git log --show-signature` trusts.";
    };
  };

  config.dotfiles.git.allowedSigners = lib.mkIf signing {
    ${personal.user.email} = cfg.personalSigningKey;
  };

  config.xdg.configFile."git/allowed_signers" = lib.mkIf signing {
    text = lib.concatStrings (
      lib.mapAttrsToList (
        email: key: ''${email} namespaces="git" ${builtins.readFile key}''
      ) cfg.allowedSigners
    );
  };

  config.programs.git = {
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
          contents = lib.recursiveUpdate personal {
            core.hooksPath = ".githooks";
            user = lib.optionalAttrs signing { signingKey = "${cfg.personalSigningKey}"; };
          };
        })
        [
          "~/.dotfiles/"
          "~/projects/personal/dotfiles/"
        ];

    # The work profile overrides the key for its own identity.
    signing = lib.mkIf signing {
      format = "ssh";
      key = lib.mkDefault "${cfg.personalSigningKey}";
      signByDefault = true;
      signer = lib.getExe sshKeygen;
    };

    settings =
      lib.mapAttrsRecursive (_: lib.mkDefault) personal
      // {
        # Use SSH for GitHub instead of HTTPS. This avoids credential helper
        # prompts entirely. ssh://git@github.com is converted transparently.
        url."ssh://git@github.com".insteadOf = "https://github.com";

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        merge.conflictstyle = "diff3";
        diff.algorithm = "histogram";
        rerere.enabled = true;
      }
      // lib.optionalAttrs signing {
        gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
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
