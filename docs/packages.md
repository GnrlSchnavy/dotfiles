# Package management

Software comes from three sources, all declared **per-host** under
`nix/hosts/<name>/`. This doc is the single source of truth for which
source to use (it supersedes the old `nix/PACKAGE-STRATEGY.md`).

## Decision matrix

| Tool type | Nix (`packages.nix`) | Homebrew (`homebrew.nix`) | Mac App Store (`masApps`) |
|---|---|---|---|
| CLI development tools | ✅ preferred | only if not in nixpkgs / needs a tap | never |
| GUI applications | never | ✅ casks | only if App-Store-exclusive |
| Language runtimes (Java, Node) | via mise (`nix/home/mise.nix`) | never | never |
| System utilities | ✅ preferred | if macOS-specific | rarely |

Rules of thumb:

- **Nix packages** (`environment.systemPackages`): reproducible CLI
  tools — git, maven, jq, ripgrep, fd, bat, tree, curl, wget, htop…
- **Homebrew brews**: CLI tools that need taps (`fluxcd/tap/flux`),
  or faster update cycles
  (gh, kubectl, helm).
- **Homebrew casks**: all GUI apps (browsers, IDEs, Slack, Docker
  Desktop, …). JDKs are not casks — mise installs them.
- **masApps**: currently unused on every host; available if an app is
  App-Store-only.
- One tool, one source — never declare the same tool in both Nix and
  Homebrew.

## Language runtimes are NOT nix-managed

Java and Node come from **mise**, so each project can pin its own
version. mise itself and its global config are declared in
[`nix/home/mise.nix`](../nix/home/mise.nix) (global: Temurin 25, Node
LTS); the runtimes are downloaded by mise into `~/.local/share/mise`,
by an activation step on every rebuild (a no-op once installed; offline
it only warns).

- **Per project**, mise reads `mise.toml` and the files other tools use:
  `.java-version`, `.sdkmanrc`, `.nvmrc`, `.node-version`. `cd`-ing into
  the project switches `java`/`node` and sets `JAVA_HOME`.
- **Java vendor gotcha:** a bare `21` in `.java-version` means OpenJDK
  21; write `temurin-21` for Temurin.
- **Changing the global versions**: edit `mise.nix` and rebuild —
  `~/.config/mise/config.toml` is a read-only Nix symlink, so
  `mise use -g` can't write it. `mise use` (per project) works as usual.
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
# CLI tool from nixpkgs — THIS machine's list
$EDITOR nix/hosts/$(scutil --get LocalHostName)/packages.nix

# GUI app or brew formula
$EDITOR nix/hosts/$(scutil --get LocalHostName)/homebrew.nix

# Stage (flakes only see git-tracked changes), then apply
git add -A
sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v
```

Keep the existing comment-grouped categories in `homebrew.nix`
(Browsers / Communication / Productivity / Development / …) and add
new entries alphabetically within their group.

## ⚠️ cleanup = "zap"

The host (`m5`) sets:

```nix
homebrew.onActivation = {
  cleanup = "zap";   # uninstall (and purge) anything not declared
  autoUpdate = true;
  upgrade = true;
};
```

Consequences:

- Anything installed with plain `brew install` and not added to
  `homebrew.nix` is **uninstalled on the next rebuild**.
- Removing an entry from `homebrew.nix` actively zaps it (including
  preferences) at the next rebuild — that's the intended way to remove
  software.
- The `ci` host force-overrides `cleanup = "none"` and
  `upgrade = false` so it doesn't fight the runner image.

## Gotchas

- Cask name is `docker-desktop` (the old `docker` cask was renamed).
- `warp` is the **Warp terminal**; the Cloudflare VPN cask is
  `cloudflare-warp`. Don't confuse them.
- nvim is not in any `packages.nix` — it's injected per-host by
  `mkNvim` in `nix/flake.nix`.
- `nixpkgs.config.allowUnfree = true` is set once in
  `nix/modules/nix.nix`; don't repeat it per host.
- The CI smoke check (`.github/workflows/check.yml`) asserts the
  formulas `kubectl`, `helm` exist after activation. If you
  remove one of those from **m5**'s brews, update the workflow too
  (ci mirrors m5's modules).
