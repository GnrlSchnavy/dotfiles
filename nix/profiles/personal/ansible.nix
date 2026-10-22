# Ansible's vault password, from Proton Pass instead of a file on disk:
# ANSIBLE_VAULT_PASSWORD_FILE points every ansible / ansible-vault /
# ansible-playbook run at a script that prints the password from
# Infra → Ansible → vault_password. Needs a `pass-cli login`
# (docs/secrets.md#ansible-vault-password).
{ osConfig, pkgs, ... }:

let
  passCli = "${osConfig.homebrew.prefix}/bin/pass-cli";

  vaultPass = pkgs.writeShellApplication {
    name = "ansible-vault-pass";
    text = ''
      pw="$(${passCli} item view --vault-name Infra --item-title Ansible --field vault_password)"
      if [ -z "$pw" ]; then
        echo "ansible-vault-pass: Infra/Ansible/vault_password is empty" >&2
        exit 1
      fi
      printf '%s\n' "$pw"
    '';
  };
in
{
  home.packages = [ vaultPass ];
  home.sessionVariables.ANSIBLE_VAULT_PASSWORD_FILE = "${vaultPass}/bin/ansible-vault-pass";
}
