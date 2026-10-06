# Zsh configuration.
#
# Typed home-manager options where they exist (history, suggestions,
# highlighting, fzf, zoxide); the imperative rest (conditional
# completions, shell functions) stays as raw strings in profileExtra
# (.zprofile) and initContent (.zshrc).
{ ... }:

{
  programs.zsh = {
    enable = true;

    # Same file as before (~/.zsh_history), bigger and shared live across
    # open shells; a command typed with a leading space isn't saved.
    history = {
      size = 100000;
      save = 100000;
      share = true;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    # Grey inline suggestion from history (→ accepts); commands coloured
    # as you type.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # zoxide replaced autojump; `j` keeps working.
    shellAliases.j = "z";

    # Login shell init (was shell/.zprofile under Stow).
    profileExtra = ''
      # Homebrew environment setup
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    # Interactive shell init (was shell/.zshrc under Stow).
    # Imperative because completions need dynamic state. Java and Node come
    # from mise (mise.nix), which hooks itself into this file.
    initContent = ''
      # Kubectl shell completion, cached for a day for faster startup.
      # Skipped without kubectl, so an empty cache can't stick around.
      if (( $+commands[kubectl] )); then
        if [[ ! -s ~/.zsh_kubectl_completion ]] || [[ $(date -r ~/.zsh_kubectl_completion +%s) -lt $(( $(date +%s) - 86400 )) ]]; then
          kubectl completion zsh >| ~/.zsh_kubectl_completion 2>/dev/null
        fi
        [[ -s ~/.zsh_kubectl_completion ]] && source ~/.zsh_kubectl_completion
      fi

      export PATH="$HOME/.local/bin:$PATH"

      # Obsidian CLI on PATH
      export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

      # Quick note editing: open nvim in the notes directory straight
      # into the fuzzy file finder. Uses the Obsidian vault ($OBSIDIAN_VAULT,
      # files.nix) when present, ~/notes otherwise. Override with NOTES_DIR.
      notes() {
        local dir="''${NOTES_DIR:-$OBSIDIAN_VAULT}"
        [ -d "$dir" ] || dir="$HOME/notes"
        mkdir -p "$dir"
        ( cd "$dir" && nvim "+Telescope find_files" )
      }

      # Quick capture: `note` opens today's fleeting note
      # (05 - Fleeting/<date>.md), `note foo` opens/creates foo.md there.
      note() {
        local dir="''${NOTES_DIR:-$OBSIDIAN_VAULT}"
        [ -d "$dir" ] || dir="$HOME/notes"
        local fleeting="$dir/05 - Fleeting"
        [ -d "$fleeting" ] || fleeting="$dir"
        mkdir -p "$fleeting"
        local name="''${1:-$(date +%Y-%m-%d)}"
        ( cd "$dir" && nvim "$fleeting/$name.md" )
      }
    '';
  };

  # Ctrl-R fuzzy history search, Ctrl-T files, Alt-C directories.
  programs.fzf.enable = true;

  # Frecency-ranked `cd`: `z proj` (and `j proj`). Import autojump's
  # history once: zoxide import --from=autojump ~/Library/autojump/autojump.txt
  programs.zoxide.enable = true;
}
