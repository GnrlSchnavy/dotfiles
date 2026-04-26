# Intentionally imperative: version managers and completions require runtime
# shell function wrappers that cannot be expressed in nix-darwin.
# Declarative config (aliases, env vars, PATH) lives in nix/modules/environment.nix

# Java version management with jenv - lazy-loaded for faster shell startup
export PATH="$HOME/.jenv/bin:$PATH"
lazy_load_jenv() {
  unset -f jenv java javac
  eval "$(jenv init -)"
}
jenv() { lazy_load_jenv && jenv "$@"; }
java() { lazy_load_jenv && java "$@"; }
javac() { lazy_load_jenv && javac "$@"; }
# Eagerly set JAVA_HOME so ./mvnw forks the correct JDK before jenv lazy-loads
export JAVA_HOME="$HOME/.jenv/versions/$(cat .java-version 2>/dev/null || cat $HOME/.jenv/version 2>/dev/null || echo 24)"

# Kubectl shell completion - cached for faster shell startup
if [[ ! -f ~/.zsh_kubectl_completion ]] || [[ $(date -r ~/.zsh_kubectl_completion +%s) -lt $(( $(date +%s) - 86400 )) ]]; then
  kubectl completion zsh > ~/.zsh_kubectl_completion 2>/dev/null
fi
[ -f ~/.zsh_kubectl_completion ] && source ~/.zsh_kubectl_completion
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/yvan/.bun/_bun" ] && source "/Users/yvan/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/Users/yvan/.bun/bin/bun "/Users/yvan/.claude/plugins/cache/thedotmack/claude-mem/12.3.8/scripts/worker-service.cjs"'
