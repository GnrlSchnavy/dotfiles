#!/usr/bin/env bash
#
# cc-tooling — apply per-client Claude Code tooling (project .claude/ agents,
# CLAUDE.md / AGENTS.md files) into a client repo checkout WITHOUT committing it.
#
# This helper is deliberately client-agnostic and carries NO client content, so
# it is safe to live in the public dotfiles. The actual tooling (which embeds
# client identifiers) lives in a PRIVATE per-client repo, cloned/linked under
# $CC_TOOLING_HOME/<client>/ and laid out as a mirror of the target checkout:
#
#   <client>/
#     shared/tree/...                 # applied to every repo of that client
#     repos/<repo>/tree/...           # applied to that one repo
#
# Every file under a tree/ maps to the same relative path in the live checkout.
# Files are SYMLINKED in (single source of truth; Claude Code follows symlinks
# for agents and instruction files) and their paths are written into the repo's
# info/exclude inside a marked, removable block — so git never sees them and
# `unapply` is clean. Existing files are never overwritten: apply refuses when a
# destination exists and isn't one of its own links.
set -euo pipefail

if [ -z "${CC_TOOLING_HOME:-}" ]; then
  CC_TOOLING_HOME="$HOME/.claude-clients"
  [ ! -e "$CC_TOOLING_HOME" ] && [ -e "$HOME/.opencode-clients" ] && CC_TOOLING_HOME="$HOME/.opencode-clients"
fi
# Marker text predates the rename; keep it so blocks applied earlier still unapply.
MARK_BEGIN="# >>> oc-tooling (local, never commit) >>>"
MARK_END="# <<< oc-tooling <<<"

die() { printf 'cc-tooling: %s\n' "$1" >&2; exit 1; }

client_dir() { # <client>
  local d="$CC_TOOLING_HOME/$1"
  [ -e "$d" ] || die "client '$1' not set up — run: cc-tooling link $1 <path>  (or: cc-tooling clone $1 <url>)"
  printf '%s\n' "$d"
}

repo_root() { git rev-parse --show-toplevel 2>/dev/null || die "not inside a git repo"; }

# info/exclude lives in the common git dir, which also works in worktrees
# (where .git is a file, not a directory).
exclude_file() {
  git rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null || die "not inside a git repo"
}

# Strip an existing oc-tooling block from an exclude file (stdin->stdout).
_strip_block() { awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}'; }

