# Profile: personal — a personal Mac: personal apps, the application
# firewall, SSH keys from the Proton Pass vaults SSH-git and SSH-personal,
# Claude Code on the Claude Max login (sandboxed, pushing through the git-only
# SSH agent), codemem via Max, and the Obsidian vault skills. Git uses the
# personal identity (the default in nix/home/git.nix).
{
  systemModules = [
    ./homebrew.nix
    ./packages.nix
    ./firewall.nix
  ];
  homeModules = [
    ./claude.nix
    ./ssh.nix
    ./sandbox-git.nix
    ./kube.nix
    ./ansible.nix
    ./hass.nix
    ./vault.nix
  ];
}
