# User-level (home-manager) configuration.
#
# Anything that lives in $HOME — shell config, dotfiles, per-user
# programs — is configured here. System-level config (packages,
# homebrew, system defaults) stays in nix/modules/.
#
# `home.username` and `home.homeDirectory` are set in flake.nix from
# the host descriptor, so they don't need to be repeated here.
#
# Phase A scaffolding: empty config to verify wiring. Subsequent
# phases will move dotfiles in here from the Stow tree.
{ ... }:

{
  # First state version we ship under home-manager. Don't change without
  # reading the home-manager release notes for the new value.
  home.stateVersion = "25.11";
}
