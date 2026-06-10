# Package management

Software comes from three sources, all declared **per-host** under
`nix/hosts/<name>/`. This doc is the single source of truth for which
source to use (it supersedes the old `nix/PACKAGE-STRATEGY.md`).

## Decision matrix

| Tool type | Nix (`packages.nix`) | Homebrew (`homebrew.nix`) | Mac App Store (`masApps`) |
|---|---|---|---|
| CLI development tools | ✅ preferred | only if not in nixpkgs / needs a tap | never |
| GUI applications | never | ✅ casks | only if App-Store-exclusive |
| Version managers (jenv, nvm) | avoid | ✅ brews (need shell integration) | never |
| System utilities | ✅ preferred | if macOS-specific | rarely |

Rules of thumb:

- **Nix packages** (`environment.systemPackages`): reproducible CLI
  tools — git, maven, jq, ripgrep, fd, bat, tree, curl, wget, htop…
- **Homebrew brews**: CLI tools that need taps (`fluxcd/tap/flux`),
  shell integration (jenv, nvm, autojump), or faster update cycles
  (gh, kubectl, helm).
- **Homebrew casks**: all GUI apps (browsers, IDEs, Slack, Docker
  Desktop, …) and the `temurin@25` JDK.
- **masApps**: currently unused on every host; available if an app is
  App-Store-only.
- One tool, one source — never declare the same tool in both Nix and
  Homebrew.

## Language runtimes are NOT nix-managed

Java and Node live behind version managers so each project can pin its
own version:

- **Java**: `jenv` (brew) + JDKs from casks (`temurin@25`). Bootstrap:
  `jenv add /Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home && jenv global temurin-25`.
- **Node**: `nvm` (brew). Bootstrap: `nvm install --lts`.
- **Python**: *not centrally managed.* pyenv was removed from the
  config (June 2026); don't re-add pyenv references to shell config,
  scripts, or docs. If a project needs Python, manage it per-project.

Both jenv and nvm are lazy-loaded in
[`nix/home/zsh.nix`](../nix/home/zsh.nix) — see
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

Both real hosts set:

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
  formulas `jenv`, `kubectl`, `helm` exist after activation. If you
  remove one of those from **m4**'s brews, update the workflow too
  (ci mirrors m4's modules).
