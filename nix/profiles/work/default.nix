# Profile: work — the client-issued Mac (Ahold): work apps, the work git
# identity, SSH keys from the Proton Pass vault SSH-work, and Claude Code
# through the sanctioned DevAI/TechNL gateway only, with codemem extracting
# through the same gateway. No personal apps, no Claude Max login, no vault.
{
  systemModules = [ ./homebrew.nix ];
  homeModules = [
    ./claude.nix
    ./git.nix
    ./ssh.nix
  ];
}
