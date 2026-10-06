# Client tooling

How per-client Claude Code tooling (custom subagents + repo-specific
instruction files) is stored, versioned, and loaded — **without putting any
client-confidential content into these public dotfiles**.

See also: [Instructions & agents per lane](claude-code.md#instructions--agents-per-lane)
(the *global*, client-free layer) and
[Two Claude Code lanes](claude-code.md#two-claude-code-lanes)
(separated inference + memory per lane).

## The split: mechanism vs content

Client agents and rules embed client identifiers (package namespaces,
service/domain names, ticket prefixes), so they must **not** live in these
public dotfiles. But they still need to be durable (survive a repo re-clone
or OS reinstall) and reusable across machines.

The rule: **the mechanism lives here; the content lives in a private
per-client repo.**

| Layer | Lives in | Client content? | Survives reinstall via |
|---|---|---|---|
| Generic agents + baseline `CLAUDE.md` | `system/.claude/` (these dotfiles) | no | `darwin-rebuild switch` |
| Client overlay (name only, no internals) | `system/.claude-work/<client>/` (these dotfiles) | name only | `darwin-rebuild switch` |
| `cc-tooling` helper | `system/bin/cc-tooling.sh` (these dotfiles) | no | `darwin-rebuild switch` |
| Per-client agents + repo instruction files | **private repo, one per client** | yes | re-clone the private repo |
| Local checkout of that private repo | `~/.claude-clients/<client>/` | yes (local only) | re-clone |

## Separated lanes (one per context)

Each working context is an isolated **Claude Code lane** — its own config dir,
inference channel and codemem memory; see
[Two Claude Code lanes](claude-code.md#two-claude-code-lanes). Today: personal
(`~/.claude`, Max) and work (`cc-work`, `~/.claude-work`, Ahold via the TechNL
proxy). A new client that needs a sanctioned channel gets its **own lane**
(below) plus its **own private tooling repo**.

## How client tooling is stored (the private repo)

One private repo per client (on the client's own GitLab/GitHub), cloned or
linked under `~/.claude-clients/<client>/`. It mirrors each target checkout
under a `tree/`:

    <client>/
      repos/<repo>/tree/...   # mirrors that client repo; symlinked into the checkout
      shared/tree/...         # (optional) applied to every repo of that client

Every file under a `tree/` maps to the same relative path in the live
checkout — the directory layout *is* the manifest. A `tree/` typically holds
`.claude/agents/*.md` (project subagents) and nested `AGENTS.md` /
`CLAUDE.md` files (per-package rules).

> **Porting from OpenCode.** The existing Ahold tooling repo still holds
> OpenCode-format files (`.opencode/agent/*.md`, `opencode.json`, nested
> `AGENTS.md`). Port the agents to `.claude/agents/<name>.md` with Claude Code
> frontmatter — `name`, `description`, `tools`, and `model:` as an alias
> (`opus` / `sonnet`, never a full id) — and drop `opencode.json`. Do the port
> **from inside `cc-work`**, never from the personal lane (the personal guard
> blocks the work tree anyway). Nested `AGENTS.md` files keep working as-is: the
> work overlay tells Claude to read them.

## How it's loaded into a checkout (`cc-tooling`)

[`cc-tooling`](../system/bin/cc-tooling.sh) — a client-agnostic helper shipped
via [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix) — materializes a
client's `tree/` into a checkout:

| Command | What it does |
|---|---|
| `cc-tooling clone <client> <url>` | clone the private repo to `~/.claude-clients/<client>/` |
| `cc-tooling link <client> <path>` | symlink `~/.claude-clients/<client>` → an existing checkout of it |
| `cc-tooling apply <client>/<repo>` | symlink `tree/` files into the current checkout + write a marked `info/exclude` block (refuses if a destination already exists) |
| `cc-tooling status` | show what's applied in the current checkout |
| `cc-tooling unapply` | remove the symlinks + the exclude block |
| `cc-tooling list` | list set-up clients and their repos |

`apply` **symlinks** the files in (single source of truth — edit the private
repo once, every checkout updates) and adds their paths to the repo's
`info/exclude` inside a marked, removable block (written first, so an
interrupted apply never leaves visible links). It never overwrites: if any
destination exists and isn't one of its own links — e.g. a tracked
`AGENTS.md` in the client repo — it lists them and changes nothing. A
re-apply removes links the tooling no longer provides; a `repos/<repo>` file
overrides a `shared` one at the same path. It works in git worktrees too
(their exclude file lives in the main repo's git dir and is shared by all
worktrees). So:

- Claude Code discovers them like any project tooling (`.claude/agents/`, the
  repo-root `AGENTS.md` via the work lane's `SessionStart` hook, nested files
  per the overlay) and follows the symlinks.
- git never sees them — they are **not** committed to the client repo and
  **not** added to its shared `.gitignore`.

`$CC_TOOLING_HOME` overrides the base dir. It defaults to `~/.claude-clients`,
falling back to the pre-migration `~/.opencode-clients` if only that exists
(the exclude-block marker text is unchanged, so earlier applies still
`unapply` cleanly).

## Runbook — onboard a new client

Two parts: **(A)** an isolated lane in these dotfiles, and **(B)** the private
tooling repo. Skip part A if the client needs no channel isolation (then just
do B and work on its repos in the personal lane — don't add its root to
`workRoots`).

Throughout, replace `<client>` (lowercase slug, e.g. `acme`), `<Client>` /
`<Channel>` (Proton Pass vault/item), and the model ids. Pick a **unique viewer
port** (personal `4747`, Ahold `4848`, so the next is `4849`).

### A. Add an isolated lane

Edits are in [`nix/home/claude-lanes.nix`](../nix/home/claude-lanes.nix) and
[`nix/home/codemem.nix`](../nix/home/codemem.nix), mirroring the Ahold (`cc-work`)
lane.

1. **Add the client's secrets to Proton Pass** (resolved at runtime, never in
   the repo):
   - `pass://<Client>/<Channel>/api_key`
   - `pass://<Client>/<Channel>/proxy_url` — the **base** URL ending in `/v1`,
     without `/messages`.

2. **Lane config dir + env** in `claude-lanes.nix`: a `<client>Dir`
   (`~/.claude-<client>`), a `<client>Env` (from `codememEnv "<client>"` plus
   `CODEMEM_CONFIG`, `CODEMEM_VIEWER_PORT=<unique-port>`, `CODEMEM_PROJECT`,
   the `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` ids that channel serves,
   and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`), and add its names to
   `laneVars`.

3. **Work root** — add the client's checkout root (e.g.
   `${home}/projects/<client>`) to `workRoots`, so the personal-lane guard
   blocks it.

4. **Files + owned settings** — `home.file` entries for
   `.claude-<client>/{CLAUDE.md,agents,commands,hooks}` (CLAUDE.md = baseline +
   the client overlay), a `<client>Owned` block like `workOwned` (env, the
   lane-check / AGENTS.md hooks, `skipWebFetchPreflight`, default model), and a
   `run ${mergeSettings} …` line in `claudeLaneSettings`. The work hooks check
   for a non-Anthropic gateway URL and the codemem observer endpoint; give the
   new lane its own hooks dir (copy `system/.claude-work/hooks/` and adjust)
   and its own `CC_LANE` value in its env.

5. **Overlay folder** — `system/.claude-<client>/<client>/*.md` (client *name*
   only, like Ahold's — no internal architecture), or keep the rules in the
   private tooling repo (part B) and skip it.

6. **Launcher** — a `cc-<client>` function. Resolve the secrets from
   `pass-cli` and **fail closed**, check the proxy URL shape, then
   `env ${unsetLaneVars}` with `CLAUDE_CONFIG_DIR`, `CC_LANE`,
   `CODEMEM_ANTHROPIC_ENDPOINT="$proxy/messages"` (also pinned into the
   lane's `settings.json` env, as `cc-work` does) and the lane env, and then
   either:
   - **the client's sanctioned launcher**, if it has one — Ahold's `cc-work`
     wraps `devai-claude` and leaves the gateway variables to it; or
   - **`claude` with the gateway set directly**: `ANTHROPIC_BASE_URL` (proxy
     URL minus `/v1` — Claude Code appends `/v1/messages`), the credential
     (`ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN`), and
     `ANTHROPIC_CUSTOM_HEADERS` for whatever header the channel requires
     (the TechNL proxy accepts only `api-key: …`). Pre-DevAI `cc-work` in git
     history is the reference.

   Make the lane's `lane-check.sh` match what the launcher guarantees. Add the
   lane to `cc-lanes-setup`, and declare codemem in its owned settings
   (`codememPlugin`).

7. **codemem observer config** in `codemem.nix` — extraction routed through the
   same channel, plus the runtime dir in `home.activation.codememDirs`:
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
   Why `CODEMEM_ANTHROPIC_ENDPOINT`: codemem's Anthropic observer ignores
   `observer_base_url` and calls `api.anthropic.com` unless that env var is set.

8. `git add` the changed files and `darwin-rebuild switch`; the first
   session in the new lane fetches the codemem plugin.

9. **Verify isolation before real work**: in a throwaway repo, confirm the
   lane-check blocks a plain `claude` session in that config dir, the personal
   guard blocks the work root, `cc-<client> -p … --output-format json` reports
   the channel's model ids, and memories appear in `~/.codemem/<client>/`
   ~2 min after the session goes idle.

### B. Set up the tooling (private repo)

1. Create a **private** tooling repo on the client's infra; `cc-tooling clone
   <client> <url>` (or `link <client> <path>` if already checked out).
2. Populate `repos/<repo>/tree/` with `.claude/agents/*.md` + nested
   instruction files; commit + push (mind the [push-auth gotcha](#gotchas) for
   work accounts).
3. In each client checkout: `cc-tooling apply <client>/<repo>`.

## Runbook — restore after re-clone / OS reinstall

1. `darwin-rebuild switch` → the dotfiles, lanes, plugins + `cc-tooling` are
   back.
2. `cc-tooling clone <client> <url>` for each active client.
3. `cc-tooling apply <client>/<repo>` in each checkout.

## Switching clients

### Offboard a client

1. In each of that client's checkouts: `cc-tooling unapply` — removes the
   symlinks and the managed `.git/info/exclude` block, leaving the checkout
   clean.
2. Drop the local clone/link: `rm ~/.claude-clients/<client>` (a `link` is
   just a symlink; a `clone` is safe to `rm -rf` since it's pushed).
3. *(If the client had a lane)* remove its launcher, env, owned settings,
   files, overlay folder and work root from `claude-lanes.nix`, and its
   observer config from `codemem.nix`; `darwin-rebuild switch`. Then handle
   the lane's leftovers — `~/.claude-<client>/` (transcripts, auto-memory) and
   the memory DB at `~/.codemem/<client>/`:
   - **Delete them** if offboarding requires removing client-derived data —
     usually the right call.
   - Keep them only if you have a specific reason.
4. The private tooling repo stays on the client's infra (archive it there if
   you like). Nothing about the client remains in these public dotfiles.

### Onboard the new client

Follow [Onboard a new client](#runbook--onboard-a-new-client). The only
client-specific judgement is the **lane**:

- **No isolation needed** (the client allows your normal path) → skip the
  lane; use the tooling and work on the client's repos in the personal lane.
- **Sanctioned-channel isolation needed** (like Ahold's TechNL) → add a
  `cc-<client>` lane mirroring `cc-work`: its own config dir, DB folder,
  observer config, viewer port and work root, with its own channel (proxy URL +
  key resolved from `pass-cli`, **fail-closed**). Never reuse another client's
  lane, channel, or DB.

## Gotchas

- **Subagents don't nest.** Claude Code subagents can't dispatch subagents, so
  a client agent meant to orchestrate others must be run from the main session
  (a slash command), like `/flow`.
- **Project agents shadow global ones** with the same `name`. Give client
  agents distinct names unless overriding is the point.
- **Pushing the private repo.** git picks the GitHub login by checkout
  location (`credential.username` in the host's `git.nix`): the work account
  by default, the personal account under `~/projects/personal/` and
  `~/.dotfiles`. Keep the private repo where its owning account applies, or
  push once with `git -c credential.https://github.com.username=<account> push`.
- **`unapply` leaves empty dirs** (e.g. an empty `.claude/agents/`) —
  harmless; re-apply repopulates them.
- The client *name* (e.g. `ahold`) appears here as an example; the client's
  internal architecture lives only in the private repo — never in these
  dotfiles.
