# SSH on a personal Mac: the GitHub and GitLab keys in the Proton Pass vault
# SSH-git, the homelab key in SSH-personal (docs/ssh.md). Claude's Bash
# sandbox reaches only SSH-git's agent. The public halves live in ./ssh/.
{ lib, ... }:

let
  # Homelab boxes: short name → address and login. One key for all of them
  # (a key identifies this Mac, not the server). `ssh node-1` and
  # `ssh 192.168.1.103` both work.
  homelab = {
    nas-1 = {
      ip = "192.168.1.102";
      user = "yvan";
    };
    node-1 = {
      ip = "192.168.1.103";
      user = "yvan";
    };
    node-2 = {
      ip = "192.168.1.104";
      user = "yvan";
    };
    node-3 = {
      ip = "192.168.1.107";
      user = "yvan";
    };
    node-4 = {
      ip = "192.168.1.105";
      user = "yvan";
    };
    node-5 = {
      ip = "192.168.1.106";
      user = "yvan";
    };
    # Home Assistant OS: the Terminal & SSH add-on logs in as root.
    ha = {
      ip = "192.168.20.18";
      user = "root";
    };
    # Offsite backup box (rest-server, template-flux ansible/offsite/),
    # at another location: reachable only over the tailnet.
    backup-1 = {
      ip = "100.64.0.24";
      user = "yvan";
    };
  };
in
{
  dotfiles.ssh = {
    vault = "SSH-personal";
    gitVault = "SSH-git";
    hosts = {
      # GnrlSchnavy
      "github.com" = {
        publicKey = ./ssh/github.pub;
        git = true;
      };
      # yvanpersonal
      "gitlab.com" = {
        publicKey = ./ssh/gitlab.pub;
        git = true;
      };
    }
    // lib.mapAttrs' (
      name: box:
      lib.nameValuePair "${name} ${box.ip}" {
        hostName = box.ip;
        inherit (box) user;
        publicKey = ./ssh/homelab.pub;
      }
    ) homelab;
  };

  # The GitHub key signs your commits too (nix/home/git.nix): registered on
  # GitHub and, as a signing key, on GitLab (docs/ssh.md#commit-signing).
  dotfiles.git.personalSigningKey = ./ssh/github.pub;
}
