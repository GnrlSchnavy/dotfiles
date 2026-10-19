# SSH on a personal Mac: keys from the Proton Pass vault SSH-personal
# (docs/ssh.md). The public halves live in ./ssh/.
{ ... }:

{
  dotfiles.ssh = {
    vault = "SSH-personal";
    hosts = {
      # GnrlSchnavy
      "github.com".publicKey = ./ssh/github.pub;
      # The NAS, on the LAN.
      "nas 192.168.1.102" = {
        hostName = "192.168.1.102";
        user = "yvan";
        publicKey = ./ssh/nas.pub;
      };
    };
  };
}
