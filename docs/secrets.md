# Secrets

Every secret these dotfiles need is resolved at runtime from **Proton
Pass** via `pass-cli`. Nothing encrypted, nothing committed, no second
secrets tool.

**The rule:** `pass://` *references* may live in this repo; resolved
*values* may never touch git or `/nix/store`.

The store half matters as much as the git half. Everything
home-manager writes lands in `/nix/store`, which is world-readable
`0755` — a secret placed in a `home.file` is a secret handed to every
user and process on the machine. That is why there is no
"`~/.kube/config` as a managed symlink" option, and why the helpers
below write into `$HOME` directly at `0600`.

## When resolution happens

At runtime, in your interactive shell. Never at build or activation
time:

- the Nix build sandbox has no network and no Proton Pass session;
- `darwin-rebuild` activation is non-interactive and runs partly as
  root, so `pass-cli` there hangs on a login prompt or fails outright.

So "declarative" means the **reference and the recipe** are versioned
in the repo; materialising the secret stays an explicit command you
run. This is a real limit, not a temporary one — plan around it rather
than trying to move resolution earlier.

Corollary: **never call these helpers at shell startup.** Each is a
network round trip and would add latency to every new terminal. Call
them inside the function that needs the secret, when it needs it.

## The primitives

`pass-cli` offers four ways in. Three are wrapped by
[`nix/home/secrets.nix`](../nix/home/secrets.nix); the fourth needs no
wrapper.

| Use case | Helper | Wraps |
|---|---|---|
| One value into a shell variable | `pass-get <ref>` | `pass-cli item view` |
| A whole config file | `pass-render <template> <dest>` | `pass-cli inject` |
| Precondition check | `pass-check` | `pass-cli info` |
| Env vars for a child process | *(none — use directly)* | `pass-cli run -- <cmd>` |

### `pass-get`

```zsh
key="$(pass-get 'pass://Ahold/TechNLGenAI/api_key')" || return 1
```

Fails **closed**: on any error nothing reaches stdout and the status
is non-zero, so the `|| return 1` idiom can never proceed with an
empty credential. An empty-but-successful lookup is treated as an
error too.

Fail-closed is load-bearing wherever the fallback would be worse than
stopping — in `cc-work` a missing TechNL proxy URL must abort the
launch, because codemem's work observer would otherwise fall back to
`api.anthropic.com` and send client content there instead of through
the sanctioned proxy.

### `pass-render`

For config files that are mostly public structure with a few secret
values in them. Write a template with `{{ pass://Vault/Item/field }}`
placeholders, commit it, and render it on demand:

```zsh
pass-render ~/.dotfiles/nix/profiles/personal/kube/homelab.yaml.tmpl \
            ~/.kube/config
```

The template syntax is `{{ pass://... }}`. Double angle brackets
(`<<...>>`) pass through untouched — pass-cli does not treat them as
references.

