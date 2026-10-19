# Work git identity — the default on the work machine. The dotfiles clones
# still commit as personal (nix/home/git.nix). Which SSH key github.com uses
# is up to ~/.ssh/config on the machine (unmanaged).
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
