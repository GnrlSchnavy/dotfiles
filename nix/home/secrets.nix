# Proton Pass secret resolution — shared across all hosts.
#
# The rule this module exists to enforce: `pass://` REFERENCES may live in
# these (public) dotfiles; resolved VALUES may never touch git or /nix/store.
# Everything home-manager writes ends up in the Nix store, which is
# world-readable 0755 — so a secret placed in a `home.file` is a secret
# published to every user and process on the machine.
#
# Resolution therefore happens at RUNTIME, in the user's interactive shell,
# never at build or activation time:
#   - the Nix build sandbox has no network and no Proton Pass session;
#   - `darwin-rebuild` activation is non-interactive and runs partly as root,
#     so pass-cli there would hang on a login prompt or fail outright.
# "Declarative" here means the reference and the recipe are versioned; the
# materialisation stays an explicit command you run (`pass-render`, `oc-work`).
#
# Do NOT call these helpers at shell startup — each one is a network round
# trip and would add latency to every new terminal. Call them from functions
# that need a secret, at the moment they need it.
#
# The three helpers wrap the three pass-cli primitives worth standardising:
#
#   pass-check              assert a usable session (precondition for the rest)
#   pass-get <ref>          one value -> stdout            (pass-cli item view)
#   pass-render <t> <dest>  a whole file from a template   (pass-cli inject)
#
# For env-var injection into a child process there is a fourth primitive,
# `pass-cli run -- <cmd>`, which needs no wrapper — use it directly.
#
# See docs/secrets.md for the naming convention and the vault-rename hazard.
{ lib, ... }:

{
  # mkOrder 1400 places these BEFORE codemem.nix's mkAfter (1500) block, so
  # the helpers are defined above their first consumer in ~/.zshrc. Function
  # definition order doesn't strictly matter in zsh (bodies resolve at call
  # time), but keeping the file readable top-to-bottom is worth the ordering.
  programs.zsh.initContent = lib.mkOrder 1400 ''
    # ── Proton Pass secret helpers (see nix/home/secrets.nix) ──

    # Assert pass-cli is installed and holds a live session. Every helper
    # calls this first so a missing login surfaces as one actionable line
    # instead of a stack of pass-cli errors.
    pass-check() {
      if ! command -v pass-cli >/dev/null 2>&1; then
        print -u2 "pass-check: pass-cli not found (brew: protonpass/tap/pass-cli)"
        return 1
      fi
      if ! pass-cli info >/dev/null 2>&1; then
        print -u2 "pass-check: no Proton Pass session — run 'pass-cli login'"
        return 1
      fi
    }

    # pass-get pass://Vault/Item/field
    #
    # Print one secret to stdout. Fails CLOSED: on any error nothing is
    # written to stdout and the status is non-zero, so the caller idiom
    #   key="$(pass-get 'pass://V/I/f')" || return 1
    # can never silently proceed with an empty credential.
    pass-get() {
      local ref="$1"
      if [[ -z "$ref" ]]; then
        print -u2 "pass-get: usage: pass-get pass://Vault/Item/field"
        return 2
      fi
      pass-check || return 1

      local value
      if ! value="$(pass-cli item view "$ref" 2>/dev/null)"; then
        print -u2 "pass-get: could not resolve $ref"
        return 1
      fi
      if [[ -z "$value" ]]; then
        print -u2 "pass-get: $ref resolved to an empty value"
        return 1
      fi
      print -r -- "$value"
    }

    # pass-render <template> <destination>
    #
    # Render a template containing {{ pass://Vault/Item/field }} references
    # into a 0600 file. Writes to a temp file in the destination directory
    # and renames on success, so a failed render (expired session, renamed
    # vault, typo'd ref) leaves any existing working config untouched rather
    # than truncating it.
    pass-render() {
      local tmpl="$1" dest="$2"
      if [[ -z "$tmpl" || -z "$dest" ]]; then
        print -u2 "pass-render: usage: pass-render <template> <destination>"
        return 2
      fi
      if [[ ! -r "$tmpl" ]]; then
        print -u2 "pass-render: template not readable: $tmpl"
        return 1
      fi
      pass-check || return 1

      mkdir -p -- "''${dest:h}" || return 1
      # Same directory as dest => the rename below is atomic.
      local tmp="''${dest}.pass-render.$$"
      if ! pass-cli inject --force --file-mode 0600 -i "$tmpl" -o "$tmp"; then
        rm -f -- "$tmp"
        print -u2 "pass-render: failed to render $tmpl ($dest left unchanged)"
        return 1
      fi
      if ! mv -f -- "$tmp" "$dest"; then
        rm -f -- "$tmp"
        print -u2 "pass-render: could not move rendered file into $dest"
        return 1
      fi
      print -u2 "pass-render: wrote $dest (0600)"
    }
  '';
}
