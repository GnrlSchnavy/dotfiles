# SSH on a personal Mac: keys from the Proton Pass vault SSH-personal
# (docs/ssh.md). The public halves live in ./ssh/.
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
  };
in
{
  dotfiles.ssh = {
    vault = "SSH-personal";
    hosts = {
      # GnrlSchnavy
      "github.com".publicKey = ./ssh/github.pub;
      # yvanpersonal
      "gitlab.com".publicKey = ./ssh/gitlab.pub;
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
}
