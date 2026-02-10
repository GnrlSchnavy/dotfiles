# Java version management with jenv - lazy-loaded for faster shell startup
export PATH="$HOME/.jenv/bin:$PATH"
lazy_load_jenv() {
  unset -f jenv java javac
  eval "$(jenv init -)"
}
jenv() { lazy_load_jenv && jenv "$@"; }
java() { lazy_load_jenv && java "$@"; }
javac() { lazy_load_jenv && javac "$@"; }

# Kubectl shell completion - cached for faster shell startup
if [[ ! -f ~/.zsh_kubectl_completion ]] || [[ $(date -r ~/.zsh_kubectl_completion +%s) -lt $(( $(date +%s) - 86400 )) ]]; then
  kubectl completion zsh > ~/.zsh_kubectl_completion 2>/dev/null
fi
[ -f ~/.zsh_kubectl_completion ] && source ~/.zsh_kubectl_completion
