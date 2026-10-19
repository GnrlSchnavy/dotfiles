# The personal Obsidian vault: the vault-* Claude skills and the notes/note
# shell functions (zsh.nix) read it.
{ config, pkgs, ... }:

let
  vault = "${config.home.homeDirectory}/Documents/Obsidian/Yvan_claude";

  # The skills name the vault as @VAULT@; fill in this machine's path.
  skills = pkgs.runCommand "claude-skills" { } ''
    cp -r ${../../../system/.claude/skills} $out
    chmod -R u+w $out
    find $out -name '*.md' -exec sed -i 's|@VAULT@|${vault}|g' {} +
    if grep -rq '@VAULT@' $out; then echo "unsubstituted @VAULT@" >&2; exit 1; fi
  '';
in
{
  home.sessionVariables.OBSIDIAN_VAULT = vault;
  home.file.".claude/skills".source = skills;
}
