# Zsh configuration.
#
# Typed home-manager options where they exist (history, suggestions,
# highlighting, fzf, zoxide); the imperative rest (conditional
# completions, shell functions) stays as raw strings in profileExtra
# (.zprofile) and initContent (.zshrc).
{
  config,
  lib,
  osConfig,
  ...
}:

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
      eval "$(${osConfig.homebrew.prefix}/bin/brew shellenv)"
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

      # Inside Claude Code's sandbox, NO_PROXY (hardcoded there) sends the
      # private k3s API past the proxy, where the sandbox blocks it. Drop it
      # so kubectl/flux go through the proxy (the API is in allowedDomains,
      # nix/profiles/personal/claude.nix). A no-op everywhere else.
      kubectl() {
        if [[ -n $SANDBOX_RUNTIME ]]; then env -u NO_PROXY -u no_proxy kubectl "$@"
        else command kubectl "$@"; fi
      }
      flux() {
        if [[ -n $SANDBOX_RUNTIME ]]; then env -u NO_PROXY -u no_proxy flux "$@"
        else command flux "$@"; fi
      }

      # Appended, so a stray tool there (an old native `claude` install, say)
      # can't shadow the Homebrew or Nix one.
      export PATH="$PATH:$HOME/.local/bin"

      # Obsidian CLI on PATH
      export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"

      # The dotfiles' master only takes PRs (docs/ci.md#master-is-protected).
      # `dotpr [branch]` turns your commits into one: commits made on master
      # move to a new branch (master goes back to origin's), the branch is
      # pushed and gh opens the PR. Merge it on GitHub once CI is green.
      dotpr() {
        if [[ -n $(git status --porcelain --untracked-files=no) ]]; then
          echo "dotpr: commit or stash your changes first" >&2; return 1
        fi
        local branch=$(git branch --show-current)
        if [[ $branch == master ]]; then
          git fetch -q origin master || return 1
          if [[ -z $(git log --oneline origin/master..HEAD) ]]; then
            echo "dotpr: no commits on master that origin doesn't have" >&2; return 1
          fi
          branch=''${1:-change-$(date +%Y%m%d-%H%M)}
          git switch -c "$branch" && git branch -f master origin/master || return 1
        fi
        git push -u origin "$branch" && gh pr create --fill --base master --head "$branch"
      }

      # Quick note editing: open nvim in the notes directory straight
      # into the fuzzy file finder. Uses the Obsidian vault ($OBSIDIAN_VAULT,
      # profiles/personal/vault.nix) when present, ~/notes otherwise.
      # Override with NOTES_DIR.
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

  # Frecency-ranked `cd`: `z proj` (and `j proj`).
  programs.zoxide.enable = true;

  # Carries autojump's history over the first time: only while zoxide has
  # no database yet, so it never runs twice.
  home.activation.zoxideFromAutojump = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    aj="$HOME/Library/autojump/autojump.txt"
    if [ -s "$aj" ] && [ ! -e "$HOME/Library/Application Support/zoxide/db.zo" ]; then
      run ${lib.getExe config.programs.zoxide.package} import --from=autojump "$aj"
    fi
  '';
}
