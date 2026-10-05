#!/usr/bin/env bash
# Tests for system/bin/cc-tooling.sh against throwaway git repos.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
tool="$repo/system/bin/cc-tooling.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

export HOME="$tmp/home" CC_TOOLING_HOME="$tmp/home/.claude-clients"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME"

failed=0
pass() { printf 'ok    cc-tooling: %s\n' "$1"; }
fail() { printf 'FAIL  cc-tooling: %s\n' "$1"; failed=1; }
check() { if [ "$1" -eq 0 ]; then pass "$2"; else fail "$2"; fi; }
same() { [ "$1" = "$2" ]; }
cct() { bash "$tool" "$@" >/dev/null 2>&1; }
clean() { [ -z "$(git status --porcelain)" ]; }

# Private tooling: one shared file, two repo files (one overriding the shared one).
t="$tmp/tooling"
mkdir -p "$t/shared/tree/.claude/agents" "$t/repos/svc/tree/.claude/agents" "$t/repos/svc/tree/module"
echo shared > "$t/shared/tree/.claude/agents/common.md"
echo shared > "$t/shared/tree/.claude/agents/x.md"
echo repo > "$t/repos/svc/tree/.claude/agents/x.md"
echo rules > "$t/repos/svc/tree/module/AGENTS.md"
(cd "$tmp" && bash "$tool" link rel tooling >/dev/null)
same "$(readlink "$CC_TOOLING_HOME/rel")" "$(cd "$t" && pwd -P)"; check $? "link stores an absolute target"
bash "$tool" link acme "$t" >/dev/null

# A client repo that already tracks module/AGENTS.md.
git init -q "$tmp/svc" && cd "$tmp/svc" || exit 1
mkdir module && echo "team rules" > module/AGENTS.md && echo app > app.txt
git add . && git commit -qm init

if cct apply acme/svc; then fail "refuses to overwrite a tracked file"; else pass "refuses to overwrite a tracked file"; fi
clean && [ ! -L module/AGENTS.md ] && [ ! -e .claude ] && ! grep -q oc-tooling .git/info/exclude 2>/dev/null; check $? "a refused apply changes nothing"

git rm -q module/AGENTS.md && git commit -qm "drop team rules"
cct apply acme/svc; check $? "apply succeeds"
clean; check $? "applied links are excluded"
same "$(cat .claude/agents/x.md)" repo; check $? "repo file overrides the shared one"
cct apply acme/svc && clean; check $? "re-apply is idempotent"

rm "$t/shared/tree/.claude/agents/common.md"
cct apply acme/svc
[ ! -e .claude/agents/common.md ] && [ ! -L .claude/agents/common.md ] && clean; check $? "re-apply drops links no longer provided"

echo mine > notes.md && mkdir -p "$t/repos/svc/tree" && echo theirs > "$t/repos/svc/tree/notes.md"
if cct apply acme/svc; then fail "refuses to overwrite an untracked file"; else pass "refuses to overwrite an untracked file"; fi
same "$(cat notes.md)" mine; check $? "untracked file left intact"
rm notes.md "$t/repos/svc/tree/notes.md"

bash "$tool" status | grep -q '/module/AGENTS.md'; check $? "status lists applied files"
cct unapply && [ ! -e module/AGENTS.md ] && [ ! -e .claude/agents/x.md ] && clean && ! grep -q oc-tooling .git/info/exclude; check $? "unapply removes links and the block"
same "$(cat app.txt)" app; check $? "unapply leaves repo files alone"

# Worktrees keep info/exclude in the common git dir (.git is a file there).
git worktree add -q "$tmp/svc-wt" && cd "$tmp/svc-wt" || exit 1
cct apply acme/svc && clean && [ -L module/AGENTS.md ]; check $? "apply works in a git worktree"
cct unapply && clean; check $? "unapply works in a git worktree"

exit $failed
