# OpenCode client tooling

How per-client OpenCode tooling (custom subagents + repo-specific
`AGENTS.md` rules) is stored, versioned, and loaded — **without putting any
client-confidential content into these public dotfiles**.

See also: [OpenCode instructions & agents](claude-code.md#opencode-instructions--agents)
(the *global*, client-free agent layer) and
[OpenCode & two-lane codemem memory](claude-code.md#opencode--two-lane-codemem-memory)
(separated memory per lane).

## The split: mechanism vs content

Client agents and rules embed client identifiers (package namespaces,
service/domain names, ticket prefixes), so they must **not** live in these
public dotfiles. But they still need to be durable (survive a repo re-clone
or OS reinstall) and reusable across machines.

The rule: **the mechanism lives here; the content lives in a private
per-client repo.**

| Layer | Lives in | Client content? | Survives reinstall via |
|---|---|---|---|
| Generic agents + baseline `AGENTS.md` | `system/opencode/` (these dotfiles) | no | `darwin-rebuild switch` |
| `oc-tooling` helper | `system/opencode/bin/oc-tooling.sh` (these dotfiles) | no | `darwin-rebuild switch` |
| Per-client agents + repo `AGENTS.md` | **private repo, one per client** | yes | re-clone the private repo |
| Local checkout of that private repo | `~/.opencode-clients/<client>/` | yes (local only) | re-clone |

## Separated memory (one lane per context)

Each working context is an isolated **codemem lane** — see
[OpenCode & two-lane codemem memory](claude-code.md#opencode--two-lane-codemem-memory).
Today: `oc-personal` (Max) and `oc-work` (Ahold, via the TechNL proxy), each
with its own DB folder, observer config, and viewer port. A new client gets
its **own lane** (add an `oc-<client>` function + observer config in
[`nix/home/codemem.nix`](../nix/home/codemem.nix), mirroring `oc-work`) plus
its **own private tooling repo** (below).

## How client tooling is stored (the private repo)

One private repo per client (on the client's own GitLab/GitHub), cloned or
linked under `~/.opencode-clients/<client>/`. It mirrors each target checkout
under a `tree/`:

    <client>/
      repos/<repo>/tree/...   # mirrors that client repo; symlinked into the checkout
      shared/tree/...         # (optional) applied to every repo of that client

Every file under a `tree/` maps to the same relative path in the live
checkout — the directory layout *is* the manifest. A `tree/` typically holds
`.opencode/agent/*.md` (project subagents), nested `AGENTS.md` files
(per-package rules), and an optional repo-root `opencode.json`.

## How it's loaded into a checkout (`oc-tooling`)

[`oc-tooling`](../system/opencode/bin/oc-tooling.sh) — a client-agnostic
helper shipped via [`nix/home/opencode.nix`](../nix/home/opencode.nix) —
materializes a client's `tree/` into a checkout:

| Command | What it does |
|---|---|
| `oc-tooling clone <client> <url>` | clone the private repo to `~/.opencode-clients/<client>/` |
| `oc-tooling link <client> <path>` | symlink `~/.opencode-clients/<client>` → an existing checkout of it |
| `oc-tooling apply <client>/<repo>` | symlink `tree/` files into the current checkout + write a marked `.git/info/exclude` block |
| `oc-tooling status` | show what's applied in the current checkout |
| `oc-tooling unapply` | remove the symlinks + the exclude block |
| `oc-tooling list` | list set-up clients and their repos |

`apply` **symlinks** the files in (single source of truth — edit the private
repo once, every checkout updates) and adds their paths to `.git/info/exclude`
inside a marked, removable block. So:

- OpenCode discovers them like any project tooling (`.opencode/agent/` glob +
  the `AGENTS.md` up-walk) and follows the symlinks.
- git never sees them — they are **not** committed to the client repo and
  **not** added to its shared `.gitignore`.

`$OC_TOOLING_HOME` (default `~/.opencode-clients`) overrides the base dir.

## Runbook — onboard a new client

1. Create a **private** tooling repo on the client's infra.
2. *(Optional, for separated memory)* add an `oc-<client>` lane in
   [`nix/home/codemem.nix`](../nix/home/codemem.nix) mirroring `oc-work`, then
   `darwin-rebuild switch`.
3. `oc-tooling clone <client> <url>` (or `link <client> <path>` if already
   checked out).
4. Populate `repos/<repo>/tree/` with the agents + `AGENTS.md`; commit + push.
5. In each client checkout: `oc-tooling apply <client>/<repo>`.

## Runbook — restore after re-clone / OS reinstall

1. `darwin-rebuild switch` → the dotfiles + `oc-tooling` are back.
2. `oc-tooling clone <client> <url>` for each active client.
3. `oc-tooling apply <client>/<repo>` in each checkout.

## Switching clients

### Offboard a client

1. In each of that client's checkouts: `oc-tooling unapply` — removes the
   symlinks and the managed `.git/info/exclude` block, leaving the checkout
   clean.
2. Drop the local clone/link: `rm ~/.opencode-clients/<client>` (a `link` is
   just a symlink; a `clone` is safe to `rm -rf` since it's pushed).
3. *(If the client had a memory lane)* remove its `oc-<client>` function +
   observer config from [`nix/home/codemem.nix`](../nix/home/codemem.nix) and
   `darwin-rebuild switch`. Then handle the lane's memory DB at
   `~/.codemem/<client>/`:
   - **Delete it** (`rm -rf ~/.codemem/<client>`) if offboarding requires
     removing client-derived data — usually the right call.
   - Keep it only if you have a specific reason.
4. The private tooling repo stays on the client's infra (archive it there if
   you like). Nothing about the client remains in these public dotfiles.

### Onboard the new client

Follow [Onboard a new client](#runbook--onboard-a-new-client). The only
client-specific judgement is the **memory lane**:

- **No isolation needed** (extraction may go through your normal path) → skip
  the lane; use the tooling and run the client's repos under `oc-personal`.
- **Sanctioned-channel isolation needed** (like Ahold's TechNL) → add an
  `oc-<client>` lane in [`nix/home/codemem.nix`](../nix/home/codemem.nix)
  mirroring `oc-work`: its own DB folder, observer config, and viewer port,
  with its own extraction channel (proxy URL + key resolved from `pass-cli`,
  **fail-closed**). Never reuse another client's lane, channel, or DB.

## Gotchas

- **Subagents aren't in the Tab switcher.** `mode: subagent` agents are
  invoked by the primary agent or via `@name`, and appear under `@` /
  `/agents` — not the agent switcher. Use `mode: all` to also list one in the
  switcher.
- **`instructions` arrays concatenate.** A repo-root `opencode.json`'s
  `instructions` stack *on top of* the lane's overlay (e.g. the Ahold
  isolation rule) rather than replacing it — verified live.
- **Pushing the private repo.** git uses the `osxkeychain` helper (your
  personal account), so pushing to a *work-account* private repo needs that
  account's credentials: either run `gh auth setup-git` once, or a one-off
  `git -c credential.helper= -c credential.helper='!gh auth git-credential' push`.
- **`unapply` leaves empty dirs** (e.g. an empty `.opencode/agent/`) —
  harmless; re-apply repopulates them.
- The client *name* (e.g. `ahold`) appears here as an example; the client's
  internal architecture lives only in the private repo — never in these
  dotfiles.
