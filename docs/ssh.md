# SSH keys (Proton Pass)

Private SSH keys live **only in Proton Pass** — never as files in
`~/.ssh`. On each Mac, `pass-cli ssh-agent` serves the keys of that
Mac's vault on a fixed socket, `~/.ssh/proton-pass-agent.sock`, and
`~/.ssh/config` (written by home-manager) sends each host to that agent
with the right key.

| Vault | Used by (profile) | Key (item title) | For |
|---|---|---|---|
| `SSH-personal` | `personal` (m5) | `GitHub personal` | GitHub `GnrlSchnavy` |
| | | `GitLab personal` | GitLab `yvanpersonal` |
| | | `Homelab` | `nas-1`, `node-1` … `node-5`, `ha` (Home Assistant) |
| `SSH-work` | `work` (the client Mac) | `GitHub work` | GitHub `yvanstemmerik-ah` (`github.com`) |
| | | `GitHub personal (work Mac)` | GitHub `GnrlSchnavy` (`github-personal`) |

Why it's split like this:

- **One vault per profile:** each Mac's agent only sees its own vault, so
  the NAS key never reaches the client Mac and the work key never reaches
  m5.
- **One key per account per Mac:** the work Mac has its own key for your
  personal GitHub account, so you can revoke that Mac alone (GitHub →
  Settings → SSH keys) without touching m5.
- **One key for the whole homelab:** a key identifies the *client* (this
  Mac), not the server, and every homelab box is reached from the same
  Mac through the same agent — separate keys per server would add work,
  not protection.

## How it's wired