Output is always `0600`. The render goes to a temp file in the
destination directory and is renamed on success, so a failure
(expired session, renamed vault, typo'd ref) leaves an existing
working config untouched rather than truncating it.

This is the preferred shape when the file has reviewable structure:
the layout, names, and non-secret fields stay legible in git, and only
the credential blobs are absent.

### `pass-cli run`

```zsh
pass-cli run --env-file .env -- ./some-script
```

Injects secrets as environment variables into a child process and
masks them in its stdout/stderr. The masking is a good default but can
corrupt legitimate output that happens to contain a secret substring;
`--no-masking` disables it.

## Reference naming

```
pass://<Vault>/<Item>/<field>
```

Vaults and items resolve **by name**, e.g.
`pass://Ahold/TechNLGenAI/api_key`. Conventions:

- one item per system, fields for its individual values — not one
  item per value;
- lowercase `snake_case` field names (`api_key`, `proxy_url`,
  `client_cert`);
- client/work secrets in a vault named for the client; infrastructure
  in `Infra`.

**Hazard:** because refs resolve by name, renaming a vault or item in
the Proton Pass UI silently breaks every reference in this repo, with
a "Could not find vault" error at the point of use. `--share-id` is
stable but unreadable; we accept the readable form and take the
rename risk. If you rename something in Proton Pass, grep this repo
for the old name.

## Per-machine bootstrap

One manual step, and it cannot be automated away — it is the root of
trust:

```bash
pass-cli login
```

Verify with `pass-cli info`. That single login is what replaces
copy-pasting each individual secret onto each new machine.

`pass-cli` itself is declared for every machine as
`protonpass/tap/pass-cli` in `nix/profiles/dev/homebrew.nix`
(the official tap; Homebrew owns updates, and pass-cli's own
`pass-cli update` is disabled under it).

Optionally lock the session at rest with `pass-cli session
create-lock`; `pass-check` reports a locked session the same way it
reports a missing one.

## Where references live today

| Consumer | Reference | Defined in |
|---|---|---|
| `cc-work` (TechNL proxy URL for codemem; the gateway credential itself is held by DevAI CLI) | `pass://Ahold/TechNLGenAI/proxy_url` | [`nix/profiles/work/claude.nix`](../nix/profiles/work/claude.nix) |
| codemem work observer auth | `pass://Ahold/TechNLGenAI/api_key` | [`nix/profiles/work/claude.nix`](../nix/profiles/work/claude.nix) |
| `kube-render` (homelab kubeconfig) | `pass://Infra/k3s/{ca_data,client_cert_data,client_key_data}` | [`nix/profiles/personal/kube.nix`](../nix/profiles/personal/kube.nix) |
| `sealed-secrets-backup` / `sealed-secrets-keys` | `Infra` notes `Sealed Secrets key <name>` (by title, not `pass://`) | [`nix/profiles/personal/kube.nix`](../nix/profiles/personal/kube.nix) |
| `ansible-vault-pass` (Ansible vault password, via `ANSIBLE_VAULT_PASSWORD_FILE`) | `Infra` → `Ansible` → `vault_password` | [`nix/profiles/personal/ansible.nix`](../nix/profiles/personal/ansible.nix) |
| `hass` (hass-cli for Home Assistant) | `Infra` → `Home Assistant` → `url`, `token` | [`nix/profiles/personal/hass.nix`](../nix/profiles/personal/hass.nix) |
| `m2-render` (work Mac's `~/.m2/settings.xml`) | `Ahold` note `Maven settings.xml (backup)` (by title) | [`nix/profiles/work/maven.nix`](../nix/profiles/work/maven.nix) |
| Project `.env` files | `pass://Dev/<Project>/<field>`, resolved by `pass-cli run` | the project (see [below](#project-env-files)) |
| SSH keys (served by `pass-cli ssh-agent`, not read through `pass://`) | vaults `SSH-git`, `SSH-personal`, `SSH-work` | [`nix/home/ssh.nix`](../nix/home/ssh.nix), [docs/ssh.md](ssh.md) |
| Per-client Claude Code profiles | `pass://<Client>/<Channel>/{api_key,proxy_url}` | [client-tooling.md](client-tooling.md) |

The codemem observer entry is a raw `observer_auth_command` array
rather than a `pass-get` call: codemem spawns that command itself and
cannot see zsh functions. Any consumer outside your shell has the same
constraint — give it the bare `pass-cli` invocation.

## Homelab kubeconfig

On a personal Mac this takes care of itself. A launchd agent,
`homelab-secrets` ([`kube.nix`](../nix/profiles/personal/kube.nix)), runs
`kube-render` and then [`sealed-secrets-backup`](#sealed-secrets-keys) at
login and once a day. It's a runtime job in your own session, not
activation, so the rule above holds. Like the SSH agent, it needs
`pass-cli login` and the Keychain fix ([ssh.md](ssh.md#prerequisites-once-per-mac));
until then each run fails and the next one tries again. Log:
`~/Library/Logs/homelab-secrets.log`. To run it now, e.g. right after
`pass-cli login` on a new Mac:

```bash
launchctl kickstart gui/$(id -u)/org.nix-community.home.homelab-secrets
tail ~/Library/Logs/homelab-secrets.log && kubectl get nodes
```

`kube-render` on its own does the same render by hand.

`kube-render` renders
[`nix/profiles/personal/kube/homelab.yaml.tmpl`](../nix/profiles/personal/kube/homelab.yaml.tmpl)
into `~/.kube/config`. It overwrites that file, so keep other clusters
in a second file and add it to `KUBECONFIG`. The template holds the
structure and the API address. The three certificate blobs live in the
custom item `Infra/k3s` as the fields `ca_data`, `client_cert_data` and
`client_key_data`.

**Creating `Infra/k3s`** (once, or after the cluster's certificates
change) from a working kubeconfig, through a pipe so no value lands in
argv or shell history. The source can be a file
(`kubectl config view --raw -o json`) or the note it was saved in:

```bash
pass-cli item view --vault-name Infra --item-title "<kubeconfig note>" --field note \
  | kubectl config view --raw -o json --kubeconfig /dev/stdin \
  | jq -e '.clusters[0].cluster as $c | .users[0].user as $u
      | if ($c["certificate-authority-data"] and $u["client-certificate-data"] and $u["client-key-data"])
        then {title: "k3s", note: "Homelab kubeconfig credentials; template: nix/profiles/personal/kube/",
              sections: [{section_name: "kubeconfig", fields: [
                {field_name: "ca_data", field_type: "hidden", value: $c["certificate-authority-data"]},
                {field_name: "client_cert_data", field_type: "hidden", value: $u["client-certificate-data"]},
                {field_name: "client_key_data", field_type: "hidden", value: $u["client-key-data"]}]}]}
        else error("not a client-certificate kubeconfig") end' \
  | pass-cli item create custom --vault-name Infra --from-template -
```

Check that the old kubeconfig's `server:` matches the template
(`192.168.1.106:6443`, also in Claude's sandbox allowlist in
`nix/profiles/personal/claude.nix`). Then delete `~/.kube/config` and run
`kube-render && kubectl get nodes`. Once that works, the note is no
longer needed.

## Sealed Secrets keys

The Sealed Secrets controller (namespace `sealed-secrets`) holds the
private keys that decrypt every `SealedSecret` in the homelab repo. Lose
them with the cluster and every sealed secret has to be re-created. The
controller adds a new key every 30 days and keeps the old ones, and each
secret only opens with the key it was sealed with, so the backup needs
**all** of them.

They're kept as one `Infra` note per key, `Sealed Secrets key <name>`.
Together they're about 130 KB, more than fits comfortably in one note.
They go from `kubectl` straight into Proton Pass, never to disk.

```bash
sealed-secrets-backup     # saves the keys not in Infra yet
```

The `homelab-secrets` agent runs it daily (see
[above](#homelab-kubeconfig)), so a new key is saved within a day of a
rotation as long as the Mac is home. Each run logs
`N new, M keys in the cluster`. A run away from home fails on `kubectl`
and the next day's run catches up.

**Checking the backup** without touching the cluster: decrypt one sealed
secret with the keys from Proton Pass. This prints only the field names:

```bash
kubectl get sealedsecret -n <ns> <name> -o yaml \
  | kubeseal --recovery-unseal -o json --recovery-private-key <(sealed-secrets-keys) \
  | jq '.data | keys'
```

**Restoring** on a rebuilt cluster: put the keys back before the
controller starts sealing with a fresh one, then restart it so it loads
them:

```bash
sealed-secrets-keys | kubectl apply -f -
kubectl -n sealed-secrets rollout restart deployment/sealed-secrets
```

`sealed-secrets-keys` is all or nothing: it reads and checks every key
note before printing, so a failed read prints nothing (and exits 1)
rather than a partial key set for `kubectl apply`.

## Ansible vault password

`ANSIBLE_VAULT_PASSWORD_FILE` (personal profile) points every
`ansible`, `ansible-playbook` and `ansible-vault` run at
`ansible-vault-pass`, a script that prints the password from the item
`Ansible` in `Infra`, field `vault_password`. Nothing is stored on disk,
and the env var overrides a `vault_password_file` in a repo's
`ansible.cfg`.

Set up once: in Proton Pass, vault `Infra`, create the item `Ansible`
with a field `vault_password` holding the vault password; then delete
the old password file. Check:

```bash
ansible-vault view <encrypted file>   # decrypts with no password file on disk
```

Every Ansible run asks Proton Pass once, so they need a `pass-cli login`;
without one, `ansible-vault-pass` fails and Ansible reports it.

## Home Assistant token

`hass` runs `hass-cli` with `HASS_TOKEN` and `HASS_SERVER` read from
the item `Home Assistant` in `Infra` (fields `token` and `url`, e.g.
`http://<address>:8123`) for that one call. A `HASS_SERVER` already in
the environment wins over the `url` field.

Set up once: in Home Assistant, Profile → Security → Long-lived access
tokens → Create; put it in that item's `token` field, and the URL in
`url`. Check:

```bash
hass info         # server version and location: the token works
hass raw get /api/  # {"message": "API running."}
```

## Project `.env` files

A project's `.env` holds references, never values, and the process gets
the values from `pass-cli run`:

```bash
# .env
STRIPE_SECRET_KEY=pass://Dev/<Project>/stripe_secret_key
DATABASE_URL=pass://Dev/<Project>/database_url
```

```bash
pass-cli run --env-file .env -- npm run dev
```

One item per project in `Dev`, one field per variable (the naming
convention above). `.env` stays globally git-ignored (`nix/home/git.nix`);
since a refs-only file holds nothing secret, a project can also commit it
under another name, e.g. `.env.refs`, and run with `--env-file .env.refs`.
`pass-cli run` masks the values in the command's output; add
`--no-masking` if that garbles legitimate output.

## Maven `settings.xml`

On the work Mac, `~/.m2/settings.xml` is the note `Maven settings.xml
(backup)` in the client vault `Ahold`, verbatim: its registry URLs and
token are client details, so the whole file lives in Proton Pass rather
than as a template here. `m2-render` writes it (mode 0600, through a temp
file, so a failed fetch keeps the old one); the launchd agent `m2-render`
runs it at login and daily, logging to `~/Library/Logs/m2-render.log`.
After a token rotation, update the note; the Mac picks it up within a day,
or at once with `m2-render`.

The vault and title are at the top of `nix/profiles/work/maven.nix`;
renaming the note (dropping "(backup)", say) means changing them there.
Check:

```bash
rm ~/.m2/settings.xml && m2-render
mvn -q dependency:resolve   # in a client project: its packages resolve
```

The personal Mac has no `settings.xml` yet; when it needs one, give the
personal profile the same module pointing at a note in `Dev`.

