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
- [ ] m5: factory reset → `DOTFILES_HOST=m5 ./setup.sh` → `pass-cli login`, Keychain fix, agent kickstart (`docs/operations.md`, "Reinstalling a Mac")
- [ ] work Mac: `pass-cli login`, Keychain fix, `GIT_CONFIG_GLOBAL=/dev/null git pull`, rebuild `#work`
- **Done when:** `ssh -T git@github.com` / `git@gitlab.com` / `git@github-personal` greet the right accounts, `ssh <box> true` works for all seven boxes, and Claude's sandbox can `git push`
- [ ] Old key files deleted, old keys removed from GitHub/GitLab/boxes
- Later: the nodes still accept password logins — switch that off once item 3 (break-glass) works

## 2. Git commit signing (SSH)

Reuses each account's SSH key (GitHub/GitLab accept one key for both).
`git.nix`: `gpg.format = ssh`, `commit.gpgsign`, `user.signingkey` per
identity (dotfiles clones → personal key), `gpg.ssh.allowedSignersFile`.

- **Done when:** `git log --show-signature -1` verifies locally and GitHub/GitLab show **Verified**, on both Macs

## 3. Break-glass access to the homelab

An offline emergency key outside Proton Pass: generated once with a
strong passphrase, private half on a USB stick (plus a paper copy) kept
in a safe place, public half in every box's `authorized_keys`. Plus: a
working physical console on each box.

- **Done when:** with the Proton agent stopped, `ssh -i /Volumes/<usb>/breakglass nas-1 true` works

## 4. Sealed Secrets master key backup

Controller key → `Infra` vault, straight from `kubectl` (never on disk).

- **Done when:** the item exists and a dry-run restore (`kubeseal --recovery-unseal`) decrypts a sealed secret with it

## 5. k3s kubeconfig as a template

Template in the repo with `{{ pass://Infra/k3s/... }}` refs; a
`kube-render` function writes `~/.kube/config` (0600).

- **Done when:** after deleting `~/.kube/config`, `kube-render && kubectl get nodes` works

## 6. Ansible vault password

`Infra/Ansible/vault_password`; a script for `vault_password_file`.

- **Done when:** `ansible-vault view <file>` works with no password file on disk

## 7. Tailscale auth keys, Flux/GitHub deploy tokens

Stored as items in `Infra`; referenced from wherever they're used.

- **Done when:** each is in Proton Pass and removed from shell history / loose files

## 8. Home Assistant long-lived token

`Infra/Home Assistant/token`; `hass-cli` (or curl) gets it per call.

- **Done when:** a call to the HA API with the token from Proton Pass returns `200`

## 9. `.env` files with references

Project `.env` files hold `pass://Dev/...` refs; run with
`pass-cli run --env-file .env -- <cmd>`.

- **Done when:** one project starts with a refs-only `.env`

## 10. Cloudflare / wrangler and Stripe CLI

Wrappers that pass `CLOUDFLARE_API_TOKEN` / `STRIPE_API_KEY` from `Dev`
per call; their stored logins removed.

- **Done when:** `wrangler whoami` and `stripe config --list` work after `wrangler logout` / removing Stripe's stored key
