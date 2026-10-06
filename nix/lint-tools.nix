# The tools scripts/lint.sh runs. One list for both places that provide them:
# the `nix develop ./nix` shell (flake.nix; CI and your own commits) and the
# personal Claude lane's DOTFILES_LINT_PATH (claude-lanes.nix), since the Bash
# sandbox can't reach the Nix daemon that `nix develop` needs.
pkgs: [
  pkgs.nixfmt
  pkgs.statix
  pkgs.deadnix
  pkgs.shellcheck
  pkgs.gitleaks
  pkgs.jq
]
