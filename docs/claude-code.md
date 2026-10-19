# Claude Code integration

Each Mac has **one** Claude Code setup, in plain `~/.claude`. What it
talks to depends on the host's profile ([`nix/profiles/`](../nix/profiles/README.md)):

| Profile | Host | Inference | Start it with | codemem lane |
|---|---|---|---|---|
| `personal` | `m5` | Claude Max login | the desktop app, T3 Code, or plain `claude` | `~/.codemem/personal/` |
| `work` | `work` | the TechNL gateway, via DevAI CLI | `cc-work` (terminal) or `cc-work-desktop` (desktop app in gateway mode) | `~/.codemem/work/` |

Client (Ahold) work happens only on the client-issued `work` Mac, so
client content never meets the personal Max login: the separation is the
machine, not config on a shared one.

## Shared plumbing

[`nix/home/claude-code.nix`](../nix/home/claude-code.nix), on every
host. It links the static files and declares two options the profiles
set:

- `dotfiles.claude.settings` — keys Nix owns in
  `~/.claude/settings.json`, grouped by how they merge (`env`, `union`,
  `hooks`, `default`, `set`; see [Settings merge](#settings-merge)).
- `dotfiles.claude.instructions` — files appended, in order, to the
  global `~/.claude/CLAUDE.md`.

Read-only symlinks, recreated on every rebuild:

| Path | Source | Set by |
|---|---|---|
| `~/.claude/CLAUDE.md` | `system/.claude/CLAUDE.md` + `dotfiles.claude.instructions` | `claude-code.nix` |
| `~/.claude/README.md` | `system/.claude/README.md` | `claude-code.nix` |
| `~/.claude/agents`, `commands` | `system/.claude/{agents,commands}/` | `claude-code.nix` |
| `~/.claude/skills` | `system/.claude/skills/`, vault path filled in | `profiles/personal/vault.nix` |
| `~/.claude/hooks` | `system/claude-work/hooks/` | `profiles/work/claude.nix` |

To change one: edit the source in the repo, `git add`, rebuild. Files
inside the linked directories are read-only at `~/.claude/`.

### Settings merge

`~/.claude/settings.json` is rewritten by Claude Code at runtime (plugin
toggles, effort level, …), so it **must not** be a Nix-store symlink.
The repo keeps a reference snapshot, `system/.claude/settings.json`, and
the `claudeSettings` activation step merges **only the owned keys** into
the live file:

- `env` — owned keys overwrite; other env keys are kept, and a key Nix
  stops owning is removed on the next rebuild (the last owned set is in
  `.nix-owned.json` next to the settings file);
- `union` — every owned list gets its missing entries appended (sandbox
  paths, domains, sockets); your own entries are kept. Entries Nix stops
  owning are **not** removed — delete them in `/sandbox` or the file;
- `hooks` — hook entries whose command lives under `~/.claude/hooks/`
  are replaced; other hooks (plugins, your own) are kept, even in the
  same matcher group;
- `default` — written only where absent (so `/model` etc. keep working);
- `set` — always written (`enabledPlugins`, marketplaces, forced
  sandbox flags).

A missing file starts from the snapshot, so a fresh machine needs no
manual step. A file that isn't valid JSON is moved to
`settings.json.invalid-<time>` and rebuilt from the snapshot, with a
warning, instead of failing the rebuild. The merge is
[`system/bin/merge-claude-settings.sh`](../system/bin/merge-claude-settings.sh);
[`tests/merge.sh`](../tests/merge.sh) covers it.

Manual re-seed (then rebuild to merge the owned keys back in):

```bash
cp ~/.dotfiles/system/.claude/settings.json ~/.claude/settings.json
```

To refresh the snapshot after changing settings in the app, copy the
runtime file back and strip the owned keys (`env`, `hooks`, `sandbox`,
`enabledPlugins`, …). Everything else under `~/.claude/` (transcripts,
session state, plugin caches) is deliberately unmanaged.

**Plugins** are declared in the profiles (`enabledPlugins`, plus
codemem's marketplace from `codemem.nix`); Claude Code fetches any it
doesn't have when an interactive session starts. `false` disables one;
a `/plugin` toggle on a declared plugin lasts until the next rebuild.
`codemem-setup` installs codemem right away, for a machine that has only
run `claude -p`.

## Personal profile

[`nix/profiles/personal/claude.nix`](../nix/profiles/personal/claude.nix):
Claude Max, every Bash command sandboxed, the declared plugins, and
codemem extracting via Max.

### Bash sandbox

macOS Seatbelt, forced on every rebuild: `sandbox.enabled` and
`allowUnsandboxedCommands: false` (a failed command can't be retried
outside the sandbox, so the boundary holds in auto mode too); toggling
them off in `/sandbox` lasts until the next rebuild. Bash prompts stay
as they were (`autoAllowBashIfSandboxed: false`, only written when
unset).

Sandboxed commands can write only to the project folder, `$TMPDIR`,
`~/.m2`, `~/.gradle` and `~/.npm`, and reach without asking only Maven
Central, Gradle, npm, the k3s API, the Cloudflare API and `github.com`
(other hosts prompt per domain). Add more in `claude.nix`
(`union.sandbox.filesystem.allowWrite`, `…network.allowedDomains`) or in
`/sandbox` — your own entries survive rebuilds. The Docker socket
([below](#docker-colima)) and the Proton Pass SSH agent's are the only unix
sockets allowed; `network.allowLocalBinding: true` lets tests reach a
container's published ports on `localhost` (otherwise Seatbelt only
allows the sandbox proxy there). Known friction: Go CLIs such as `gh`
don't work inside Seatbelt — run those yourself, or list them in
`sandbox.excludedCommands` (fully unsandboxed).

Commits in this repo run the lint pre-commit hook, which normally gets
its tools from `nix develop` — unreachable from the sandbox (no Nix
daemon socket). So `claude.nix` sets `DOTFILES_LINT_PATH` to the same
tools (`nix/lint-tools.nix`), and `.githooks/pre-commit` puts them on
`PATH` when `$SANDBOX_RUNTIME` is set: Claude's commits get the full
lint, gitleaks included, before anything is pushed to this public repo.
Without the variable (a session older than the rebuild) the hook skips
with a warning and CI lints after the push.

### Git push/pull from the sandbox

[`nix/profiles/personal/sandbox-git.nix`](../nix/profiles/personal/sandbox-git.nix)
lets Claude `git push`, `pull` and `fetch` over SSH. Two things stop
plain `ssh` in the sandbox:

- **No route out.** Sandboxed commands have no DNS and only reach the
  sandbox proxy. The sandbox sets its own `GIT_SSH_COMMAND` (`nc -X 5`
  to its SOCKS port) without credentials, so the proxy refuses it, and
  it overwrites any `GIT_SSH_COMMAND` from the settings env. So a
  `git()` shell function (reaching Bash through the shell snapshot)
  sets `GIT_SSH_COMMAND` per call to `claude-git-ssh`
  ([`system/bin/claude-git-ssh.sh`](../system/bin/claude-git-ssh.sh))
  when `$SANDBOX_RUNTIME` is set. That adds a `ProxyCommand` tunnelling
  through the HTTP proxy with `ncat`, using the per-command credentials
  in `$HTTP_PROXY` and `127.0.0.1` (the proxy refuses `localhost`).
  Outside the sandbox `git` is untouched. Only `git` typed in Bash gets
  this, not a git run from inside another program.
- **Only fixed-path sockets.** The sandbox allows unix sockets by path.
  The keys come from the Proton Pass SSH agent ([docs/ssh.md](ssh.md)),
  whose socket is fixed (`~/.ssh/proton-pass-agent.sock`), so the
  sandbox allows exactly that one and `~/.ssh/config` already points
  `github.com` at it. No key files, no passphrases.

Check it from a session with
`SSH_AUTH_SOCK=~/.ssh/proton-pass-agent.sock ssh-add -l` and
`git ls-remote origin`. Not covered: `gh` (HTTPS API) and HTTPS remotes;
`git.nix` rewrites `https://github.com` to SSH anyway.

The trade-off: sandboxed commands can use **every key loaded in the
agent** for any SSH host the allowlist lets through (today only
`github.com`), and push to any repo those keys can write to.

### Vault skills

[`nix/profiles/personal/vault.nix`](../nix/profiles/personal/vault.nix)
links `system/.claude/skills/` (the `vault-*` Obsidian skills) with the
vault path substituted for `@VAULT@`, and sets `OBSIDIAN_VAULT` for the
`notes`/`note` shell functions. Personal only.

## Work profile

[`nix/profiles/work/claude.nix`](../nix/profiles/work/claude.nix): Claude
Code only through Ahold's TechNL gateway. DevAI CLI is the sanctioned
way in: `devai setup` once (Entra ID keyless sign-in, or a static key),
then `devai-claude` starts Claude Code through a temporary local
compatibility proxy. DevAI owns auth, the proxy and model routing;
`devai status` / `devai quota` show login state and budget. Install it
per its docs (`npm install -g @royalaholddelhaize/devai-cli`, needs a
GitHub Packages token). Requires Claude Code CLI **>= 2.1.285** (the
`claude-code` cask) — older builds reject `claude-opus-5-5` as
`unrecognized_model`.

### The launchers (zsh functions)

- **`cc-work`** — refuses to start unless `devai-claude` is installed.
  It resolves the TechNL proxy URL from `pass-cli`
  (`pass://Ahold/TechNLGenAI/proxy_url`) for codemem's observer and
  **fails closed** if it is missing or malformed — without it the
  observer would default to `api.anthropic.com`. It pins that endpoint
  into `~/.claude/settings.json` (`env.CODEMEM_ANTHROPIC_ENDPOINT`, a
  local file, never the repo) and runs `devai-claude -- "$@"`, so its
  arguments are Claude Code's (`cc-work -p …`, `cc-work --resume`); call
  `devai-claude` directly for DevAI's own options.
- **`cc-work-desktop`** — the same preparation, then
  `devai-claude-desktop --detach`: DevAI starts its local proxy (kept
  running after the shell exits), switches the desktop app to its
  gateway profile (`Claude-3p`, its own chats, login and settings) and
  **restarts the app**. Run it from a regular terminal — the app's own
  terminal pane closes with it. Switch back under Developer → Configure
  Third-Party Inference; `devai status` shows the desktop state.

The rest of the work env lives in `settings.json`, so every session gets
it however it was launched: `CODEMEM_PROJECT`, model aliases `opus` →
`claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5`, `haiku` →
`claude-haiku-4-5` (`ANTHROPIC_DEFAULT_*_MODEL`; `/model` can still pick
any other id the gateway serves — `devai status` lists them), and
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` (no telemetry, error
reports, auto-updates or feature-flag calls to Anthropic). Also merged:
`skipWebFetchPreflight: true` (the preflight sends the target hostname
to `api.anthropic.com`) and `model: "opus"` as a default.

### Gateway check

[`gateway-check.sh`](../system/claude-work/hooks/gateway-check.sh)
(`UserPromptSubmit` + `PreToolUse`) blocks (exit 2, before anything is
sent — a blocked prompt makes zero API calls) unless the session has a
gateway URL (`ANTHROPIC_BASE_URL` or `CLAUDE_CODE_API_BASE_URL`) that
isn't `anthropic.com`, and a `CODEMEM_ANTHROPIC_ENDPOINT` that isn't
either. Both launchers pass; plain `claude` (no gateway) and the
desktop app in its normal mode (`ANTHROPIC_BASE_URL=https://api.anthropic.com`)
are blocked. Fixtures: [`tests/gateway-check.sh`](../tests/gateway-check.sh).

### Instructions

- The Ahold overlay — every `system/claude-work/ahold/*.md`, in name
  order — is appended to the global `CLAUDE.md` via
  `dotfiles.claude.instructions`. Add files alongside the existing ones;
  client *name* only, no internals.
- Ahold repos keep their instructions in `AGENTS.md`, which Claude Code
  doesn't auto-load. The `agents-md.sh` `SessionStart` hook injects the
  repo-root `AGENTS.md` (skipped if the repo's `CLAUDE.md` already
  imports `@AGENTS.md`); the overlay tells Claude to read nested
  `AGENTS.md` files before working in a subdirectory.
- `cc-tooling` (per-client agents and rules from a private repo) ships
  with this profile — see [Client tooling](client-tooling.md).

Agents set `model:` to an **alias** only (`opus` / `sonnet`), never a
full id, so on the work Mac every tier resolves to a TechNL id and an
agent can't route client work out of the gateway.

## Docker (Colima)

[`nix/profiles/dev/docker.nix`](../nix/profiles/dev/docker.nix), on
every machine: a [Colima](https://github.com/abiosoft/colima) VM is
**the** Docker engine — Docker Desktop is gone. The shell, IntelliJ,
Testcontainers and Claude Code all use it.

- **The VM** — Colima's `default` profile, started at login by a
  launchd agent (`colima-default`): 4 CPUs, 3 GB RAM, 60 GB disk (vz,
  virtiofs). Its only mount is `~/projects`, writable, replacing
  Colima's default mount of all of `$HOME`. `colima.yaml` is a store
  symlink, which is safe because the agent starts Colima with
  `--save-config=false`; `sshConfig = false` keeps `~/.ssh/config`
  untouched.
- **Selection** — Colima makes `colima` the active docker context
  (written to `~/.docker/config.json`, app-owned and never symlinked),
  and `DOCKER_HOST=unix://~/.colima/default/docker.sock` plus
  `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock` (the
  socket path inside the VM, which Ryuk mounts) are set in the shell
  and in Claude's `settings.json` env (desktop-app sessions don't
  inherit the shell).
- **The CLI** — `docker` from nixpkgs with the compose and buildx
  plugins.
- **Personal sandbox** — `claude.nix` allows the socket in
  `sandbox.network.allowUnixSockets`, so sandboxed Claude can run
  `docker`, `docker compose` and Testcontainers itself.

Day to day: bind mounts outside `~/projects` (including `$TMPDIR`) come
up empty inside containers; Testcontainers copies files over the API,
so `withCopyFileToContainer` works from anywhere. Status and recovery:
`colima status`, `colima stop` (frees the RAM; it comes back at next
login, or `colima start`). Log: `~/.local/state/colima/default.log`.
Colima runs on Lima, which can break after a macOS or Colima update; a
stop/start usually fixes it.

What the sandbox gives up by allowing the socket, deliberately: a
container started from a sandboxed session can write anywhere under
`~/projects`, not just the current project; container traffic (image
pulls included) leaves through the VM, not the sandbox proxy, so
`allowedDomains` doesn't apply to it; and with `allowLocalBinding`,
sandboxed commands can reach any service listening on `localhost`.

Left over from the old setup (Colima `personal` profile) after the
first rebuild: `colima delete -p personal` removes its VM.

## codemem memory

[codemem](https://www.npmjs.com/package/codemem) gives Claude Code
persistent memory. [`nix/home/codemem.nix`](../nix/home/codemem.nix)
declares `dotfiles.codemem.lane` and `dotfiles.codemem.observer`; with a
lane set it writes the observer config to
`~/.config/codemem/<lane>.json`, creates `~/.codemem/<lane>/`, declares
the plugin and its marketplace, and puts `CODEMEM_DB`, `CODEMEM_CONFIG`,
`CODEMEM_PLUGIN_LOG` and `CODEMEM_CLAUDE_HOOK_{SPOOL,LOCK,CONTEXT}_DIR`
in the settings env (the plugin's hooks, MCP server and viewer inherit
them).

| Profile | Lane | Observer | Extraction goes through |
|---|---|---|---|
| personal | `personal` | `claude_sidecar`, `claude-haiku-4-5` | local Claude (Max) |
| work | `work` | `api_http` / `anthropic`, `claude-haiku-4-5`, `api-key` header | the TechNL proxy (`CODEMEM_ANTHROPIC_ENDPOINT`, pinned by `cc-work`) |

The work observer's key comes from a `pass-cli` command in its config
(`pass://Ahold/TechNLGenAI/api_key`, cached five minutes). codemem's
Anthropic observer ignores `observer_base_url` and calls
`api.anthropic.com` unless `CODEMEM_ANTHROPIC_ENDPOINT` is set, which is
why `cc-work` and the gateway check insist on it. The extraction sweep
runs in the viewer the MCP server auto-starts (~2 min after a session
goes idle), so work extraction stays in the TechNL channel.

**No secrets live in the repo.** The TechNL key and proxy URL are
resolved at runtime via `pass-cli`, and paths use
`config.home.homeDirectory`, so the modules survive a change of host or
username. Prereqs: `pass-cli` (a `dev` brew) and Node 24.15+ (the
plugin's hooks run `node`, its MCP server `npx`) — mise's global Node
LTS covers it.

## History

- **Two lanes on one Mac** (until October 2026): m5 ran a personal
  `~/.claude` and a work `~/.claude-work` side by side, with a guard
  hook keeping the client tree out of the personal lane, a Colima VM
  only for personal sessions and Docker Desktop for everything else.
  Replaced by one role per machine; see git history before `7714277`.
  On m5, `~/.claude-work`, `~/.codemem/work-ahold` and
  `~/.config/codemem/work-ahold.json` can be deleted by hand.
- **OpenCode** was replaced by Claude Code and fully removed. Leftovers:
  `~/.local/share/opencode`, `~/.cache/opencode`, `~/.config/opencode`.
- **claude-mem** was replaced by codemem. On a machine that still has
  it: `npx claude-mem uninstall`, then `rm -rf ~/.claude-mem` if you
  don't want its memories.

## Agent workflow

A schema-driven, multi-agent way to take a feature from spec to merged:
the `/flow <spec>` command makes the main session the **lead**, which
dispatches role subagents (`planner` on Opus; `architect`/`developer`/
`reviewer`/`closer` on Sonnet) and the specialists, and enforces an
escalation ladder + review gates. `/flow-plan`, `/flow-review` and
`/flow-close` run single steps. Roles live in `system/.claude/agents/`,
commands in `system/.claude/commands/`; tiers are model aliases each
machine maps to its own models.

Full reference: [Agent workflow](agent-workflow.md).

## Repo-level Claude config

- `CLAUDE.md` at the repo root is the agent entry point; it defers to
  `docs/` for detail. `AGENTS.md` is a symlink to it so tools that read
  the cross-tool `AGENTS.md` convention see the same guidance.
- `.gitignore` excludes `/.claude/` at the repo root (machine-local
  Claude Code worktree state) — distinct from `system/.claude/`, which
  is versioned.
- The global git ignores (`nix/home/git.nix`) exclude
  `**/.claude/settings.local.json` and `**/CLAUDE.local.md` in every
  repo: they hold per-machine approvals and notes.
