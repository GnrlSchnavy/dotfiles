# Profiles — what each machine gets

Every Mac gets the shared base plus the `dev` profile, and exactly one of
`personal` or `work`:

| Host | Profiles | Role |
|---|---|---|
| `m5` | `dev` + `personal` | Personal Mac. No client work, ever. |
| `work` | `dev` + `work` | Client-issued Mac (Ahold). Client work only. |
| `ci` | `dev` + `personal` | GitHub Actions fresh-install test of m5's setup. |

This doc describes what you end up with on each. How profiles are wired
and where a change belongs: [`nix/profiles/README.md`](../nix/profiles/README.md)
and [architecture.md](architecture.md#profiles). `tests/docs.sh` fails when
an app or brew in a profile's `homebrew.nix` isn't named here.

## At a glance

| | m5 (`personal`) | work (`work`) |
|---|---|---|
| Extra apps | Proton suite, Signal, WhatsApp, Discord, Slack, Steam, … | Slack, GitHub Copilot (Outlook, Teams etc. preinstalled by the client) |
| Git identity | personal (`yvan`, gmail) | work (`yvanstemmerik-ah`, ah.nl); the dotfiles repo still commits as personal |
| Claude Code backend | Claude Max login | TechNL GenAI gateway via DevAI CLI only |
| Start Claude with | `claude` or the desktop app | `cc-work` or `cc-work-desktop` |
| Bash sandbox | always on | off |
| Plugins | codemem + superpowers, code-review, playwright, … | codemem only |
| Blocking hooks | none | gateway check on every prompt and tool call |
| Extra `CLAUDE.md` | — | Ahold overlay (data isolation, stack) |
| codemem extracts via | local Claude (Max) | TechNL proxy |
| Vault skills (`vault-*`) | yes | no |
| Sign-ins after install | `pass-cli login` | `pass-cli login`, DevAI CLI install + `devai setup`, work SSH key |

## Every machine — the shared base

Not a profile: `nix/modules/` and `nix/home/` apply to every host.

- **macOS defaults** (`modules/system.nix`): Touch ID for sudo, caps
  lock → escape, dark mode, fast key repeat, no autocorrect/smart quotes,
  Finder in column view with path bar, screen locks immediately, lock
  screen shows a contact email, guest login off.
- **Homebrew policy** (`modules/homebrew.nix`): `cleanup = "zap"` — what
  isn't declared for the host is uninstalled on rebuild; brew
  auto-updates and upgrades on every rebuild. Third-party taps are
  trusted automatically (`modules/homebrew-trust.nix`).
- **Nix itself** (`modules/nix.nix`): unfree packages allowed, weekly
  garbage collection of generations older than 30 days, store dedup.
- **Shell** (`home/zsh.nix`, `modules/environment.nix`): zsh with
  autosuggestions and syntax highlighting, fzf (Ctrl-R history, Ctrl-T
  files), zoxide (`z`/`j`), kubectl completion and aliases (`k`, `kg`,
  `kgp`, `kgd`, `kgs`, `kga`, `kd`, `kaf`, `kdf`), `notes`/`note` (nvim in
  the notes folder), `EDITOR`/`VISUAL` = nvim.
- **Neovim**: NixVim (Catppuccin, LSP, Telescope, Treesitter), built per
  host by `mkNvim` ([nvim-cheatsheet.md](nvim-cheatsheet.md)).
- **Java & Node** (`home/mise.nix`): Temurin 25 (default) and 21, Node
  LTS; per-project versions from `.java-version` / `.nvmrc` / `mise.toml`.
- **Git** (`home/git.nix`): SSH for GitHub, rebase on pull, histogram
  diffs, rerere, global ignores; personal identity unless the profile
  overrides it; both dotfiles clones always commit as personal and run
  the repo's pre-commit lint.
- **Secrets** (`home/secrets.nix`): `pass-check`, `pass-get`,
  `pass-render` around Proton Pass ([secrets.md](secrets.md)).
- **Claude Code plumbing** (`home/claude-code.nix`): one config dir,
  `~/.claude`; the shared subagents (planner, architect, developer,
  reviewer, closer and ~30 specialists) and commands (`/flow`,
  `/flow-plan`, `/flow-review`, `/flow-close`, `/search-web`); the global
  `CLAUDE.md`; the settings merge that writes each profile's owned keys
  into `~/.claude/settings.json` on every rebuild.
- **codemem plumbing** (`home/codemem.nix`): persistent memory for
  Claude Code; the profile picks the lane and how memories are extracted.
  `codemem-setup` installs the plugin immediately if a session hasn't yet.

## `dev` — every machine

[`nix/profiles/dev/`](../nix/profiles/dev/)

### Apps (Homebrew casks)

| Group | Apps |
|---|---|
| Browsers | `brave-browser`, `firefox`, `google-chrome` |
| Productivity | `alfred`, `obsidian`, `rectangle` |
| Passwords | `proton-pass` (the app; `pass-cli` below reads the same vaults) |
| Music | `spotify` |
| Dictation | `wispr-flow` (cloud transcription — dictated audio goes to Wispr's servers) |
| Development | `intellij-idea`, `visual-studio-code`, `warp`, `claude` (desktop app), `claude-code` |

### CLI tools

From nixpkgs (`packages.nix`): `git`, `jq`, `ripgrep`, `fd`, `bat`, `tree`,
`curl`, `wget`, `htop`, `fastfetch`, `unzip`, `p7zip`, `mkalias`, `tmux`,
`gnupg`, `maven`, `kotlin`, `kdoctor` (Kotlin Multiplatform check),
`pnpm`, `kubectl`, `helm`, `kubeseal`, `gh`.

From Homebrew, each for a stated reason (`homebrew.nix`):

| Brew | Why not nixpkgs |
|---|---|
| `fluxcd/tap/flux` | official tap; tracks the cluster's controller releases |
| `protonpass/tap/pass-cli` | official tap; brew owns its updates |
| `opencode`, `openspec` | release about weekly; stable nixpkgs lags |

### Alfred on Cmd-Space

`alfred.nix`, on every rebuild:

- turns off Spotlight's Cmd-Space ("Show Spotlight search"; Finder's
  Opt-Cmd-Space search window is left alone) and applies it without
  logging out;
- sets Alfred's hotkey to Cmd-Space. Alfred keeps it per machine in a
  folder it creates on its **first launch**, so on a new Mac: open Alfred
  once, rebuild, then restart Alfred.

### Docker (Colima)

`docker.nix`: a Colima VM (profile `default`) starts at login and is the
only Docker engine — there is no Docker Desktop.

- `docker`, `docker compose`, `docker buildx` come from nixpkgs.
- Colima is the active docker context; the shell also gets `DOCKER_HOST`,
  and Testcontainers gets `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE`. Claude
  Code sessions get both through `~/.claude/settings.json`.
- 4 CPUs, 3 GB RAM, 60 GB disk.
- Containers see host files under **`~/projects` only** — bind-mounting
  anything outside it gives an empty directory.
- `colima status`, `colima stop` / `colima start`; log in
  `~/.local/state/colima/default.log`. Details:
  [claude-code.md](claude-code.md#docker-colima).

## `personal` — m5

[`nix/profiles/personal/`](../nix/profiles/personal/)

### Apps (Homebrew casks)

| Group | Apps |
|---|---|
| Communication | `discord`, `signal`, `slack`, `whatsapp` |
| Media | `vlc`, `jellyfin-media-player`, Feishin (music; pinned dmg via Nix); Spotify is in `dev` |
| Proton | `proton-drive`, `proton-mail`, `proton-mail-bridge`, `protonvpn` (Proton Pass is in `dev`) |
| Networking | `tailscale-app` (homelab) |
| Development | `t3-code` (T3 Code, a front end for Claude Code) |
| Kubernetes | `lens` (homelab k3s; not on the work Mac) |
| Browsers | `tor-browser` |
| Dictation | `handy` (local; Wispr Flow is in `dev`) |
| Games | `steam`, `crossover` |
| Utilities and security | `little-snitch`, `knockknock`, `oversight`, `taskexplorer`, `balenaetcher` |

### CLI tools

From nixpkgs: `ansible`, `nmap`, `stripe-cli`. From Homebrew: `clamav`
(brew keeps freshclam's config and signature database writable; the Nix
build doesn't).

### Git

The personal identity (`yvan`, gmail, GitHub user `GnrlSchnavy`) — the
shared default, nothing to override.

### SSH

`ssh.nix`: keys from the Proton Pass vault `SSH-personal`
([docs/ssh.md](ssh.md)) — GitHub (GnrlSchnavy), GitLab (yvanpersonal) and the homelab
(`ssh nas-1`, `node-1` … `node-5`, `ha`). No key files on disk.

### Claude Code — Claude Max, sandboxed

`claude.nix`. Sign in to your Claude Max account in the desktop app or
`claude`; there is no launcher.

- **Bash sandbox, always on** (macOS Seatbelt). Commands can't fall back
  to running unsandboxed, even in auto mode. Allowed beyond the project:
  writes to `~/.m2`, `~/.gradle`, `~/.npm`; network to Maven Central,
  Gradle, npm, the k3s API, Cloudflare's API (wrangler) and GitHub
  (SSH); the Colima socket (so Claude can run `docker` and
  Testcontainers); localhost binding (tests reaching published ports).
- **Git push and pull from the sandbox** (`sandbox-git.nix`): the sandbox
  may use the Proton Pass SSH agent's socket, and a `git()` wrapper sends
  sandboxed git over SSH through the sandbox proxy.
- **Plugins**: codemem, superpowers, frontend-design, context7,
  code-review, code-simplifier, skill-creator, playwright, feature-dev,
  kotlin-lsp (clangd-lsp and swift-lsp off). Fetched by the first
  interactive session.
- **Lint in the sandbox**: `DOTFILES_LINT_PATH` gives the dotfiles'
  pre-commit hook its tools, since `nix develop` can't run there.
- **codemem**: lane `personal` (`~/.codemem/personal`), memories
  extracted by the local Claude sidecar on your Max login.

### Obsidian vault

`vault.nix`: the `vault-*` skills (`/vault-today`, `/vault-close`,
`/vault-context`, …) with the vault path filled in, and `OBSIDIAN_VAULT`
so `notes`/`note` open the vault.

### After a fresh install

`pass-cli login` and the Keychain fix for `pass-cli`
([docs/ssh.md](ssh.md#prerequisites-once-per-mac)); SSH keys then come
from Proton Pass.

## `work` — the client Mac

[`nix/profiles/work/`](../nix/profiles/work/)

### Apps (Homebrew casks)

`slack`, `github-copilot-app`. No personal apps.

Outlook, Teams and the other Microsoft apps come preinstalled by the
client's device management, so they aren't declared: brew refuses to
install over an app it didn't install, which would fail the rebuild.
`zap` only removes what Homebrew installed, so it leaves them alone.
The same goes for any other app the client preinstalls — leave it out
of the profiles for that machine.

### Git

`git.nix`: work identity by default (`yvanstemmerik-ah`,
`yvan.stemmerik@ah.nl`, GitHub user `yvanstemmerik-ah`). The dotfiles
clones still commit as personal.

### SSH

`ssh.nix`: keys from the Proton Pass vault `SSH-work`
([docs/ssh.md](ssh.md)). `github.com` is the work account;
`github-personal` is your personal account with its own key, and git
sends every `GnrlSchnavy` repo there (these dotfiles included).

### Claude Code — only through the gateway

`claude.nix`. Client content must stay inside the sanctioned TechNL GenAI
gateway; it must never reach `api.anthropic.com` directly or a Claude Max
login. DevAI CLI (Ahold's launcher) owns the gateway auth, its local
proxy and model routing.

- **Start sessions with**:
  - `cc-work` — `devai-claude` in a terminal;
  - `cc-work-desktop` — `devai-claude-desktop`, which switches the
    desktop app to its gateway profile and restarts it (run it from a
    normal terminal, not the app's own).

  Both first check that DevAI is installed, resolve the TechNL proxy URL
  from Proton Pass and pin it as codemem's endpoint — and refuse to start
  if any of that fails.
- **Gateway check** (`system/claude-work/hooks/gateway-check.sh`): runs on
  every prompt and tool call and blocks unless the session has a
  non-Anthropic gateway URL and codemem's endpoint is the TechNL proxy.
  Plain `claude`, or the desktop app in its normal mode, is blocked.
- **Repo instructions**: Ahold repos keep theirs in `AGENTS.md`, which
  Claude Code doesn't load by itself; a SessionStart hook injects the
  repo-root one.
- **Ahold overlay**: every `system/claude-work/ahold/*.md` is appended to
  the global `CLAUDE.md` — the data-isolation rules and the stack notes.
- **Models**: the `opus` / `sonnet` / `haiku` aliases map to the ids the
  gateway serves (`ANTHROPIC_DEFAULT_*_MODEL`); default model `opus`.
  Subagents use aliases, so they stay inside the gateway too.
- **No calls to Anthropic**: telemetry, error reports, auto-updates and
  feature flags are off; WebFetch's preflight (which sends the hostname
  to Anthropic) is skipped.
- **No sandbox and no extra plugins** — only codemem. Add plugins in
  `claude.nix` if you want them there.
- **codemem**: lane `work` (`~/.codemem/work`), memories extracted
  through the TechNL proxy with a key read from Proton Pass.
- **`cc-tooling`**: applies per-client Claude Code tooling (agents,
  `CLAUDE.md` / `AGENTS.md` files) from a private repo into client
  checkouts without committing it ([client-tooling.md](client-tooling.md)).

### After a fresh install

1. `pass-cli login` — the work profile reads
   `pass://Ahold/TechNLGenAI/{api_key,proxy_url}`.
2. Install the DevAI CLI (a global npm package from the client's
   registry — not managed by Nix), then `devai setup`.
3. The Keychain fix for `pass-cli` ([docs/ssh.md](ssh.md#prerequisites-once-per-mac));
   SSH keys then come from Proton Pass.
4. Check: `cc-work` starts and a prompt goes through; `git config
   user.email` shows the work address; `docker ps` works.

Onboarding runbook (hostname, username, `setup.sh`):
[hosts.md](hosts.md#onboarding-the-work-mac).
