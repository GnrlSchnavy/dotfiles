#!/usr/bin/env bash
# Tests for system/bin/merge-claude-settings.sh (the activation-time merge of
# each lane's owned keys into ~/.claude*/settings.json).
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
merge="$repo/system/bin/merge-claude-settings.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failed=0
pass() { printf 'ok    merge: %s\n' "$1"; }
fail() { printf 'FAIL  merge: %s\n' "$1"; failed=1; }
check() { if [ "$1" -eq 0 ]; then pass "$2"; else fail "$2"; fi; }
q() { jq -e "$1" "$s" >/dev/null 2>&1; }

d="$tmp/claude"
s="$d/settings.json"
p="$d/hooks/"
mkdir -p "$d"

cat >"$tmp/seed.json" <<'EOF'
{"enabledPlugins": {"x@y": true}, "effortLevel": "high"}
EOF
cat >"$tmp/owned.json" <<EOF
{
  "env": {"A": "1", "B": "2"},
  "union": {"permissions": {"deny": ["Read(//w/**)"]}, "sandbox": {"filesystem": {"denyRead": ["/w"]}}},
  "set": {"sandbox": {"enabled": true}},
  "default": {"model": "opus", "sandbox": {"autoAllowBashIfSandboxed": false}},
  "hooks": {"PreToolUse": [{"matcher": "*", "hooks": [{"type": "command", "command": "${p}guard.sh"}]}]}
}
EOF
run() { bash "$merge" "$s" "$1" "$p" "$tmp/seed.json" 2>"$tmp/err"; }

run "$tmp/owned.json"; check $? "first run succeeds without a settings file"
q '.enabledPlugins["x@y"] == true and .effortLevel == "high"'; check $? "missing file starts from the seed"
q '.env == {"A":"1","B":"2"} and .model == "opus" and .sandbox.enabled == true'; check $? "owned keys are written"

# What the app and the user add between rebuilds.
jq --arg p "$p" '
  .env.MINE = "keep" | .env.A = "changed"
  | .model = "sonnet" | .sandbox.enabled = false
  | .permissions.deny += ["Read(//mine/**)"]
  | .hooks.PreToolUse[0].hooks += [{"type": "command", "command": "/usr/local/bin/my-hook"}]
  | .hooks.Stop = [{"hooks": [{"type": "command", "command": "/plugin/stop.sh"}]}]
' "$s" >"$tmp/edit" && mv "$tmp/edit" "$s"

run "$tmp/owned.json"
q '.env == {"A":"1","B":"2","MINE":"keep"}'; check $? "owned env overwrites, other env stays"
q '.model == "sonnet"'; check $? "default keeps a value you changed"
q '.sandbox.enabled == true and .sandbox.autoAllowBashIfSandboxed == false'; check $? "set is enforced, nested default filled"
q '.permissions.deny == ["Read(//w/**)", "Read(//mine/**)"]'; check $? "union keeps your entries without duplicates"
q '[.hooks.PreToolUse[].hooks[].command] | sort == ["'"$p"'guard.sh", "/usr/local/bin/my-hook"]'; check $? "managed hook replaced, hand-added hook in the same group kept"
q '.hooks.Stop[0].hooks[0].command == "/plugin/stop.sh"'; check $? "other events keep their hooks"
q '[.hooks.PreToolUse[].hooks[] | select(.command == "'"$p"'guard.sh")] | length == 1'; check $? "managed hook not duplicated"

cp "$s" "$tmp/before"
run "$tmp/owned.json"
cmp -s "$s" "$tmp/before"; check $? "re-run is idempotent"

jq '.env = {"A": "1"}' "$tmp/owned.json" >"$tmp/owned2.json"
run "$tmp/owned2.json"
q '.env == {"A":"1","MINE":"keep"}'; check $? "an env key Nix no longer owns is removed"

printf '{"env": {' >"$s"
run "$tmp/owned2.json"; check $? "invalid JSON doesn't fail the rebuild"
q '.env.A == "1" and .effortLevel == "high"'; check $? "invalid file is replaced from the seed"
ls "$s".invalid-* >/dev/null 2>&1 && grep -q 'not valid JSON' "$tmp/err"; check $? "invalid file is kept aside with a warning"
[ -z "$(find "$d" -name 'settings.json.??????')" ]; check $? "no temp files left behind"

exit $failed
