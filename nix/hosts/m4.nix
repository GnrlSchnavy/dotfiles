{ pkgs, config, inputs, ... }:

{
  # Host-specific configuration for m4
  # Modules are imported at the flake level

  # Allow 'paid' applications to be set in flake config
  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system
  nix.settings.experimental-features = "nix-command flakes";

  # Set Git commit hash for darwin-version
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  
  # Used for backwards compatibility, please read the changelog before changing
  system.stateVersion = 5;
  
  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";
}