# Claude Code, personal: signed in to Claude Max (desktop app or `claude`),
# Bash always sandboxed, codemem extracting via Max. The plumbing is in
# nix/home/claude-code.nix and codemem.nix; this module only sets options.
{ lib, ... }:

{
  # Client data from the two-lane era (docs/claude-code.md#history) doesn't
  # belong on a personal Mac: every rebuild says so until it's deleted.
  home.activation.workLeftovers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for d in "$HOME/.claude-work" "$HOME"/.codemem/work* "$HOME"/.config/codemem/work*.json; do
      if [ -e "$d" ]; then
        warnEcho "client data from the old work lane is still on this personal Mac: $d (delete it)"
      fi
    done
  '';

  dotfiles.codemem = {
    lane = "personal";
    observer = {
      observer_runtime = "claude_sidecar";
      observer_model = "claude-haiku-4-5";
    };
  };

  dotfiles.claude.settings = {
    # The Bash sandbox (macOS Seatbelt). Sandbox paths are plain absolute or
    # ~/ — not the // form permission rules use. Builds still need their
    # registries; their caches are sandbox-only (claude-code.nix).
    union.sandbox = {
      network.allowedDomains = [
        "repo.maven.apache.org"
        "repo1.maven.org"
        "services.gradle.org"
        "plugins.gradle.org"
        "downloads.gradle.org"
        "registry.npmjs.org"
        "192.168.1.106:6443" # k3s API (kubectl/flux, via the sandbox proxy)
        "api.cloudflare.com" # wrangler
      ];
    };
    set = {
      # Forced on every rebuild: a failed sandboxed command may not be
      # retried outside the sandbox, so the boundary holds in auto mode too.
      sandbox = {
        enabled = true;
        allowUnsandboxedCommands = false;
      };
      # Declared rather than installed by hand: the first interactive session
      # fetches any enabled plugin it doesn't have yet. false disables an
      # installed plugin; a /plugin toggle lasts until the next rebuild.
      enabledPlugins = {
        "superpowers@claude-plugins-official" = true;
        "frontend-design@claude-plugins-official" = true;
        "context7@claude-plugins-official" = true;
        "code-review@claude-plugins-official" = true;
        "code-simplifier@claude-plugins-official" = true;
        "skill-creator@claude-plugins-official" = true;
        "playwright@claude-plugins-official" = true;
        "feature-dev@claude-plugins-official" = true;
        "kotlin-lsp@claude-plugins-official" = true;
        # Not for JVM work.
        "clangd-lsp@claude-plugins-official" = false;
        "swift-lsp@claude-plugins-official" = false;
      };
    };

    # Keep Bash permission prompts as they were (only written when unset).
    default.sandbox.autoAllowBashIfSandboxed = false;
  };
}
