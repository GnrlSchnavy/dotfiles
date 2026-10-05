# Decision logic for work-lane-guard.sh. Prints the reason to block, or nothing.
#
# Input: the Claude Code hook payload. Arguments:
#   $roots  newline-separated work roots (as configured, plus physical paths)
#   $home   the user's home directory
#   $pwd    fallback when the payload has no cwd
#   $pcwd   the session cwd with symlinks resolved (may be empty)
#
# Paths are compared lower-cased because APFS is case-insensitive. Only jq 1.7
# builtins are used (macOS ships /usr/bin/jq 1.7.1) and no regex.

def lc: ascii_downcase;

def normpath:
  reduce (split("/")[]) as $s ([];
    if $s == "" or $s == "." then .
    elif $s == ".." then .[:-1]
    else . + [$s] end)
  | "/" + join("/");

def resolve($base):
  (if . == "~" or startswith("~/") then $home + .[1:]
   elif startswith("$HOME") then $home + .[5:]
   elif startswith("/") then .
   else $base + "/" + . end)
  | normpath | lc;

def inside($r): . == $r or startswith($r + "/");
def above($r): . as $p | $p != $r and ($p == "/" or ($r | startswith($p + "/")));
def hit($R): . as $p | any($R[]; . as $r | $p | inside($r));
def reaches($R): . as $p | any($R[]; . as $r | $p | above($r));

def globby: [index("*"), index("?"), index("["), index("{")] | map(. != null) | any;
def explicit: startswith("/") or startswith("~") or startswith("$HOME");

# Split shell-ish text into words on whitespace, quotes and shell operators.
def tokens:
  split("${HOME}") | join("$HOME")
  | explode
  | map(if . == 9 or . == 10 or . == 13 or . == 32 or . == 34 or . == 38 or . == 39
          or . == 40 or . == 41 or . == 58 or . == 59 or . == 60 or . == 61 or . == 62
          or . == 96 or . == 124
        then 32 else . end)
  | implode
  | split(" ")
  | map(select(length > 0));

# A glob reaches into a root when its fixed prefix is inside the root, or is a
# parent of it and the pattern descends past the root's own name.
def glob_hit($base; $R):
  split("/") as $segs
  | ([range(0; $segs | length) | select($segs[.] | globby)] | first) as $i
  | if $i == null then false
    else
      ($segs[:$i] | join("/")) as $fixed
      | $segs[$i:] as $rest
      | ((if $fixed == "" then (if $i == 0 then "." else "/" end) else $fixed end) | resolve($base)) as $p
      | any($R[]; . as $r
          | ($p | inside($r))
            or (($p | above($r))
                and (($rest | map(index("**") != null) | any)
                     or ($rest | length) > ($r | ltrimstr($p) | ltrimstr("/") | split("/") | length))))
    end;

def recursive($toks):
  ($toks | map(lc)) as $l
  | ($l | any(. == "find" or . == "fd" or . == "fdfind" or . == "rg" or . == "ag" or . == "ack"
              or . == "tree" or . == "du" or . == "rsync" or . == "tar" or . == "zip" or . == "7z"
              or . == "--recursive"))
    or ($toks | any(startswith("-") and (startswith("--") | not) and index("R") != null))
    or (($l | any(. == "grep" or . == "egrep" or . == "fgrep" or . == "cp" or . == "scp"))
        and ($toks | any(startswith("-") and (startswith("--") | not) and index("r") != null)));

def dynamic: (index("$(") != null) or (index("`") != null) or (split("$HOME") | join("") | index("$") != null);

def bash_check($cwd; $R; $names):
  . as $cmd
  | ($cmd | tokens) as $toks
  | (reduce $toks[] as $t ({cwd: $cwd, prev: "", hit: null, anc: ($cwd | reaches($R))};
      if .hit != null then .
      else
        .cwd as $c
        | ($t | resolve($c)) as $abs
        | (if ($abs | hit($R)) or (($t | globby) and ($t | glob_hit($c; $R))) then .hit = $t else . end)
        | (if $abs | reaches($R) then .anc = true else . end)
        | (if (.prev == "cd" or .prev == "pushd") and ($t | startswith("-") | not) then .cwd = $abs else . end)
        | .prev = ($t | lc)
      end)) as $st
  | if $st.hit != null then "the command touches \($st.hit)"
    elif $st.anc and recursive($toks) then "a recursive command runs from a folder that contains a client work tree"
    elif ($cmd | dynamic) and ($toks | any(lc | split("/") | any(. as $s | any($names[]; . == $s))))
    then "the command builds a path at run time that names a client work tree"
    else empty end;

($roots | split("\n") | map(select(length > 0) | normpath | lc) | unique) as $R
| ($R | map(split("/") | last)) as $names
| ((.cwd // $pwd) | normpath | lc) as $cwd
| (.tool_input // {}) as $in
| (.tool_name // "") as $tool
| if ($R | length) == 0 then empty
  elif ($cwd | hit($R)) or ($pcwd != "" and ($pcwd | normpath | lc | hit($R)))
  then "this session runs inside a client work tree (\(.cwd // $pwd))"
  elif $tool == "" then
    # A prompt: scan every string in the payload, so a renamed field still counts.
    first(.. | strings | tokens[]
      | if startswith("@") then .[1:] else select(explicit) end
      | select(length > 0)
      | . as $t
      | select(resolve($cwd) | hit($R))
      | "the prompt references \($t)")
  elif $tool == "Bash" then ($in.command // "") | bash_check($cwd; $R; $names)
  elif $tool == "Grep" then
    ($in.path // ".") as $raw
    | ($raw | resolve($cwd)) as $p
    | if ($p | hit($R)) or ($p | reaches($R)) then "Grep searches \($raw) (\($p)), which is or contains a client work tree"
      else empty end
  elif $tool == "Glob" then
    ($in.path // ".") as $raw
    | ($raw | resolve($cwd)) as $p
    | ($in.pattern // "") as $pat
    | if ($p | hit($R)) then "Glob searches \($raw), which is inside a client work tree"
      elif ($pat | globby) and ($pat | glob_hit($p; $R)) then "Glob pattern \($pat) reaches a client work tree"
      elif ($pat | globby | not) and ($pat | resolve($p) | hit($R)) then "Glob pattern \($pat) is inside a client work tree"
      else empty end
  elif $tool == "Read" or $tool == "Write" or $tool == "Edit" or $tool == "MultiEdit"
       or $tool == "NotebookEdit" or $tool == "NotebookRead" or $tool == "LS" then
    first($in | (.file_path?, .notebook_path?, .path?) | strings | select(length > 0)
      | . as $f | select(resolve($cwd) | hit($R)) | "\($tool) targets \($f)")
  elif $tool == "Task" or $tool == "Agent" or $tool == "TodoWrite" or $tool == "WebSearch"
       or $tool == "WebFetch" or $tool == "ExitPlanMode" or $tool == "AskUserQuestion" then empty
  else
    first($in | .. | strings | tokens[] | select(explicit)
      | . as $f | select(resolve($cwd) | hit($R)) | "\($tool) references \($f)")
  end
