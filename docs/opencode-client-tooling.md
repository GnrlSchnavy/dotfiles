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

Two parts: **(A)** an isolated memory lane in these dotfiles, and **(B)** the
private tooling repo. Skip part A if the client needs no extraction isolation
(then just do B and run its repos under `oc-personal`).

Throughout, replace `<client>` (lowercase slug, e.g. `acme`), `<CLIENT>` (env
prefix, e.g. `ACME`), and the channel/pass values. Pick a **unique viewer
port** (personal `4747`, Ahold `4848`, so the next is `4849`).

### A. Add an isolated memory lane

All edits are in [`nix/home/codemem.nix`](../nix/home/codemem.nix), mirroring
the `oc-work` (Ahold) lane.

1. **Add the client's secrets to Proton Pass** (resolved at runtime, never in
   the repo):
   - `pass://<Client>/<Channel>/api_key`
   - `pass://<Client>/<Channel>/proxy_url` — the **base** URL (e.g.
     `https://…/v1`), without `/messages`.

2. **Client OpenCode config** (project-scoped, so `home.file`, outside
   `~/.config`). The proxy URL + key come from env (set by the launcher), so
   neither is in the repo:
   ```nix
   home.file."projects/<client>/opencode.json".text = builtins.toJSON {
     "$schema" = "https://opencode.ai/config.json";
     plugin = [ pluginSpec ];
     mcp = codememMcp;
     # optional overlay (see note below):
     # instructions = [ "${home}/.config/opencode/<client>/*.md" ];
     provider.<client> = {
       npm = "@ai-sdk/anthropic";
       name = "<Client> proxy";
       options = {
         baseURL = "{env:<CLIENT>_PROXY_URL}";
         apiKey = "dummy";
         headers."api-key" = "{env:<CLIENT>_API_KEY}";
       };
       models."claude-sonnet-4-6" = {
         name = "Claude Sonnet 4.6";
         limit = { context = 200000; output = 64000; };
       };
     };
     model = "<client>/claude-sonnet-4-6";
   };
   ```

3. **codemem observer config** — extraction routed through the same channel:
   ```nix
   xdg.configFile."codemem/<client>.json".text = builtins.toJSON {
     observer_runtime = "api_http";
     observer_provider = "anthropic";
     observer_model = "claude-haiku-4-5";
     observer_auth_source = "command";
     observer_auth_command = [ "pass-cli" "item" "view" "pass://<Client>/<Channel>/api_key" ];
     observer_auth_cache_ttl_s = 300;
     observer_headers."api-key" = "\${auth.token}";  # literal ${auth.token}
   };
   ```

4. **Launcher** — append to `programs.zsh.initContent`. Resolves both secrets,
   **fails closed**, and sets the per-lane env:
   ```nix
   oc-<client>() {
     local key proxy
     key="$(pass-cli item view 'pass://<Client>/<Channel>/api_key')"    || { print -u2 "oc-<client>: no api_key";   return 1; }
     proxy="$(pass-cli item view 'pass://<Client>/<Channel>/proxy_url')" || { print -u2 "oc-<client>: no proxy_url"; return 1; }
     CODEMEM_DB="${home}/.codemem/<client>/mem.sqlite" \
     CODEMEM_CONFIG="${home}/.config/codemem/<client>.json" \
     CODEMEM_VIEWER_PORT=<unique-port> \
     CODEMEM_PROJECT=<client> \
     CODEMEM_PLUGIN_LOG="${home}/.codemem/<client>/plugin.log" \
     CODEMEM_ANTHROPIC_ENDPOINT="$proxy/messages" \
     <CLIENT>_API_KEY="$key" \
     <CLIENT>_PROXY_URL="$proxy" \
     ANTHROPIC_API_KEY="$key" \
     OPENCODE_CONFIG="${home}/projects/<client>/opencode.json" \
     opencode "$@"
   }
   ```
   Why `ANTHROPIC_API_KEY` + `CODEMEM_ANTHROPIC_ENDPOINT`: codemem's observer
   targets an Anthropic-shaped endpoint; the endpoint var redirects it to the
   sanctioned proxy (never `api.anthropic.com`) and the key var feeds it the
   client key. See the existing `oc-work` for the worked example.

5. **Per-lane runtime dir** — extend the `home.activation.codememDirs` list:
   ```nix
   run mkdir -p ${home}/.codemem/personal ${home}/.codemem/work-ahold ${home}/.codemem/<client>
   ```

6. `git add` the changed files, then `darwin-rebuild switch`.

7. **Verify isolation before real work**: run `oc-<client>` in a throwaway
   repo, do a little, wait ~2 min for the sweep, then confirm memories were
   created — which proves extraction went through the only configured channel
   (and the launcher fails closed if a secret is missing).

> **Overlay note:** the `instructions` line is optional. A client overlay can
> live as a public folder `system/opencode/<client>/*.md` (client *name* only,
> like Ahold's — no internal architecture), or be dropped entirely and the
> rules kept in the private tooling repo (part B).

### B. Set up the tooling (private repo)

1. Create a **private** tooling repo on the client's infra; `oc-tooling clone
   <client> <url>` (or `link <client> <path>` if already checked out).
2. Populate `repos/<repo>/tree/` with the agents + nested `AGENTS.md`;
   commit + push (mind the [push-auth gotcha](#gotchas) for work accounts).
3. In each client checkout: `oc-tooling apply <client>/<repo>`.

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
