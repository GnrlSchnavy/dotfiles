# Development apps, on every machine. GUI apps are casks; CLI tools come
# from nixpkgs unless they need a tap or a faster release cycle
# (docs/packages.md).
{ ... }:

{
  homebrew = {
    casks = [
      # Browsers
      "brave-browser"
      "firefox"
      "google-chrome"

      # Productivity
      "alfred"
      "obsidian"
      "rectangle"

      # Development
      "chromedriver"
      "claude"
      "claude-code"
      "intellij-idea"
      "visual-studio-code"
      "warp"
    ];

    # CLI tools come from nixpkgs (packages.nix); these stay in Homebrew
    # for a reason given per entry.
    brews = [
      # Official taps, not in core Homebrew.
      # Flux CLI: tracks the cluster's controller releases, which stable
      # nixpkgs lags behind.
      "fluxcd/tap/flux"
      # Proton Pass CLI: brew owns updates (its own `pass-cli update` is
      # disabled under Homebrew); onActivation.upgrade picks up new versions.
      "protonpass/tap/pass-cli"

      # AI coding tools that release about weekly; stable nixpkgs lags.
      "opencode"
      "openspec"
    ];
  };
}
