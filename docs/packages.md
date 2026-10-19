# Package management

Software comes from three sources, all declared **per profile** under
`nix/profiles/<role>/` — `dev` for every machine, `personal` or `work`
for one role ([nix/profiles/README.md](../nix/profiles/README.md)).
This doc is the single source of truth for which source to use.

## Decision matrix

| Tool type | Nix (`nix/profiles/<role>/packages.nix`) | Homebrew (`nix/profiles/<role>/homebrew.nix`) | Mac App Store (`masApps`) |
|---|---|---|---|
| CLI development tools | ✅ preferred | only if not in nixpkgs / needs a tap | never |
| GUI applications | never | ✅ casks | only if App-Store-exclusive |
| Language runtimes (Java, Node) | via mise (`nix/home/mise.nix`) | never | never |
| System utilities | ✅ preferred | if macOS-specific | rarely |

Rules of thumb:

- **Nix packages** (`environment.systemPackages`): CLI tools by
  default — git, jq, ripgrep, kubectl, helm, gh, tmux, gnupg, kotlin,
  pnpm, ansible, nmap…
- **Homebrew brews**: only with a reason, written next to the entry —
  an official tap (`fluxcd/tap/flux`, which also tracks the cluster's
  controller releases; `protonpass/tap/pass-cli`), a release cycle
  stable nixpkgs can't keep up with (`opencode`, `openspec`), or a
  build that doesn't fit Nix (`clamav`'s writable config and database).
- **Homebrew casks**: all GUI apps (browsers, IDEs, Slack, …). JDKs are
  not casks — mise installs them. Docker is not a cask either: the
  engine is Colima and the `docker` CLI comes from nixpkgs
  (`nix/profiles/dev/docker.nix`).
- **masApps**: currently unused on every host; available if an app is
  App-Store-only.
- **Which profile**: `dev` if every machine needs it, `personal` /
  `work` if only that role does. An app both roles want but not every
  dev machine would (Slack) is listed in each.
- One tool, one source — never declare the same tool in both Nix and
  Homebrew.

## Language runtimes are NOT nix-managed

Java and Node come from **mise**, so each project can pin its own
version. mise itself and its global config are declared in
[`nix/home/mise.nix`](../nix/home/mise.nix) (global: Temurin 25 as the
default and Temurin 21, Node LTS); the runtimes are downloaded by mise into `~/.local/share/mise`,
by an activation step on every rebuild (a no-op once installed; offline
it only warns).

- **Per project**, mise reads `mise.toml` and the files other tools use:
  `.java-version`, `.sdkmanrc`, `.nvmrc`, `.node-version`. `cd`-ing into
  the project switches `java`/`node` and sets `JAVA_HOME`.
- **Java vendor gotcha:** a bare `21` in `.java-version` means OpenJDK
  21; write `temurin-21` for Temurin.
- **Changing the global versions**: edit the list in `mise.nix` and
  rebuild — `~/.config/mise/config.toml` is a read-only Nix symlink, so
  `mise use -g` can't write it. `mise use` (per project) works as usual.
  - *Add a JDK everywhere* (installed on every machine, in IntelliJ's
    list): add it to `java = [ … ]`, e.g. `"temurin-17"`. The first
    entry is the default `java`; the order of the rest doesn't matter.
  - *A version for one project only*: put it in that project's
    `.java-version` or `mise.toml`, run `mise install` there once, and
    the next rebuild links it for IntelliJ.
  - *Remove one*: drop it from the list. mise keeps the install until
    `mise prune` (which deletes versions no config uses any more); the
    next rebuild then unlinks it.
  - *Patch updates*: `temurin-25` means "the newest 25.x when it was
    installed"; mise doesn't move it on its own. `mise upgrade`
    installs newer patch releases, and the next rebuild relinks them.
- **macOS sees every JDK mise installed**: each rebuild links them into
  `~/Library/Java/JavaVirtualMachines/mise-<version>.jdk`, so
  `/usr/libexec/java_home -V`, IntelliJ's JDK list and Gradle toolchains
  find them. A JDK a project installs between rebuilds is linked on the
  next rebuild; one mise removes is unlinked then too.
- **Python**: *not centrally managed.* pyenv was removed from the
  config (June 2026); don't re-add pyenv references to shell config,
  scripts, or docs. If a project needs Python, manage it per-project.

mise hooks itself into the shell — see
[shell-and-dotfiles.md](shell-and-dotfiles.md).

## Adding / removing a package

```bash
# CLI tool from nixpkgs — every machine (dev) or one role (personal)
$EDITOR nix/profiles/dev/packages.nix

# GUI app or brew formula — dev, personal or work
$EDITOR nix/profiles/dev/homebrew.nix

# Stage (flakes only see git-tracked changes), then apply
git add -A
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Keep the existing comment-grouped categories in `homebrew.nix`
(Browsers / Communication / Productivity / Development / …) and add
new entries alphabetically within their group.

## ⚠️ cleanup = "zap"

[`nix/modules/homebrew.nix`](../nix/modules/homebrew.nix) sets, for
every host:

```nix
homebrew.onActivation = {
  cleanup = "zap";   # uninstall (and purge) anything not declared
  autoUpdate = true;
  upgrade = true;
};
```

Consequences:

- Anything installed with plain `brew install` and not added to one of
  the host's profiles' `homebrew.nix` is **uninstalled on the next
  rebuild**.
- Removing an entry from `homebrew.nix` actively zaps it (including
  preferences) at the next rebuild — that's the intended way to remove
  software. Moving one between profiles removes it from hosts without
  the target profile.
- The `ci` host force-overrides `cleanup = "none"` and
  `upgrade = false` so it doesn't fight the runner image.

## Gotchas

- Docker Desktop was replaced by Colima (October 2026). After the first
  rebuild without it, the cask is zapped; Colima's VM is separate.
- `warp` is the **Warp terminal**; the Cloudflare VPN cask is
  `cloudflare-warp`. Don't confuse them.
- nvim is not in any `packages.nix` — it's injected per-host by
  `mkNvim` in `nix/flake.nix`.
- `nixpkgs.config.allowUnfree = true` is set once in
  `nix/modules/nix.nix`; don't repeat it per profile.
- The CI smoke check (`.github/workflows/check.yml`) asserts the
  formulas `flux`, `pass-cli` exist after activation and that
  `kubectl`, `helm`, `gh` are on PATH. If you move or remove one of
  those, update the workflow too (ci mirrors m5's profiles).
