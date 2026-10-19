# Everything secret through Proton Pass

One item at a time; each is verified before the next starts. Branch per
item, merged when its check passes. Runbooks land in `docs/` as we go.

## Resume here (2026-10-19, before m5's factory reset)

The chat that started this lives on m5 and is erased with it; this file
is the hand-off. State:

- **Machines:** m5 = personal (`dev` + `personal`), about to be
  factory-reset and reinstalled from master. The client Mac = host
  `work` (user `pnl1ln25`, selected with `DOTFILES_HOST=work`, since its
  hostname is managed by the client), installed and in use.
- **Done today:** profile split (dev/personal/work), work host, Colima
  instead of Docker Desktop, CLI tools from nixpkgs, CI checks for
  disabled casks and doc drift, Alfred on Cmd-Space, Proton Pass /
  Spotify / Wispr Flow on both Macs, SSH keys in Proton Pass (item 1,
  merged).
- **Pre-reset backups** (m5): see `docs/operations.md` "Reinstalling a
  Mac"; the kubeconfig and Maven `settings.xml` go into vault `Infra`
  as notes.
- **Next:** finish item 1's checks on both Macs, then item 2.

Vaults (by profile, per `docs/secrets.md` conventions):

| Vault | Holds | Reaches |
|---|---|---|
| `SSH-personal` | SSH keys: GitHub, GitLab, Homelab | m5 (SSH agent) |
| `SSH-work` | SSH keys: GitHub work, GitHub personal (work Mac) | work Mac (SSH agent) |
| `Infra` | homelab secrets: k3s, Sealed Secrets, Ansible, Tailscale, Flux, Home Assistant | m5, on demand |
| `Dev` | dev tokens: Cloudflare, Stripe, project `.env` values | m5, on demand |
| `Ahold` | TechNL (existing) | work Mac |

## 1. SSH keys from Proton Pass — in progress

