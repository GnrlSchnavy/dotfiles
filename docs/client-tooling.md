# Client tooling

How per-client Claude Code tooling (custom subagents + repo-specific
instruction files) is stored, versioned, and loaded — **without putting any
client-confidential content into these public dotfiles**.

See also: [Work profile](claude-code.md#work-profile) (the client machine's
Claude Code setup: gateway, overlay, `AGENTS.md` hook) and
[Agent workflow](agent-workflow.md) (the *global*, client-free agents).

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
| Client overlay (name only, no internals) | `system/claude-work/<client>/` (these dotfiles) | name only | `darwin-rebuild switch` |
| `cc-tooling` helper | `system/bin/cc-tooling.sh` (these dotfiles) | no | `darwin-rebuild switch` |
| Per-client agents + repo instruction files | **private repo, one per client** | yes | re-clone the private repo |
| Local checkout of that private repo | `~/.claude-clients/<client>/` | yes (local only) | re-clone |

## Where client work runs

On the **client's machine**, never the personal Mac: each Mac plays one role
([hosts.md](hosts.md)). Today that is Ahold's client-issued Mac, host `work`,
profile [`nix/profiles/work/`](../nix/profiles/work/) — Claude Code only through
the TechNL gateway (`cc-work`), codemem through the same gateway, and
`cc-tooling` on `PATH`. A new client with its own sanctioned channel gets its
**own profile** (below) plus its **own private tooling repo**.

## How client tooling is stored (the private repo)

One private repo per client (on the client's own GitLab/GitHub), cloned or
linked under `~/.claude-clients/<client>/`. It mirrors each target checkout
under a `tree/`:

    <client>/
      repos/<repo>/tree/...   # mirrors that client repo; symlinked into the checkout
      shared/tree/...         # (optional) applied to every repo of that client

Every file under a `tree/` maps to the same relative path in the live
checkout — the directory layout *is* the manifest. Only instructions and
prompts are linked: `.claude/agents/*.md` (project subagents),
`.claude/commands/*.md`, and nested `AGENTS.md` / `CLAUDE.md` files
(per-package rules). Anything else (a `.claude/settings.json`, hooks,
scripts) is skipped with a warning, so the private repo can't change
Claude's permissions, environment or hooks on this Mac.

> **Porting from OpenCode.** The existing Ahold tooling repo still holds
> OpenCode-format files (`.opencode/agent/*.md`, `opencode.json`, nested
> `AGENTS.md`). Port the agents to `.claude/agents/<name>.md` with Claude Code
> frontmatter — `name`, `description`, `tools`, and `model:` as an alias
> (`opus` / `sonnet`, never a full id) — and drop `opencode.json`. Do the port
> **on the work Mac, from inside `cc-work`**. Nested `AGENTS.md` files keep
> working as-is: the work overlay tells Claude to read them.

## How it's loaded into a checkout (`cc-tooling`)

[`cc-tooling`](../system/bin/cc-tooling.sh) — a client-agnostic helper shipped
by the work profile ([`nix/profiles/work/claude.nix`](../nix/profiles/work/claude.nix))
— materializes a client's `tree/` into a checkout:

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
  repo-root `AGENTS.md` via the work profile's `SessionStart` hook, nested
  files per the overlay) and follows the symlinks.
- git never sees them — they are **not** committed to the client repo and
  **not** added to its shared `.gitignore`.

`$CC_TOOLING_HOME` overrides the base dir. It defaults to `~/.claude-clients`,
falling back to the pre-migration `~/.opencode-clients` if only that exists
(the exclude-block marker text is unchanged, so earlier applies still
`unapply` cleanly).

## Runbook — onboard a new client

Two parts: **(A)** a client profile and host in these dotfiles, and **(B)** the
private tooling repo. Skip part A if the client needs no channel isolation and
you already work for it on a client machine — then just do B there.

Throughout, replace `<client>` (lowercase slug, e.g. `acme`), `<Client>` /
`<Channel>` (Proton Pass vault/item), and the model ids.

### A. Add a client profile and host

Mirror [`nix/profiles/work/`](../nix/profiles/work/) (Ahold).

1. **Add the client's secrets to Proton Pass** (resolved at runtime, never in
   the repo):
   - `pass://<Client>/<Channel>/api_key`
   - `pass://<Client>/<Channel>/proxy_url` — the **base** URL ending in `/v1`,
     without `/messages`.

