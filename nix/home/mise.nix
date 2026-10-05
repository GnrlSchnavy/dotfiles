# Language runtimes (Java, Node) via mise — shared across all hosts.
#
# mise and its global config are declared here; the runtimes themselves are
# downloaded by mise into ~/.local/share/mise (`mise install` once per
# machine). Runtimes stay out of Nix so each project can pin its own version.
#
# Per project, mise reads mise.toml plus the version files other tools use:
# .java-version, .sdkmanrc, .nvmrc, .node-version (idiomatic files are off by
# default in mise; enabled below for java and node). In .java-version a bare
# "21" means OpenJDK 21 — write "temurin-21" for Temurin. Entering a project
# directory switches java/node on PATH and sets JAVA_HOME.
#
# ~/.config/mise/config.toml is a read-only Nix symlink: change the global
# versions here, not with `mise use -g`.
{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      tools = {
        java = "temurin-25";
        # codemem's hooks and MCP server need Node 24.15+.
        node = "lts";
      };
      settings.idiomatic_version_file_enable_tools = [ "java" "node" ];
    };
  };

  # Shims cover non-interactive callers that never run `mise activate`
  # (Claude Code hooks, IDE run configs, `zsh -c`).
  home.sessionPath = [ "$HOME/.local/share/mise/shims" ];
}
