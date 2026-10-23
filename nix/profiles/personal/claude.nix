# Claude Code, personal: signed in to Claude Max (desktop app or `claude`),
# Bash always sandboxed, codemem extracting via Max. The plumbing is in
# nix/home/claude-code.nix and codemem.nix; this module only sets options.
{ config, pkgs, ... }:

let
  dotfilesLintTools = pkgs.buildEnv {
    name = "dotfiles-lint-tools";
    paths = import ../../lint-tools.nix pkgs;
  };
in
{
  dotfiles.codemem = {
    lane = "personal";
    observer = {
      observer_runtime = "claude_sidecar";
      observer_model = "claude-haiku-4-5";
    };
  };

  dotfiles.claude.settings = {
    # The dotfiles' lint tools, for the pre-commit hook in the Bash sandbox,
    # where `nix develop` can't run (.githooks/pre-commit).
    env.DOTFILES_LINT_PATH = "${dotfilesLintTools}/bin";

    # The Bash sandbox (macOS Seatbelt). Sandbox paths are plain absolute or
    # ~/ — not the // form permission rules use. Builds still need their
    # caches and registries.
    union.sandbox = {
      filesystem.allowWrite = [
        "~/.m2"
        "~/.gradle"
        "~/.npm"
      ];
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
        # Lets sandboxed commands bind and connect to localhost, e.g. tests
        # reaching a container's published ports. Without it only the sandbox
        # proxy is reachable on localhost.
        network.allowLocalBinding = true;
        # The Docker engine (nix/profiles/dev/docker.nix). Its containers
        # have their own network and write ~/projects: an accepted risk, as
        # the sandbox holds no secrets. Owned outright, like sandbox-git.nix's
        # socket, so a dropped socket leaves the sandbox.
        network.allowUnixSockets = [
          "${config.home.homeDirectory}/${config.services.colima.colimaHomeDir}/default/docker.sock"
        ];
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
