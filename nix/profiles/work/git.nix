# Work git identity — the default on the work machine. The dotfiles clones
# still commit as personal (nix/home/git.nix). SSH keys: ./ssh.nix.
{ ... }:

{
  programs.git.settings = {
    user = {
      name = "yvanstemmerik-ah";
      email = "yvan.stemmerik@ah.nl";
    };
    credential."https://github.com".username = "yvanstemmerik-ah";
  };
}