| Piece | Where |
|---|---|
| The agent (launchd, at login) and `~/.ssh/config` | [`nix/home/ssh.nix`](../nix/home/ssh.nix) — shared plumbing, no keys |
| Vault, hosts and public keys, per profile | `nix/profiles/{personal,work}/ssh.nix` and `…/ssh/*.pub` |
| Claude Code's sandbox pushing through the same agent | [`nix/profiles/personal/sandbox-git.nix`](../nix/profiles/personal/sandbox-git.nix) |
| Work Mac: every `GnrlSchnavy` repo (these dotfiles too) goes via `github-personal` | [`nix/profiles/work/ssh.nix`](../nix/profiles/work/ssh.nix) |
| Commit signing with the same keys | [`nix/home/git.nix`](../nix/home/git.nix) ([below](#commit-signing)) |

The repo holds only **public** keys: ssh needs the public half to pick
the matching private key from the agent (`IdentitiesOnly yes`, so it
never offers a key from the wrong account). Hosts that aren't declared
can go in `~/.ssh/config.local`, which `~/.ssh/config` includes.

## Prerequisites (once per Mac)

1. **A paid Proton Pass plan** other than Essentials — Family qualifies.
2. **`pass-cli login`** — the agent runs as you and uses that session.
3. **Let every `pass-cli` version read its Keychain item.** `pass-cli`
   keeps its session in the login Keychain, and each Homebrew upgrade
   (every rebuild may upgrade it) re-triggers a Keychain prompt — which a
   background agent can't answer, so SSH would stop working after an
   upgrade. Fix it once:
   1. Open **Keychain Access** (`open -a "Keychain Access"`).
   2. Select the **login** keychain, search for **ProtonPassCLI**.
   3. Double-click the item → **Access Control** tab.
   4. Choose **Allow all applications to access this item** → **Save
      Changes** (asks your password).

   This stays limited to software signed by Proton: the item's partition
   list only admits Proton's team ID.

## Creating the keys (once, from any Mac signed in to `pass-cli`)

Vaults and keys belong to your Proton account, so you can create the
work Mac's keys from m5 too.

```bash
pass-cli vault create --name SSH-personal
pass-cli vault create --name SSH-work

# New keys, generated inside Proton Pass. No passphrase: the vault
# already encrypts them.
pass-cli item create ssh-key generate --vault-name SSH-personal \
  --title "GitHub personal"
pass-cli item create ssh-key generate --vault-name SSH-personal \
  --title "GitLab personal"
pass-cli item create ssh-key generate --vault-name SSH-personal \
  --title "Homelab"
pass-cli item create ssh-key generate --vault-name SSH-work \
  --title "GitHub work"
pass-cli item create ssh-key generate --vault-name SSH-work \
  --title "GitHub personal (work Mac)"
```

To bring an existing key along instead of generating a new one:
`pass-cli item create ssh-key import --vault-name … --title … --from-private-key <file>`.

## Putting the public keys in the repo

Print each vault's public keys (only public keys — safe to copy) with a
temporary agent:

```bash
for v in SSH-personal SSH-work; do
  sock="$TMPDIR/pp-$v.sock"
  pass-cli ssh-agent start --vault-name "$v" --socket-path "$sock" >/dev/null 2>&1 &
  sleep 5
  echo "== $v"
  SSH_AUTH_SOCK="$sock" ssh-add -L
  kill $!
done
```

Each line is `ssh-ed25519 AAAA… <item title>` (pass-cli uses the item
title as the comment). Save each to its file and commit:

| Item title | File |
|---|---|
| `GitHub personal` | `nix/profiles/personal/ssh/github.pub` |
| `GitLab personal` | `nix/profiles/personal/ssh/gitlab.pub` |
| `Homelab` | `nix/profiles/personal/ssh/homelab.pub` |
| `GitHub work` | `nix/profiles/work/ssh/github-work.pub` |
| `GitHub personal (work Mac)` | `nix/profiles/work/ssh/github-personal.pub` |

## Registering the public keys

- **GitHub `GnrlSchnavy`** → Settings → SSH and GPG keys → New SSH key:
  `personal/ssh/github.pub` (title "m5") and
  `work/ssh/github-personal.pub` (title "work Mac").
- **GitHub `yvanstemmerik-ah`** → same place: `work/ssh/github-work.pub`,
  then **Configure SSO** next to it and authorize the client's
  organization.
- **GitLab `yvanpersonal`** → Preferences → SSH Keys → Add new key:
  `personal/ssh/gitlab.pub`.
- **Homelab boxes** (NAS, nodes): while your old access still works
  (password or old key), copy the key onto each box:
  `ssh-copy-id -f -i ~/.dotfiles/nix/profiles/personal/ssh/homelab.pub <user>@<host>`.
  `-f` is needed because the private half isn't on disk (ssh-copy-id
  otherwise refuses); it also skips the already-installed check, so run
  it once per box.
- **Home Assistant OS:** in the **Terminal & SSH** add-on → Configuration
  → `authorized_keys`, add the contents of `homelab.pub` and restart the
  add-on. (Home Assistant on a regular Linux: `ssh-copy-id` like the
  nodes.)

## Applying and checking

```bash
cd ~/.dotfiles && git pull
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#${DOTFILES_HOST:-$(scutil --get LocalHostName)} -v
```

Then:

```bash
SSH_AUTH_SOCK=~/.ssh/proton-pass-agent.sock ssh-add -l   # the vault's keys
ssh -T git@github.com              # m5: "Hi GnrlSchnavy!"   work Mac: "Hi yvanstemmerik-ah!"
ssh -T git@github-personal         # work Mac only: "Hi GnrlSchnavy!"
ssh nas-1 true                     # m5 only; likewise node-1 … node-5 and ha
ssh -T git@gitlab.com              # m5: "Welcome to GitLab, @yvanpersonal!"
```

The first rebuild replaces a hand-written `~/.ssh/config` with the
managed one (the old file is kept as `~/.ssh/config.hm-backup`); move
any host you still need into `~/.ssh/config.local`.

## Removing the old key files

Only after every check above passes:

```bash
rm ~/.ssh/github_ed25519* ~/.ssh/github_ahold_ed25519* ~/.ssh/nas_ed25519* ~/.ssh/gitlab*
```

and delete the old keys from the GitHub and GitLab SSH key lists and
from the homelab boxes' `~/.ssh/authorized_keys`.

## A new Mac

Nothing to create: `pass-cli login`, the Keychain fix (prerequisite 3),
rebuild. The agent serves the profile's vault and `~/.ssh/config` is
already right.

## Adding or rotating a key

1. Generate it into the profile's vault (`pass-cli item create ssh-key
   generate --vault-name … --title …`).
2. Save its public half under `nix/profiles/<profile>/ssh/` and add a
   host to that profile's `ssh.nix`.
3. Register the public key with the service; rebuild.
4. Rotating: then delete the old item in Proton Pass and the old public
   key from the service.

## Commit signing

Git signs every commit and annotated tag with an SSH key from the same
agent. There's no extra key to create: each identity signs with its own
GitHub key on that Mac.

| Mac | Identity | Signs with | Registered as a signing key on |
|---|---|---|---|
| m5 | personal (everything) | `personal/ssh/github.pub` | GitHub `GnrlSchnavy`, GitLab |
| work Mac | work (the default) | `work/ssh/github-work.pub` | GitHub `yvanstemmerik-ah` |
| work Mac | personal (the dotfiles clones) | `work/ssh/github-personal.pub` | GitHub `GnrlSchnavy` |

Wiring: [`nix/home/git.nix`](../nix/home/git.nix) turns signing on once
the profile sets `dotfiles.git.personalSigningKey`. The work profile
also sets the work key ([`nix/profiles/work/git.nix`](../nix/profiles/work/git.nix)).
Git runs `ssh-keygen` through a small wrapper that points it at the
Proton Pass agent: `SSH_AUTH_SOCK` itself stays on macOS's agent, in the
shell and in apps like IntelliJ. `~/.config/git/allowed_signers` lists
this Mac's keys, so signatures also verify locally.

**Register each key a second time, as a signing key.** An SSH key only
counts for signatures once it's added with that type. That holds even
when the same key is already there for authentication:

- **GitHub** (each account) → Settings → SSH and GPG keys → New SSH key
  → Key type **Signing Key**, the same `.pub` file as in the table.
- **GitLab** → Preferences → SSH Keys → Add new key: the contents of
  `personal/ssh/github.pub`, Usage type **Signing**. GitLab commits from
  m5 are signed with the GitHub key, so there's one signing key to manage.

GitHub and GitLab only show **Verified** when the commit email is a
verified address on that account (`yvanstemmerik@gmail.com` on the
personal accounts, the client address on `yvanstemmerik-ah`).

Check, after a rebuild:

```bash
git commit --allow-empty -m "signing test" && git log --show-signature -1
# Good "git" signature for yvanstemmerik@gmail.com with ED25519 key SHA256:…
```

Push it to a scratch branch and check for **Verified** on the commit, then
delete the branch.

## Troubleshooting

| Symptom | Check |
|---|---|
| `Permission denied (publickey)` | Is the agent up? `SSH_AUTH_SOCK=~/.ssh/proton-pass-agent.sock ssh-add -l`. If not: `tail ~/Library/Logs/proton-pass-ssh-agent.log` |
| Log says not logged in / no session | `pass-cli login`, then `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.proton-pass-ssh-agent` |
| It broke right after a rebuild | A `pass-cli` upgrade hit the Keychain prompt: redo prerequisite 3 |
| The agent lists no keys | Wrong vault name, or a key Proton can't use: `pass-cli ssh-agent debug --vault-name SSH-personal` |
| GitHub greets the wrong account | The host's public key file doesn't match the key in the vault |
| `git commit` fails: `Couldn't sign` / `agent refused operation` | The agent is down or doesn't hold the signing key: check it as above. To commit anyway, once: `git -c commit.gpgsign=false commit …` |
| GitHub shows **Unverified** | The key isn't added as a *Signing Key*, or the commit email isn't verified on that account |
