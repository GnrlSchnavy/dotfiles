# Zsh configuration.
#
# Most of this is imperative shell code (lazy-load wrappers, conditional
# completions) that doesn't translate cleanly to home-manager's typed
# options. Kept as raw strings in profileExtra (.zprofile) and
# initContent (.zshrc).
#
# The handful of things that *do* translate (aliases, env vars) are
# declared via the typed options.
{ ... }:

{
  programs.zsh = {
    enable = true;

    # Login shell init (was shell/.zprofile under Stow).
    profileExtra = ''
      # Homebrew environment setup
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # Autojump configuration for smart directory navigation
      [ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

      # NVM (Node Version Manager)
      [ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh
      [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm
    '';

    # Interactive shell init (was shell/.zshrc under Stow).
    # Imperative because version managers and completions need shell
    # function wrappers and dynamic state.
    initContent = ''
      # Java version management with jenv - lazy-loaded for faster shell startup
      export PATH="$HOME/.jenv/bin:$PATH"
      lazy_load_jenv() {
        unset -f jenv java javac
        eval "$(jenv init -)"
      }
      jenv()  { lazy_load_jenv && jenv  "$@"; }
      java()  { lazy_load_jenv && java  "$@"; }
      javac() { lazy_load_jenv && javac "$@"; }
      # Eagerly set JAVA_HOME so ./mvnw forks the correct JDK before jenv lazy-loads
      export JAVA_HOME="$HOME/.jenv/versions/$(cat .java-version 2>/dev/null || cat $HOME/.jenv/version 2>/dev/null || echo 24)"

      # Python version management with pyenv - lazy-loaded for faster shell startup
      export PATH="$PYENV_ROOT/bin:$PATH"
      lazy_load_pyenv() {
        unset -f pyenv python python3 pip pip3
        eval "$(pyenv init - --no-rehash zsh)"
      }
      pyenv()   { lazy_load_pyenv && pyenv   "$@"; }
      python()  { lazy_load_pyenv && python  "$@"; }
      python3() { lazy_load_pyenv && python3 "$@"; }
      pip()     { lazy_load_pyenv && pip     "$@"; }
      pip3()    { lazy_load_pyenv && pip3    "$@"; }

      # Kubectl shell completion - cached for faster shell startup
      if [[ ! -f ~/.zsh_kubectl_completion ]] || [[ $(date -r ~/.zsh_kubectl_completion +%s) -lt $(( $(date +%s) - 86400 )) ]]; then
        kubectl completion zsh > ~/.zsh_kubectl_completion 2>/dev/null
      fi
      [ -f ~/.zsh_kubectl_completion ] && source ~/.zsh_kubectl_completion

      export PATH="$HOME/.local/bin:$PATH"

      # bun completions
      [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

      # bun on PATH
      export PATH="$BUN_INSTALL/bin:$PATH"

      # Obsidian CLI on PATH
      export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
    '';
  };

  # Static env vars used above. Set via home-manager so they're available
  # to all shells, not just interactive ones.
  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
    NVM_DIR = "$HOME/.nvm";
    PYENV_ROOT = "$HOME/.pyenv";
  };
}
