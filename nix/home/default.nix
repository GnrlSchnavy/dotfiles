# User-level (home-manager) configuration entry point.
#
# Anything that lives in $HOME — shell config, dotfiles, per-user
# programs — is configured here. System-level config (packages,
# homebrew, system defaults) stays in nix/modules/.
#
# `home.username` and `home.homeDirectory` are derived from
# users.users.<name>.home in the host descriptor (see hosts/m4/default.nix).
{ ... }:

{
  # git.nix is intentionally NOT here — it's per-host (different identity
  # per machine), pulled in via the descriptor's homeModules list.
  imports = [
    ./files.nix
    ./zsh.nix
    ./codemem.nix
    ./opencode.nix
  ];

  # First state version we ship under home-manager. Don't change without
  # reading the home-manager release notes for the new value.
  home.stateVersion = "25.11";
}
