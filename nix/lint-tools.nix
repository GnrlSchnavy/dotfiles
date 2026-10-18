# The tools scripts/lint.sh runs. One list for both places that provide them:
# the `nix develop ./nix` shell (flake.nix; CI and your own commits) and the
# personal profile's DOTFILES_LINT_PATH (nix/profiles/personal/claude.nix),
# since the Bash sandbox can't reach the Nix daemon that `nix develop` needs.
pkgs: [
  pkgs.nixfmt
  pkgs.statix
  pkgs.deadnix
  pkgs.shellcheck
  pkgs.gitleaks
  pkgs.jq
]
