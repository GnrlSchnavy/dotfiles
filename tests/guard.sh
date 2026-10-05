#!/usr/bin/env bash
# Fixtures for the Claude Code lane hooks:
#   system/.claude/hooks/work-lane-guard.sh  (personal lane)
#   system/.claude-work/hooks/lane-check.sh  (work lane)
# Every known way of reaching a work root from the personal lane must block,
# and ordinary work (including editing these dotfiles) must not.
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
guard="$repo/system/.claude/hooks/work-lane-guard.sh"
lane_check="$repo/system/.claude-work/hooks/lane-check.sh"

export HOME=/Users/u
export CC_WORK_ROOTS=/Users/u/projects/client
P=/Users/u/projects
C=$P/client
D=$P/personal/dotfiles

failed=0
expect() { # <block|allow> <name> <payload>
  local want="$1" name="$2" rc got err
  err="$(printf '%s' "$3" | bash "$guard" 2>&1 >/dev/null)"
  rc=$?
  case $rc in 2) got=block ;; 0) got=allow ;; *) got="exit $rc" ;; esac
  if [ "$got" = "$want" ]; then
    printf 'ok    guard: %s\n' "$name"
  else
    printf 'FAIL  guard: %s (want %s, got %s)\n' "$name" "$want" "$got"
    failed=1
  fi
  if [ -n "$err" ] && { [ "$got" != "$want" ] || [ -n "${VERBOSE:-}" ]; }; then
    printf '        %s\n' "${err%%$'\n'*}"
  fi
}
tool() { # <cwd> <tool> <tool_input json>
  jq -cn --arg cwd "$1" --arg t "$2" --argjson in "$3" \
    '{session_id: "t", transcript_path: "/Users/u/.claude/projects/x/t.jsonl", hook_event_name: "PreToolUse", cwd: $cwd, tool_name: $t, tool_input: $in}'
}
sh() { tool "$1" Bash "$(jq -cn --arg c "$2" '{command: $c}')"; }
prompt() { # <cwd> <text>
  jq -cn --arg cwd "$1" --arg p "$2" \
    '{session_id: "t", transcript_path: "/Users/u/.claude/projects/x/t.jsonl", hook_event_name: "UserPromptSubmit", cwd: $cwd, prompt: $p}'
}

# ── must block ──
expect block "cwd inside the work root"            "$(tool "$C/svc" Read '{"file_path":"'"$C"'/svc/A.java"}')"
expect block "Read by absolute path"                "$(tool "$D" Read '{"file_path":"'"$C"'/svc/A.java"}')"
expect block "Write by absolute path"               "$(tool "$D" Write '{"file_path":"'"$C"'/x.md","content":"x"}')"
expect block "Read with different case (APFS)"      "$(tool "$D" Read '{"file_path":"/Users/u/Projects/Client/A.java"}')"
expect block "Bash: ~/ path"                        "$(sh "$D" 'cat ~/projects/client/svc/A.java')"
expect block "Bash: \$HOME path"                    "$(sh "$D" 'cat $HOME/projects/client/svc/A.java')"
expect block "Bash: \${HOME} path"                  "$(sh "$D" 'cat "${HOME}/projects/client/svc/A.java"')"
expect block "Bash: ../ from a sibling"             "$(sh "$P/personal" 'cat ../client/svc/A.java')"
expect block "Bash: cd .. then relative"            "$(sh "$P/personal" 'cd .. && cat client/svc/A.java')"
expect block "Bash: relative from the parent"       "$(sh "$P" 'cat client/svc/A.java')"
expect block "Bash: git -C into the root"           "$(sh "$D" 'git -C ../../client log -p')"
expect block "Bash: glob through the parent"        "$(sh "$P" 'cat */README.md')"
expect block "Bash: brace expansion"                "$(sh "$D" 'cat ~/projects/{client,other}/README.md')"
expect block "Bash: recursive grep from the parent" "$(sh "$P/personal" 'grep -rn token ..')"
expect block "Bash: rg from home"                   "$(sh /Users/u 'rg password')"
expect block "Bash: find from the parent"           "$(sh "$P" "find . -name '*.java'")"
expect block "Bash: path built from a variable"     "$(sh "$D" 'd=~/projects; cat $d/client/A.java')"
expect block "Grep with path into the root"         "$(tool "$P" Grep '{"pattern":"secret","path":"client"}')"
expect block "Grep with no path from the parent"    "$(tool "$P" Grep '{"pattern":"secret"}')"
expect block "Grep from home"                       "$(tool "$D" Grep '{"pattern":"secret","path":"/Users/u"}')"
expect block "Glob pattern into the root"           "$(tool "$P" Glob '{"pattern":"client/**/*.java"}')"
expect block "Glob ** from the parent"              "$(tool "$P" Glob '{"pattern":"**/*.java"}')"
expect block "Glob */x from the parent"             "$(tool "$P" Glob '{"pattern":"*/README.md"}')"
expect block "MCP tool with an absolute path"       "$(tool "$D" mcp__fs__read_file '{"path":"'"$C"'/A.java"}')"
expect block "MCP tool with a ~ path"               "$(tool "$D" mcp__fs__read_file '{"args":{"file":"~/projects/client/A.java"}}')"
expect block "prompt naming a ~ path"               "$(prompt "$D" 'summarise ~/projects/client/README.md')"
expect block "prompt @-mentioning a relative path"  "$(prompt "$P/personal" 'explain @../client/README.md please')"
expect block "prompt under a renamed field"         "$(jq -cn --arg cwd "$D" '{hook_event_name: "UserPromptSubmit", cwd: $cwd, prompt_text: "read /Users/u/projects/client/x"}')"
expect block "invalid JSON (fails closed)"          '{"cwd": '