Merged (PR #14, `4bb8d50`); runbook `docs/ssh.md`.

- [x] Keychain fix for `pass-cli` on m5 (redo after the reset)
- [x] Vaults `SSH-personal`, `SSH-work`
- [x] Keys: GitHub personal, GitLab personal, Homelab, GitHub work, GitHub personal (work Mac)
- [x] Public keys committed; merged
- [x] Registered: GitHub ×2 accounts, GitLab, `ssh-copy-id -f` to nas-1 and node-1…5, HA add-on `authorized_keys`
- [x] m5: factory reset → `DOTFILES_HOST=m5 ./setup.sh` → `pass-cli login`, Keychain fix, agent kickstart (`docs/operations.md`, "Reinstalling a Mac")
- [x] m5 checks: GitHub, GitLab, nas-1, node-1…5 and the sandbox `git push` work
- [ ] m5 → `ha` (192.168.20.18): no route yet — it's on the other network (`192.168.20.x`), not reachable from the main LAN; sort out the routing/firewall between the two, then `ssh ha true`
- [ ] work Mac: `pass-cli login`, Keychain fix, `GIT_CONFIG_GLOBAL=/dev/null git pull`, rebuild `#work`
- **Done when:** `ssh -T git@github.com` / `git@gitlab.com` / `git@github-personal` greet the right accounts, `ssh <box> true` works for all seven boxes, and Claude's sandbox can `git push`
- [ ] Old key files deleted, old keys removed from GitHub/GitLab/boxes
- Later: the nodes still accept password logins — switch that off once item 3 (break-glass) works

## 2. Git commit signing (SSH) — in progress

Each identity signs with its GitHub key on that Mac; on m5 the same key is
also GitLab's signing key, so no per-remote key choice. `nix/home/git.nix`
(`dotfiles.git.personalSigningKey`, an `ssh-keygen` wrapper pointed at the
Proton agent, `allowed_signers`); runbook `docs/ssh.md#commit-signing`.

- [x] Config: personal profile → `github.pub`; work → `github-work.pub`, dotfiles clones `github-personal.pub`
- [x] Proton agent signs (`ssh-keygen -Y sign`), also from Claude's sandbox
- [ ] m5: rebuild; add `github.pub` as **Signing Key** on GitHub `GnrlSchnavy` and as **Signing** on GitLab
- [ ] work Mac: rebuild `#work`; add `github-work.pub` / `github-personal.pub` as Signing Keys on their accounts
- **Done when:** `git log --show-signature -1` verifies locally and GitHub/GitLab show **Verified**, on both Macs

## 3. Break-glass access to the homelab

An offline emergency key outside Proton Pass: generated once with a
strong passphrase, private half on a USB stick (plus a paper copy) kept
in a safe place, public half in every box's `authorized_keys`. Plus: a
working physical console on each box.

- **Done when:** with the Proton agent stopped, `ssh -i /Volumes/<usb>/breakglass nas-1 true` works

## 4. Sealed Secrets master key backup — done

19 keys in namespace `sealed-secrets` (30-day rotation, all kept), ~130 KB
together, so one `Infra` note per key: `sealed-secrets-backup` (adds the
missing ones; re-run after rotations), `sealed-secrets-keys` (all as a
kubectl List, for restore or `kubeseal --recovery-private-key`). In
`nix/profiles/personal/kube.nix`; runbook `docs/secrets.md#sealed-secrets-keys`.
The backup format was checked against the live cluster: it decrypts
`familyhub-acc/family-hub-db-credentials`.

- [x] Scripts, launchd agent `homelab-secrets` (login + daily: `kube-render`, `sealed-secrets-backup`), docs
- [x] Agent's first run (2026-10-19): `19 new, 19 keys in the cluster`; the dry-run restore from Proton Pass decrypts `familyhub-acc/family-hub-db-credentials`
- **Done when:** the notes exist and the dry-run restore in the runbook (`<(sealed-secrets-keys)`) decrypts a sealed secret
- The agent reaches `192.168.1.106` fine (no Local Network privacy block)

## 5. k3s kubeconfig as a template — done

Template `nix/profiles/personal/kube/homelab.yaml.tmpl` (API address
inline, it's already public in `claude.nix`), custom item `Infra/k3s`
with `ca_data`, `client_cert_data`, `client_key_data`; `kube-render`
(`nix/profiles/personal/kube.nix`). Runbook `docs/secrets.md#homelab-kubeconfig`.
Done before item 4: `kubectl` needs it.

- [x] Template, `kube-render` (also run by the `homelab-secrets` agent), docs (`secrets.md`, `operations.md`, `profiles.md`)
- [x] `Infra/k3s` created; `kube-render && kubectl get nodes` works, also from the agent
- **Done when:** after deleting `~/.kube/config`, `kube-render && kubectl get nodes` works
- [ ] Delete the old `k3s kubeconfig` note (and the trashed backup) in Proton Pass

## 6. Ansible vault password

`Infra/Ansible/vault_password`; a script for `vault_password_file`.

- **Done when:** `ansible-vault view <file>` works with no password file on disk

## 7. Tailscale auth keys, Flux/GitHub deploy tokens — done (nothing to move)

Checked 2026-10-19: Flux's deploy key (`flux-system/flux-system`),
`flux-system/gitlab-preview-readonly`, and Headscale's
`tailscale-authkey-routers` and `headscale-oidc-client` are all
SealedSecrets in `GnrlSchnavy/template-flux`, so the repo plus item 4's
key backup restores them. The factory reset cleared shell history and
loose files. Re-bootstrapping Flux creates a new deploy key from a
one-off GitHub token, so there's nothing to store ahead of time.

## 8. Home Assistant long-lived token

`Infra/Home Assistant/token`; `hass-cli` (or curl) gets it per call.

- **Done when:** a call to the HA API with the token from Proton Pass returns `200`

## 9. `.env` files with references

Project `.env` files hold `pass://Dev/...` refs; run with
`pass-cli run --env-file .env -- <cmd>`.

- **Done when:** one project starts with a refs-only `.env`

## 10. Cloudflare / wrangler and Stripe CLI — dropped

Dropped 2026-10-19: not worth it. wrangler and the Stripe CLI keep their
own logins.

## 11. Maven `settings.xml` as a template per profile

`settings.xml` holds one `<server>` per registry. A template per profile,
rendered with `pass-render`: work → the client's GitHub Packages token
(client vault; today a verbatim backup, `Maven settings.xml (backup)`);
personal → its own entries from `Dev`; a new client → its own vault and
entry. m5 doesn't get the client token back after its reset.

- **Done when:** on the work Mac, removing `~/.m2/settings.xml`, rendering it, and resolving a client project's dependencies works
