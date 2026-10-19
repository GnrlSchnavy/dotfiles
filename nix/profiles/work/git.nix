# Work git identity — the default on the work machine. The dotfiles clones
# still commit as personal (nix/home/git.nix). SSH keys: ./ssh.nix.
#
# Each identity signs with its own GitHub key (docs/ssh.md#commit-signing):
# work commits with the work key, the dotfiles with the personal one.
{ ... }:

let
  email = "yvan.stemmerik@ah.nl";
in
{
  programs.git = {
    settings = {
      user = {
        name = "yvanstemmerik-ah";
        inherit email;
      };
      credential."https://github.com".username = "yvanstemmerik-ah";
    };
    signing.key = "${./ssh/github-work.pub}";
  };

  dotfiles.git = {
    personalSigningKey = ./ssh/github-personal.pub;
    allowedSigners.${email} = ./ssh/github-work.pub;
  };
}