# ── must allow ──
expect allow "Read inside the dotfiles"             "$(tool "$D" Read '{"file_path":"'"$D"'/README.md"}')"
expect allow "Edit whose text mentions the root"    "$(tool "$D" Edit '{"file_path":"'"$D"'/docs/x.md","old_string":"a","new_string":"see ~/projects/client"}')"
expect allow "Bash: grep the dotfiles docs"         "$(sh "$D" 'grep -rn "work roots" docs/')"
expect allow "Bash: overlay folder named client"    "$(sh "$D" 'ls system/.claude-work/client')"
expect allow "Bash: ls in home"                     "$(sh /Users/u 'ls -la')"
expect allow "Bash: brew list in home"              "$(sh /Users/u 'brew list')"
expect allow "Bash: similarly named sibling"        "$(sh "$D" 'cat ~/projects/clientele/README.md')"
expect allow "Bash: ls * in the parent (names only)" "$(sh "$P" 'ls *')"
expect allow "Bash: cd home then git status"        "$(sh "$D" 'cd ~ && git status')"
expect allow "Bash: unrelated variable"             "$(sh "$D" 'echo $PATH')"
expect allow "Bash: recursive grep in the repo"     "$(sh "$D" 'grep -rn TODO .')"
expect allow "Glob inside the dotfiles"             "$(tool "$D" Glob '{"pattern":"**/*.nix"}')"
expect allow "Grep inside the dotfiles"             "$(tool "$P/personal" Grep '{"pattern":"x","path":"dotfiles/nix"}')"
expect allow "prompt about the client lane"         "$(prompt "$D" 'how do I add a client lane?')"
expect allow "prompt with a relative mention"       "$(prompt "$P/personal" 'compare with client/README.md')"
expect allow "subagent prompt naming the root"      "$(tool "$D" Agent '{"prompt":"never read ~/projects/client"}')"

# A session whose cwd reaches the root through a symlink.
tmp="$(mktemp -d)"
mkdir -p "$tmp/projects/client/svc"
ln -s "$tmp/projects/client" "$tmp/work"
CC_WORK_ROOTS="$tmp/projects/client" expect block "cwd is a symlink into the root" "$(tool "$tmp/work/svc" Read '{"file_path":"x"}')"
# A guard deployed without its decision file must block.
cp "$guard" "$tmp/guard.sh"
printf '%s' "$(tool "$D" Read '{"file_path":"x"}')" | bash "$tmp/guard.sh" >/dev/null 2>&1
if [ $? -eq 2 ]; then printf 'ok    guard: missing .jq fails closed\n'; else printf 'FAIL  guard: missing .jq fails closed\n'; failed=1; fi
rm -rf "$tmp"

# ── work-lane check ──
check() { # <block|allow> <name> <env assignments...>
  local want="$1" name="$2" rc got
  shift 2
  printf '{}' | env -i PATH="$PATH" HOME="$HOME" "$@" bash "$lane_check" >/dev/null 2>&1
  rc=$?
  case $rc in 2) got=block ;; 0) got=allow ;; *) got="exit $rc" ;; esac
  if [ "$got" = "$want" ]; then
    printf 'ok    lane-check: %s\n' "$name"
  else
    printf 'FAIL  lane-check: %s (want %s, got %s)\n' "$name" "$want" "$got"
    failed=1
  fi
}
ok_env=(CC_LANE=work ANTHROPIC_BASE_URL=http://127.0.0.1:8787 CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages)
check allow "started by cc-work"         "${ok_env[@]}"
check allow "desktop gateway mode"       CLAUDE_CODE_API_BASE_URL=http://127.0.0.1:8787 CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check block "desktop gateway is Anthropic" CLAUDE_CODE_API_BASE_URL=https://API.anthropic.com CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check block "no gateway"                 CC_LANE=work CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check block "gateway is Anthropic"       CC_LANE=work ANTHROPIC_BASE_URL=https://api.anthropic.com CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check block "gateway is Anthropic (case)" CC_LANE=work ANTHROPIC_BASE_URL=https://API.Anthropic.COM CODEMEM_ANTHROPIC_ENDPOINT=https://gateway.example/v1/messages
check block "codemem endpoint Anthropic" CC_LANE=work ANTHROPIC_BASE_URL=http://127.0.0.1:8787 CODEMEM_ANTHROPIC_ENDPOINT=https://api.anthropic.com/v1/messages

exit $failed
