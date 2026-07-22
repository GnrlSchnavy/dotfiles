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

      # Quick note editing: open nvim in the notes directory straight
      # into the fuzzy file finder. Uses the Obsidian vault when present,
      # ~/notes otherwise. Override with NOTES_DIR.
      notes() {
        local dir="''${NOTES_DIR:-$HOME/Documents/Obsidian/Yvan_claude}"
        [ -d "$dir" ] || dir="$HOME/notes"
        mkdir -p "$dir"
        ( cd "$dir" && nvim "+Telescope find_files" )
      }

      # Quick capture: `note` opens today's fleeting note
      # (05 - Fleeting/<date>.md), `note foo` opens/creates foo.md there.
      note() {
        local dir="''${NOTES_DIR:-$HOME/Documents/Obsidian/Yvan_claude}"
        [ -d "$dir" ] || dir="$HOME/notes"
        local fleeting="$dir/05 - Fleeting"
        [ -d "$fleeting" ] || fleeting="$dir"
        mkdir -p "$fleeting"
        local name="''${1:-$(date +%Y-%m-%d)}"
        ( cd "$dir" && nvim "$fleeting/$name.md" )
      }
    '';
  };

  # Static env vars used above. Set via home-manager so they're available
  # to all shells, not just interactive ones.
  home.sessionVariables = {
    BUN_INSTALL = "$HOME/.bun";
    NVM_DIR = "$HOME/.nvm";
  };
}
