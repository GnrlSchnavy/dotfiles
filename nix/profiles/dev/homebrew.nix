# Development apps and CLI tools, on every machine. Use Homebrew when a tool
# isn't in nixpkgs or needs a tap (docs/packages.md).
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
      "lens"
      "visual-studio-code"
      "warp"
    ];

    brews = [
      # Programming languages
      "kotlin"

      # Security
      "gnupg"
      # Proton Pass CLI — official tap, not in core Homebrew. brew owns
      # updates (its own `pass-cli update` is disabled under Homebrew);
      # onActivation.upgrade picks up new versions on rebuild.
      "protonpass/tap/pass-cli"

      # Kubernetes ecosystem
      "fluxcd/tap/flux"
      "helm"
      "kdoctor"
      "kubectl"
      "kubeseal"

      # Shell enhancements (directory jumping is zoxide, from nixpkgs)
      "tmux"

      # Development utilities
      "gh"
      "opencode"
      "openspec"
      "pnpm"
    ];
  };
}
