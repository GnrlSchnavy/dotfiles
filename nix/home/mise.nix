# Language runtimes (Java, Node) via mise — shared across all hosts.
#
# mise and its global config are declared here; the runtimes themselves are
# downloaded by mise into ~/.local/share/mise, by the activation step below
# on every rebuild. Runtimes stay out of Nix so each project can pin its own
# version.
#
# Per project, mise reads mise.toml plus the version files other tools use:
# .java-version, .sdkmanrc, .nvmrc, .node-version (idiomatic files are off by
# default in mise; enabled below for java and node). In .java-version a bare
# "21" means OpenJDK 21 — write "temurin-21" for Temurin. Entering a project
# directory switches java/node on PATH and sets JAVA_HOME.
#
# ~/.config/mise/config.toml is a read-only Nix symlink: change the global
# versions here, not with `mise use -g`.
{ config, lib, ... }:

{
  programs.mise = {
    enable = true;
    # Use the stock package: on nixpkgs 26.05 mise and its direnv are in the
    # binary cache. (On 25.11 they weren't, and building direnv locally failed:
    # its test suite runs fish, whose cached binary has an invalid code
    # signature, so macOS kills it. Overriding the package forces that build.)
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

  # Install the global versions on every rebuild, so no machine needs a
  # manual `mise install`; once they're there it's a quick no-op. Run from /
  # so a mise.toml in the directory you rebuild from isn't picked up. It
  # needs network the first time, so a failure only warns.
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe config.programs.mise.package} --cd / install --yes \
      || echo "mise install failed (offline?); the next rebuild retries" >&2
  '';

  # Lets macOS see mise's JDKs: /usr/libexec/java_home, and the tools that ask
  # it (IntelliJ's JDK detection, Gradle/Maven toolchains), scan
  # ~/Library/Java/JavaVirtualMachines. Each installed JDK gets a
  # mise-<version>.jdk there whose Contents links into mise's install (the
  # layout mise documents; java_home skips a symlinked .jdk itself). Rebuilt
  # from scratch every time, so JDKs mise drops disappear too. Per user, so
  # no sudo; JDKs a project installs later are linked on the next rebuild.
  home.activation.miseJdkLinks = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    jvms="$HOME/Library/Java/JavaVirtualMachines"
    run mkdir -p "$jvms"
    for jdk in "$jvms"/mise-*.jdk; do
      if [ -e "$jdk" ] || [ -L "$jdk" ]; then run rm -rf "$jdk"; fi
    done
    for dir in "$HOME"/.local/share/mise/installs/java/*; do
      # Skip mise's version aliases (symlinks) and non-macOS layouts.
      if [ -L "$dir" ] || [ ! -f "$dir/Contents/Info.plist" ]; then continue; fi
      link="$jvms/mise-''${dir##*/}.jdk"
      run mkdir -p "$link"
      run ln -s "$dir/Contents" "$link/Contents"
    done
  '';
}
