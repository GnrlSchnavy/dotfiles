# Nix Modules

System-level (`nix-darwin`) modules **shared by every host** — imported
by [`flake.nix`](../flake.nix) into every `darwinConfiguration` via
`sharedModules`:

- **`system.nix`** — macOS defaults: keyboard remap (caps→esc),
  screensaver, login window, finder, global UI/keyboard/sound settings.
- **`environment.nix`** — system-wide env vars (`EDITOR`, `VISUAL`)
  and kubectl shell aliases.
- **`nix.nix`** — nix daemon settings, `allowUnfree`, weekly GC of
  >30-day generations, automatic store dedup.
- **`homebrew-trust.nix`** — runs `brew trust` during activation for
  every third-party tap the host declares, which Homebrew requires
  before it loads their formulae.

Machine-specific modules (`homebrew.nix`, `packages.nix`, `dock.nix`,
`git.nix`) live per-host in [`../hosts/<name>/`](../hosts/), not here.

Full documentation: [`docs/architecture.md`](../../docs/architecture.md)
and [`docs/packages.md`](../../docs/packages.md).
