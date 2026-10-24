#!/usr/bin/env bash
# Doc drift: the directory map in docs/architecture.md must match the nix/
# tree, both ways — every module is in the map, every mapped path exists.
# Also every profile is in nix/profiles/README.md's table, every cask and
# brew a profile declares is named in docs/profiles.md, and README.md's
# layout and docs/hosts.md's table name every host and shared module.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo" || exit 1
failed=0
pass() { printf 'ok    docs: %s\n' "$1"; }
fail() { printf 'FAIL  docs: %s\n' "$1"; failed=1; }

# The map's code block: from "## Directory map" to the closing fence.
block="$(awk '/^## Directory map/ { on = 1; next } on && /^```/ { if (seen) exit; seen = 1; next } seen' docs/architecture.md)"
[ -n "$block" ] || { fail "no directory map in docs/architecture.md"; exit 1; }

# Rebuild full paths from the tree drawing: each "│   " or "    " is one
# level, then "├── " or "└── " and the entry name; dirs end in "/".
mapped=()
stack=()
while IFS= read -r line; do
  depth=0
  while :; do
    case "$line" in
      "│   "*) line="${line#"│   "}" ;;
      "    "*) line="${line#"    "}" ;;
      *) break ;;
    esac
    depth=$((depth + 1))
  done
  case "$line" in
    "├── "* | "└── "*) ;;
    *) continue ;; # nix/ itself, or a continuation line
  esac
  rest="${line#"├── "}"
  rest="${rest#"└── "}"
  name="${rest%% *}"
  prefix="nix/"
  for ((i = 0; i < depth; i++)); do prefix="$prefix${stack[i]}"; done
  mapped+=("$prefix$name")
  case "$name" in */) stack[depth]="$name" ;; esac
done <<<"$block"

in_map() { local p; for p in "${mapped[@]}"; do [ "$p" = "$1" ] && return 0; done; return 1; }

# Forward: modules and host dirs are mapped. nixvim's files are listed by
# name only, several to a line.
missing=""
while IFS= read -r f; do
  case "$f" in
    nix/hosts/*) d="${f#nix/hosts/}"; in_map "nix/hosts/${d%%/*}/" || missing="$missing nix/hosts/${d%%/*}/" ;;
    nix/nixvim/config/*) grep -qw -- "$(basename "$f")" <<<"$block" || missing="$missing $f" ;;
    *) in_map "$f" || missing="$missing $f" ;;
  esac
done < <(git ls-files 'nix/*.nix' 'nix/*/*.nix' 'nix/*/*/*.nix' 'nix/*/*/*/*.nix' | sort -u)
if [ -z "$missing" ]; then pass "every nix/ module is in the architecture map"
else fail "missing from the architecture map:$(printf '%s' "$missing" | tr ' ' '\n' | sort -u | tr '\n' ' ')"; fi

# Reverse: everything mapped exists.
stale=""
for p in "${mapped[@]}"; do [ -e "$p" ] || stale="$stale $p"; done
if [ -z "$stale" ]; then pass "every mapped path exists"
else fail "in the architecture map but not in the repo:$stale"; fi

# Every cask and brew a profile declares is named in docs/profiles.md.
missing=""
for f in nix/profiles/*/homebrew.nix; do
  while IFS= read -r name; do
    grep -qF -- "\`$name\`" docs/profiles.md || missing="$missing $name"
  done < <(grep -o '"[^"]*"' "$f" | tr -d '"')
done
if [ -z "$missing" ]; then pass "every profile app and brew is in docs/profiles.md"
else fail "missing from docs/profiles.md:$missing"; fi

# README's layout tree names every host folder and every shared module, and
# docs/hosts.md's table has a row for every host folder.
tree="$(awk '/^## Repository layout/ { on = 1; next } on && /^```/ { if (seen) exit; seen = 1; next } seen' README.md)"
missing=""
for d in nix/hosts/*/; do
  name="$(basename "$d")"
  grep -qF -- "── $name/" <<<"$tree" || missing="$missing $d"
  grep -qF -- "| \`$name\` |" docs/hosts.md || missing="$missing docs/hosts.md:$name"
done
while IFS= read -r f; do
  grep -qF -- "── $(basename "$f") " <<<"$tree" || missing="$missing $f"
done < <(git ls-files 'nix/home/*.nix' 'nix/modules/*.nix')
if [ -z "$missing" ]; then pass "README's layout and docs/hosts.md name every host and shared module"
else fail "missing from README.md's layout or docs/hosts.md:$missing"; fi

# Every profile is in the profiles README table.
missing=""
for d in nix/profiles/*/; do
  name="$(basename "$d")"
  grep -q "\[\`$name\`\]($name/)" nix/profiles/README.md || missing="$missing $name"
done
if [ -z "$missing" ]; then pass "every profile is in nix/profiles/README.md"
else fail "profiles missing from nix/profiles/README.md:$missing"; fi

exit $failed