# Relative paths listed in the current block (stdin->stdout).
_block_paths() { awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{on=1;next} $0==e{on=0} on{sub(/^\//, ""); print}'; }

# True when <path> is a link this tool created (it points into the tooling home,
# or the pre-rename ~/.opencode-clients).
_is_ours() {
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in
    "$CC_TOOLING_HOME"/* | "$HOME/.opencode-clients"/*) return 0 ;;
    *) return 1 ;;
  esac
}

cmd_link() { # <client> <path>
  [ $# -eq 2 ] || die "usage: cc-tooling link <client> <path>"
  [ -d "$2" ] || die "path does not exist: $2"
  local target; target="$(cd "$2" && pwd -P)"
  mkdir -p "$CC_TOOLING_HOME"
  ln -sfn "$target" "$CC_TOOLING_HOME/$1"
  printf 'linked %s -> %s\n' "$CC_TOOLING_HOME/$1" "$target"
}

cmd_clone() { # <client> <url>
  [ $# -eq 2 ] || die "usage: cc-tooling clone <client> <url>"
  mkdir -p "$CC_TOOLING_HOME"
  git clone "$2" "$CC_TOOLING_HOME/$1"
}

cmd_apply() { # <client>/<repo>
  [ $# -eq 1 ] && [ "${1#*/}" != "$1" ] || die "usage: cc-tooling apply <client>/<repo>"
  local client="${1%%/*}" repo="${1#*/}"
  local cdir root excl; cdir="$(client_dir "$client")"; root="$(repo_root)"; excl="$(exclude_file)"

  local -a trees=()
  [ -d "$cdir/shared/tree" ] && trees+=("$cdir/shared/tree")
  [ -d "$cdir/repos/$repo/tree" ] && trees+=("$cdir/repos/$repo/tree")
  [ ${#trees[@]} -gt 0 ] || die "no tooling for $client/$repo under $cdir (expected shared/tree or repos/$repo/tree)"

  # Plan before touching anything; a repo file overrides a shared one.
  local -a rels=() srcs=()
  local tree f rel i found
  for tree in "${trees[@]}"; do
    while IFS= read -r -d '' f; do
      rel="${f#"$tree"/}"
      found=""
      for i in "${!rels[@]}"; do
        if [ "${rels[i]}" = "$rel" ]; then srcs[i]="$f"; found=1; break; fi
      done
      [ -n "$found" ] || { rels+=("$rel"); srcs+=("$f"); }
    done < <(find "$tree" -type f -print0)
  done
  [ ${#rels[@]} -gt 0 ] || die "no files under ${trees[*]}"

  local -a conflicts=()
  for rel in "${rels[@]}"; do
    if [ -e "$root/$rel" ] || [ -L "$root/$rel" ]; then
      _is_ours "$root/$rel" || conflicts+=("$rel")
    fi
  done
  if [ ${#conflicts[@]} -gt 0 ]; then
    printf 'cc-tooling: refusing to apply — these paths already exist and are not cc-tooling links:\n' >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$excl")"; touch "$excl"

  # Drop links from an earlier apply that this one no longer provides.
  local old keep
  while IFS= read -r old; do
    keep=""
    for rel in "${rels[@]}"; do if [ "$rel" = "$old" ]; then keep=1; break; fi; done
    if [ -z "$keep" ] && _is_ours "$root/$old"; then rm -f "$root/$old"; printf '  - %s\n' "$old"; fi
  done < <(_block_paths <"$excl")

  # Exclude first, so an interrupted apply never leaves visible links behind.
  { _strip_block <"$excl"; printf '%s\n' "$MARK_BEGIN"; printf '/%s\n' "${rels[@]}"; printf '%s\n' "$MARK_END"; } >"$excl.tmp"
  mv "$excl.tmp" "$excl"

  for i in "${!rels[@]}"; do
    mkdir -p "$(dirname "$root/${rels[i]}")"
    ln -sfn "${srcs[i]}" "$root/${rels[i]}"
    printf '  + %s\n' "${rels[i]}"
  done
  printf 'applied %s/%s — %d file(s) symlinked, excluded locally\n' "$client" "$repo" "${#rels[@]}"
}

cmd_unapply() {
  local root excl rel n=0; root="$(repo_root)"; excl="$(exclude_file)"
  [ -f "$excl" ] || { printf 'nothing applied\n'; return 0; }
  while IFS= read -r rel; do
    if _is_ours "$root/$rel"; then rm -f "$root/$rel"; printf '  - %s\n' "$rel"; n=$((n+1)); fi
  done < <(_block_paths <"$excl")
  _strip_block <"$excl" >"$excl.tmp"; mv "$excl.tmp" "$excl"
  printf 'unapplied — %d symlink(s) removed, exclude block cleared\n' "$n"
}

cmd_status() {
  local excl; excl="$(exclude_file)"
  [ -f "$excl" ] || { printf 'nothing applied\n'; return 0; }
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '$0==b{on=1;next} $0==e{on=0} on{print "  " $0}' "$excl"
}

cmd_list() {
  [ -d "$CC_TOOLING_HOME" ] || { printf 'no clients set up (%s)\n' "$CC_TOOLING_HOME"; return 0; }
  local d r
  for d in "$CC_TOOLING_HOME"/*; do
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
    *) die "usage: cc-tooling {link <client> <path> | clone <client> <url> | apply <client>/<repo> | unapply | status | list}" ;;
  esac
}

main "$@"