2. **Profile** — `nix/profiles/<client>/`: `default.nix` (module lists),
   `homebrew.nix` (the client's apps), `git.nix` (the client git identity),
   and `claude.nix`. Add its row to `nix/profiles/README.md`.

3. **`claude.nix`** — set the shared options, as `profiles/work/claude.nix`
   does:
   - `dotfiles.claude.settings.env`: `CODEMEM_PROJECT`, the
     `ANTHROPIC_DEFAULT_{OPUS,SONNET,HAIKU}_MODEL` ids that channel serves,
     `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`;
   - `…settings.hooks`: a gateway check on `UserPromptSubmit` +
     `PreToolUse` (and `agents-md.sh` on `SessionStart` if the client uses
     `AGENTS.md`), linked as `~/.claude/hooks`. Reuse
     `system/claude-work/hooks/` if it matches what the launcher guarantees,
     or copy and adjust it;
   - `…settings.set.skipWebFetchPreflight = true`, `…default.model`;
   - `dotfiles.claude.instructions`: the overlay files (step 4);
   - `cc-tooling` in `home.packages`.

4. **Overlay folder** — `system/claude-work/<client>/*.md` (client *name*
   only, like Ahold's — no internal architecture), or keep the rules in the
   private tooling repo (part B) and skip it.

5. **Launcher** — a `cc-<client>` function. Resolve the proxy URL from
   `pass-cli` and **fail closed**, check its shape, pin
   `CODEMEM_ANTHROPIC_ENDPOINT="$proxy/messages"` into `settings.json` (as
   `cc-work` does) and in the launch env, then either:
   - **the client's sanctioned launcher**, if it has one — Ahold's `cc-work`
     wraps `devai-claude` and leaves the gateway variables to it; or
   - **`claude` with the gateway set directly**: `ANTHROPIC_BASE_URL` (proxy
     URL minus `/v1` — Claude Code appends `/v1/messages`), the credential
     (`ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN`), and
     `ANTHROPIC_CUSTOM_HEADERS` for whatever header the channel requires
     (the TechNL proxy accepts only `api-key: …`). Pre-DevAI `cc-work` in git
     history is the reference.

6. **codemem** — extraction routed through the same channel:
   ```nix
   dotfiles.codemem = {
     lane = "<client>";
     observer = {
       observer_runtime = "api_http";
       observer_provider = "anthropic";
       observer_model = "claude-haiku-4-5";
       observer_auth_source = "command";
       observer_auth_command = [ "pass-cli" "item" "view" "pass://<Client>/<Channel>/api_key" ];
       observer_auth_cache_ttl_s = 300;
       observer_headers."api-key" = "\${auth.token}";  # literal ${auth.token}
     };
   };
   ```
   Why `CODEMEM_ANTHROPIC_ENDPOINT`: codemem's Anthropic observer ignores
   `observer_base_url` and calls `api.anthropic.com` unless that env var is set.

7. **Host** — the client's Mac gets a descriptor with
   `profiles = [ "dev" "<client>" ]`, in its own `nix/hosts/<name>/`
   folder ([hosts.md](hosts.md#onboarding-a-new-mac)). Never add a client profile to
   the personal Mac.

8. `git add` the changed files and run `./setup.sh` (or `darwin-rebuild
   switch`) on that Mac; the first session fetches the codemem plugin.

9. **Verify before real work**: in a throwaway repo, confirm the gateway check
   blocks a plain `claude` session, `cc-<client> -p … --output-format json`
   reports the channel's model ids, and memories appear in
   `~/.codemem/<client>/` ~2 min after the session goes idle.

### B. Set up the tooling (private repo)

1. Create a **private** tooling repo on the client's infra; `cc-tooling clone
   <client> <url>` (or `link <client> <path>` if already checked out).
2. Populate `repos/<repo>/tree/` with `.claude/agents/*.md` + nested
   instruction files; commit + push (mind the [push-auth gotcha](#gotchas)).
3. In each client checkout: `cc-tooling apply <client>/<repo>`.

## Runbook — restore after re-clone / OS reinstall

1. `darwin-rebuild switch` → the dotfiles, Claude Code setup, plugins +
   `cc-tooling` are back.
2. `cc-tooling clone <client> <url>` for each active client.
3. `cc-tooling apply <client>/<repo>` in each checkout.

## Switching clients

### Offboard a client

1. In each of that client's checkouts: `cc-tooling unapply` — removes the
   symlinks and the managed `.git/info/exclude` block, leaving the checkout
   clean.
2. Drop the local clone/link: `rm ~/.claude-clients/<client>` (a `link` is
   just a symlink; a `clone` is safe to `rm -rf` since it's pushed).
3. *(If the client had a profile)* remove `nix/profiles/<client>/`, its
   overlay folder, its host descriptor and `flake.nix` entry. The machine
   usually goes back to the client; if not, delete `~/.claude/`
   (transcripts, auto-memory) and `~/.codemem/<client>/` — offboarding
   usually requires removing client-derived data.
4. The private tooling repo stays on the client's infra (archive it there if
   you like). Nothing about the client remains in these public dotfiles.

### Onboard the new client

Follow [Onboard a new client](#runbook--onboard-a-new-client). The only
client-specific judgement is the **channel**:

- **No isolation needed** (the client allows your normal path) → skip the
  client profile; use the tooling on the machine you do that client's work on.
- **Sanctioned-channel isolation needed** (like Ahold's TechNL) → a
  `<client>` profile mirroring `work` on the client's own Mac, with its own
  channel (proxy URL + key resolved from `pass-cli`, **fail-closed**),
  codemem lane and observer. Never reuse another client's profile, channel,
  or memory.

## Gotchas

- **Subagents don't nest.** Claude Code subagents can't dispatch subagents, so
  a client agent meant to orchestrate others must be run from the main session
  (a slash command), like `/flow`.
- **Project agents shadow global ones** with the same `name`. Give client
  agents distinct names unless overriding is the point.
- **Pushing the private repo.** On the work Mac git uses the work identity
  and GitHub login (`nix/profiles/work/git.nix`) everywhere except the
  dotfiles clones, which stay personal. The SSH key github.com uses is up to
  `~/.ssh/config` on that machine; push once with
  `git -c credential.https://github.com.username=<account> push` if a
  different login is needed.
- **`unapply` leaves empty dirs** (e.g. an empty `.claude/agents/`) —
  harmless; re-apply repopulates them.
- The client *name* (e.g. `ahold`) appears here as an example; the client's
  internal architecture lives only in the private repo — never in these
  dotfiles.
