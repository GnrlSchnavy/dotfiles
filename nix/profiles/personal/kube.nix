# Homelab k3s secrets from Proton Pass (docs/secrets.md#homelab-kubeconfig):
#
# - kube-render: ~/.kube/config (0600) from ./kube/homelab.yaml.tmpl and the
#   item Infra/k3s.
# - sealed-secrets-backup / sealed-secrets-keys: the Sealed Secrets
#   controller's keys, one Infra note per key, straight from kubectl into
#   Proton Pass and back (docs/secrets.md#sealed-secrets-keys).
#
# A launchd agent runs kube-render and sealed-secrets-backup at login and
# daily, so after `pass-cli login` both keep themselves current. Like the
# SSH agent, it needs the pass-cli Keychain fix (docs/ssh.md).
{
  config,
  osConfig,
  pkgs,
  ...
}:

let
  passCli = "${osConfig.homebrew.prefix}/bin/pass-cli";
  log = "${config.home.homeDirectory}/Library/Logs/homelab-secrets.log";

  # pass-render for scripts (that one is a zsh function): render next to the
  # target and rename on success, so a failed render keeps a working config.
  kubeRender = pkgs.writeShellApplication {
    name = "kube-render";
    text = ''
      mkdir -p "$HOME/.kube"
      tmp="$HOME/.kube/config.render.$$"
      trap 'rm -f "$tmp"' EXIT
      ${passCli} inject --force --file-mode 0600 -i ${./kube/homelab.yaml.tmpl} -o "$tmp" >/dev/null
      mv -f "$tmp" "$HOME/.kube/config"
      echo "kube-render: wrote ~/.kube/config"
    '';
  };

  # Saves every key the controller holds that isn't in Infra yet, as a note
  # "Sealed Secrets key <name>". The controller adds a key every 30 days and
  # keeps the old ones; secrets only open with the key they were sealed with.
  sealedSecretsBackup = pkgs.writeShellApplication {
    name = "sealed-secrets-backup";
    runtimeInputs = [
      pkgs.kubectl
      pkgs.jq
    ];
    text = ''
      have="$(${passCli} item list Infra --filter-state active)"
      names="$(kubectl get secret -n sealed-secrets \
        -l sealedsecrets.bitnami.com/sealed-secrets-key -o name)"
      if [ -z "$names" ]; then
        echo "sealed-secrets-backup: the cluster has no Sealed Secrets keys" >&2
        exit 1
      fi
      total=0 saved=0
      for name in $names; do
        name="''${name#secret/}"
        total=$((total + 1))
        grep -qF ": Sealed Secrets key $name (state=" <<<"$have" && continue
        kubectl get secret -n sealed-secrets "$name" -o json \
          | jq -e --arg t "Sealed Secrets key $name" '{title: $t, note: ({apiVersion, kind, type,
              metadata: {name: .metadata.name, namespace: .metadata.namespace, labels: .metadata.labels},
              data} | tojson)}' \
          | ${passCli} item create note --vault-name Infra --from-template - >/dev/null
        echo "sealed-secrets-backup: saved $name"
        saved=$((saved + 1))
      done
      echo "sealed-secrets-backup: $saved new, $total keys in the cluster"
    '';
  };

  # Every backed-up key as one kubectl List on stdout, for a restore
  # (`| kubectl apply -f -`) or kubeseal --recovery-private-key.
  sealedSecretsKeys = pkgs.writeShellApplication {
    name = "sealed-secrets-keys";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      titles="$(${passCli} item list Infra --filter-state active \
        | sed -n 's/^- \[[^]]*\]: \(Sealed Secrets key .*\) (state=.*$/\1/p')"
      if [ -z "$titles" ]; then
        echo "sealed-secrets-keys: no Sealed Secrets keys in Infra" >&2
        exit 1
      fi
      while IFS= read -r t; do
        ${passCli} item view --vault-name Infra --item-title "$t" --field note
      done <<<"$titles" | jq -s '{apiVersion: "v1", kind: "List", items: .}'
    '';
  };

  sync = pkgs.writeShellApplication {
    name = "homelab-secrets-sync";
    runtimeInputs = [
      kubeRender
      sealedSecretsBackup
    ];
    text = ''
      echo "== $(date '+%F %T')"
      kube-render
      sealed-secrets-backup
    '';
  };
in
{
  home.packages = [
    kubeRender
    sealedSecretsBackup
    sealedSecretsKeys
  ];

  # Fails (and retries the next day) while pass-cli isn't logged in or the
  # cluster is out of reach; the log says which.
  launchd.agents.homelab-secrets = {
    enable = true;
    config = {
      ProgramArguments = [ "${sync}/bin/homelab-secrets-sync" ];
      RunAtLoad = true;
      StartInterval = 86400;
      StandardOutPath = log;
      StandardErrorPath = log;
    };
  };
}
