#!/usr/bin/env bash
#
# oc-tooling — apply per-client OpenCode tooling (project agents + nested
# AGENTS.md) into a client repo checkout WITHOUT committing it.
#
# This helper is deliberately client-agnostic and carries NO client content, so
# it is safe to live in the public dotfiles. The actual tooling (which embeds
# client identifiers) lives in a PRIVATE per-client repo, cloned/linked under
# $OC_TOOLING_HOME/<client>/ and laid out as a mirror of the target checkout:
#
#   <client>/
#     shared/tree/...                 # applied to every repo of that client
#     repos/<repo>/tree/...           # applied to that one repo
#
# Every file under a tree/ maps to the same relative path in the live checkout.
# Files are SYMLINKED in (single source of truth; OpenCode follows symlinks for
# agents) and their paths are written into .git/info/exclude inside a marked,
# removable block — so git never sees them and `unapply` is clean.
set -euo pipefail

OC_TOOLING_HOME="${OC_TOOLING_HOME:-$HOME/.opencode-clients}"
MARK_BEGIN="# >>> oc-tooling (local, never commit) >>>"
MARK_END="# <<< oc-tooling <<<"

die() { printf 'oc-tooling: %s\n' "$1" >&2; exit 1; }

client_dir() { # <client>
  local d="$OC_TOOLING_HOME/$1"
  [ -e "$d" ] || die "client '$1' not set up — run: oc-tooling link $1 <path>  (or: oc-tooling clone $1 <url>)"
  printf '%s\n' "$d"
}

repo_root() { git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repo"; }

# Strip an existing oc-tooling block from an exclude file (stdin->stdout).
_strip_block() { awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}'; }

cmd_link() { # <client> <path>
  [ $# -eq 2 ] || die "usage: oc-tooling link <client> <path>"
  [ -d "$2" ] || die "path does not exist: $2"
  mkdir -p "$OC_TOOLING_HOME"
  ln -sfn "$2" "$OC_TOOLING_HOME/$1"
  printf 'linked %s -> %s\n' "$OC_TOOLING_HOME/$1" "$2"
}

cmd_clone() { # <client> <url>
  [ $# -eq 2 ] || die "usage: oc-tooling clone <client> <url>"
  mkdir -p "$OC_TOOLING_HOME"
  git clone "$2" "$OC_TOOLING_HOME/$1"
}

cmd_apply() { # <client>/<repo>
  [ $# -eq 1 ] && [ "${1#*/}" != "$1" ] || die "usage: oc-tooling apply <client>/<repo>"
  local client="${1%%/*}" repo="${1#*/}"
  local cdir root; cdir="$(client_dir "$client")"; root="$(repo_root)"

  local -a trees=()
  [ -d "$cdir/shared/tree" ] && trees+=("$cdir/shared/tree")
  [ -d "$cdir/repos/$repo/tree" ] && trees+=("$cdir/repos/$repo/tree")
  [ ${#trees[@]} -gt 0 ] || die "no tooling for $client/$repo under $cdir (expected shared/tree or repos/$repo/tree)"

  local -a rels=()
  local tree f rel dest
  for tree in "${trees[@]}"; do
    while IFS= read -r -d '' f; do
      rel="${f#"$tree"/}"
      dest="$root/$rel"
      mkdir -p "$(dirname "$dest")"
      ln -sfn "$f" "$dest"
      rels+=("$rel")
      printf '  + %s\n' "$rel"
    done < <(find "$tree" -type f -print0)
  done

  local excl="$root/.git/info/exclude"
  mkdir -p "$(dirname "$excl")"; touch "$excl"
  { _strip_block <"$excl"; printf '%s\n' "$MARK_BEGIN"; printf '/%s\n' "${rels[@]}"; printf '%s\n' "$MARK_END"; } >"$excl.tmp"
  mv "$excl.tmp" "$excl"
  printf 'applied %s/%s — %d file(s) symlinked, excluded locally\n' "$client" "$repo" "${#rels[@]}"
}

cmd_unapply() {
  local root excl; root="$(repo_root)"; excl="$root/.git/info/exclude"
  [ -f "$excl" ] || { printf 'nothing applied\n'; return 0; }
  local line rel dest in=0 n=0
  while IFS= read -r line; do
    [ "$line" = "$MARK_BEGIN" ] && { in=1; continue; }
    [ "$line" = "$MARK_END" ] && { in=0; continue; }
    [ $in -eq 1 ] || continue
    rel="${line#/}"; dest="$root/$rel"
    if [ -L "$dest" ]; then rm -f "$dest"; printf '  - %s\n' "$rel"; n=$((n+1)); fi
  done < "$excl"
  _strip_block <"$excl" >"$excl.tmp"; mv "$excl.tmp" "$excl"
  printf 'unapplied — %d symlink(s) removed, exclude block cleared\n' "$n"
}

cmd_status() {
  local root excl; root="$(repo_root)"; excl="$root/.git/info/exclude"
  [ -f "$excl" ] || { printf 'nothing applied\n'; return 0; }
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{on=1;next} $0==e{on=0} on{print "  " $0}' "$excl"
}

cmd_list() {
  [ -d "$OC_TOOLING_HOME" ] || { printf 'no clients set up (%s)\n' "$OC_TOOLING_HOME"; return 0; }
  local d r
  for d in "$OC_TOOLING_HOME"/*; do
    [ -e "$d" ] || continue
    printf '%s\n' "$(basename "$d")"
    [ -d "$d/repos" ] && for r in "$d"/repos/*; do [ -d "$r" ] && printf '  %s\n' "$(basename "$r")"; done
  done
}

main() {
  local sub="${1:-}"; [ $# -gt 0 ] && shift
  case "$sub" in
    link)    cmd_link "$@" ;;
    clone)   cmd_clone "$@" ;;
    apply)   cmd_apply "$@" ;;
    unapply) cmd_unapply "$@" ;;
    status)  cmd_status "$@" ;;
    list)    cmd_list "$@" ;;
    *) die "usage: oc-tooling {link <client> <path> | clone <client> <url> | apply <client>/<repo> | unapply | status | list}" ;;
  esac
}

main "$@"
