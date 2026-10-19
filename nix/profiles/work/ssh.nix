# SSH on the work Mac: keys from the Proton Pass vault SSH-work
# (docs/ssh.md). The public halves live in ./ssh/.
#
# github.com is the work account; your personal account is reached through
# the github-personal alias, and git sends every GnrlSchnavy repo (these
# dotfiles included) there, so remotes need no editing.
{ ... }:

{
  dotfiles.ssh = {
    vault = "SSH-work";
    hosts = {
      # yvanstemmerik-ah
      "github.com".publicKey = ./ssh/github-work.pub;
      # GnrlSchnavy — its own key, so the work Mac can be revoked alone.
      github-personal = {
        hostName = "github.com";
        user = "git";
        publicKey = ./ssh/github-personal.pub;
      };
    };
  };

  # The longest matching insteadOf wins, so these beat the general
  # https → ssh://git@github.com rule in nix/home/git.nix.
  programs.git.settings.url."ssh://git@github-personal/GnrlSchnavy/".insteadOf = [
    "https://github.com/GnrlSchnavy/"
    "ssh://git@github.com/GnrlSchnavy/"
    "git@github.com:GnrlSchnavy/"
  ];
}
