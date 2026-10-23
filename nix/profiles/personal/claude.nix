# Claude Code, personal: signed in to Claude Max (desktop app or `claude`),
# Bash always sandboxed, codemem extracting via Max. The plumbing is in
# nix/home/claude-code.nix and codemem.nix; this module only sets options.
{ config, lib, ... }:

let
  # npm, Gradle and Maven caches for sandboxed commands only. The sandbox
  # may write here and nowhere your own builds, IntelliJ or codemem's npx
  # read from.
  sandboxCaches = "${config.home.homeDirectory}/.cache/claude-sandbox";
in
{
  # ~/.zshenv runs for every command the sandbox starts, with
  # $SANDBOX_RUNTIME set, so wrappers (./mvnw, ./gradlew) and child
  # processes get these too. ~/.m2/settings.xml and ~/.npmrc are still read;
  # ~/.gradle/gradle.properties isn't (it lives in GRADLE_USER_HOME).
  programs.zsh.envExtra = ''
    if [[ -n $SANDBOX_RUNTIME ]]; then
      export npm_config_cache=${sandboxCaches}/npm
      export GRADLE_USER_HOME=${sandboxCaches}/gradle
      export MAVEN_USER_HOME=${sandboxCaches}/m2
      export MAVEN_OPTS="-Dmaven.repo.local=${sandboxCaches}/m2/repository''${MAVEN_OPTS:+ $MAVEN_OPTS}"
    fi
  '';
  home.activation.claudeSandboxCaches = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${sandboxCaches}
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
    # registries; their caches are sandbox-only (sandboxCaches below).
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
        # Lets sandboxed commands bind and connect to localhost, e.g. tests
        # reaching a container's published ports. Without it only the sandbox
        # proxy is reachable on localhost.
        network.allowLocalBinding = true;
        # Owned outright, like the sockets below: union entries never leave,
        # and the build caches this used to allow (~/.m2, ~/.gradle, ~/.npm)
        # must, since code planted there runs outside the sandbox later.
        filesystem.allowWrite = [ sandboxCaches ];
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
