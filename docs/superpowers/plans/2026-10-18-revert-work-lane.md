# Work-Lane Reversion Plan

> **Superseded — do not execute.** Instead of deleting the work setup, it
> moved to its own host: see `2026-10-18-m5-personal-only.md` and commit
> 7714277 (dev/personal/work profiles).

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all Ahold work-lane infrastructure from the Nix dotfiles configuration, leaving a personal-only MacBook setup with no work isolation, DevAI CLI dependency, or dual-lane Claude Code structure.

**Architecture:** The current setup maintains strict isolation between personal (`~/.claude`) and work (`~/.claude-work`) lanes via separate Claude Code configs, codemem databases, git identities, and Docker engines. Reverting means collapsing to a single personal lane: remove all `.claude-work` directories, eliminate work-specific Nix modules and guards, restore personal-only git identity defaults, and clean up CLI shortcuts that depend on DevAI/TechNL infrastructure.

**Tech Stack:** Nix (darwin-rebuild), home-manager, git config, Claude Code, codemem

---

## What's Currently Work-Related

### 1. **Claude Code Dual-Lane System**
- **Personal lane:** `~/.claude` (config dir, personal Anthropic login)
- **Work lane:** `~/.claude-work` (config dir, Ahold TechNL gateway via DevAI CLI)
- **Location:** `nix/home/claude-lanes.nix` (483 lines)
- **Scope:** Defined dual-lane functions (`cc-personal`, `cc-work`, `cc-work-desktop`, `_cc_work_prepare`), environment isolation, hook injection, Docker engine separation

### 2. **Work Lane Hooks & Guards**
- **Work enforce hooks:** `system/.claude-work/hooks/` — `lane-check.sh`, `agents-md.sh` (enforce TechNL gateway, block direct Anthropic access)
- **Personal guard hooks:** `system/.claude/hooks/work-lane-guard.sh` (block personal lane from reading `~/projects/ahold`)
- **Total:** 4 files, ~200 lines

### 3. **Work Lane Overlay & Documentation**
- **Path:** `system/.claude-work/ahold/` — `00-isolation.md`, `10-stack.md`
- **Merged into:** Work lane `~/.claude-work/CLAUDE.md` at build time
- **Scope:** Work-specific Claude instructions

### 4. **Codemem Memory Separation**
- **Personal DB:** `~/.codemem/personal/` (local Claude extraction)
- **Work DB:** `~/.codemem/work-ahold/` (TechNL proxy extraction)
- **Configs:** `~/.config/codemem/personal.json`, `~/.config/codemem/work-ahold.json`
- **Location:** `nix/home/codemem.nix` (60+ lines define per-lane observer configs)

### 5. **Git Configuration**
- **Default identity:** `yvanstemmerik-ah` (work)
- **Personal overrides:** Conditional includes for `~/projects/personal/` and `~/.dotfiles/`
- **GitHub routing:** `RoyalAholdDelhaize`, `yvanstemmerik-ah` owners → work SSH key (`ahold` alias)
- **Location:** `nix/hosts/m5/git.nix` lines 14-33

### 6. **DevAI CLI Dependency**
- **Commands:** `devai-claude`, `devai-claude-desktop` (from `devai setup`)
- **Secrets:** TechNL proxy URL + API key from Proton Pass (`pass://Ahold/TechNLGenAI/`)
- **Location:** `nix/home/claude-lanes.nix` lines 408-451 (zsh functions)

### 7. **Docker Isolation**
- **Colima profile:** `personal` (VM with 4 CPUs, 3 GB RAM, mounts only `~/projects/personal`)
- **Mounted:** Only `~/projects/personal/` (work tree `~/projects/ahold` is excluded)
- **Location:** `nix/home/claude-lanes.nix` lines 320-370

### 8. **Work Root Restrictions**
- **Blocked path:** `~/projects/ahold`
- **Enforced by:** Personal lane Read/Edit permission denies, Bash sandbox denyRead
- **Location:** `nix/home/claude-lanes.nix` lines 59, 172-179

---

## Files to Modify

### Removals (delete entire files)
- `system/.claude-work/` (directory with hooks, ahold overlay)
- `system/.claude/hooks/work-lane-guard.sh`

### Modifications (edit in place)
1. **`nix/home/claude-lanes.nix`** (483 lines → ~100 lines)
   - Remove: `workRoots`, `workEnv`, `workOwned`, dual-lane zsh functions, Colima profile
   - Keep: `personalDir`, `personalEnv`, `personalOwned`, `codememPlugin`, `mergeSettings`, `claudeGitSsh`

2. **`nix/home/codemem.nix`** (60 lines → ~30 lines)
   - Remove: `work-ahold.json` config, work observer setup
   - Keep: `personal.json`, runtime folder creation (just personal)

3. **`nix/hosts/m5/git.nix`** (80+ lines → ~50 lines)
   - Remove: `workGitHubOwners`, GitHub owner routing, work SSH key references
   - Change: Default user identity from `yvanstemmerik-ah` (work) to `yvan` + `yvanstemmerik@gmail.com` (personal)
   - Keep: Personal includes for `~/projects/personal/` and `~/.dotfiles/`

4. **`nix/home/files.nix`** (if it exists)
   - Remove: Any references to `.claude-work/` symlinks

5. **`nix/home/default.nix`** (if it imports claude-lanes.nix)
   - Verify no work-only module imports

---

## Tasks

### Task 1: Prepare & verify

**Files:**
- Read: `nix/home/claude-lanes.nix`, `nix/homes/codemem.nix`, `nix/hosts/m5/git.nix`
- No modifications

- [ ] **Step 1: Verify current git branch is clean**

Run: `cd ~/.dotfiles && git status`
Expected: No uncommitted changes

- [ ] **Step 2: Review current work-related lines**

Run: `cd ~/.dotfiles && grep -n "workEnv\|workOwned\|work-ahold\|devai-claude\|RoyalAholdDelhaize" nix/home/claude-lanes.nix nix/home/codemem.nix nix/hosts/m5/git.nix`
Expected: Output shows work config in three files

---

### Task 2: Remove work Claude Code lane infrastructure

**Files:**
- Delete: `system/.claude-work/` (entire directory)
- Delete: `system/.claude/hooks/work-lane-guard.sh`
- Modify: `nix/home/claude-lanes.nix` (remove work vars, functions, settings merge)

- [ ] **Step 1: Delete work lane directory**

Run: `rm -rf ~/.dotfiles/system/.claude-work/`
Expected: Directory gone

- [ ] **Step 2: Delete personal work guard hook**

Run: `rm ~/.dotfiles/system/.claude/hooks/work-lane-guard.sh`
Expected: File gone

- [ ] **Step 3: Edit `nix/home/claude-lanes.nix` — remove work-lane top-level declarations**

Open file, delete lines:
- Lines 59 (workRoots), 110-123 (workEnv), 241-258 (workOwned)

After edit, the file should have only `personalDir`, `personalEnv`, `personalOwned`, `codememPlugin`, etc.

- [ ] **Step 4: Edit `nix/home/claude-lanes.nix` — remove work lane zsh functions**

Delete lines 407-481 (`_cc_work_prepare`, `cc-work`, `cc-work-desktop`, `cc-lanes-setup` functions)

Keep only: `cc-personal()` and `git()` function

- [ ] **Step 5: Edit `nix/home/claude-lanes.nix` — remove work settings merge**

Delete line 391 (the `run ${mergeSettings}... ${workDir}...` call in `claudeLaneSettings` activation)

Keep only: line 390 (personal settings merge)

- [ ] **Step 6: Edit `nix/home/claude-lanes.nix` — remove work file symlinks**

Delete lines 308-310 (`.claude-work/CLAUDE.md`, `.claude-work/agents`, `.claude-work/commands`, `.claude-work/hooks` in `home.file`)

Keep lines 302-304 (personal lane symlinks)

- [ ] **Step 7: Edit `nix/home/claude-lanes.nix` — remove Colima profile**

Delete lines 320-370 (`services.colima` with `profiles.personal` — the entire block)

- [ ] **Step 8: Edit `nix/home/claude-lanes.nix` — remove work-only exports from personalOwned**

Delete lines 172-175 (the `permissions.deny` Read/Edit blocks for `workRoots`)

Delete lines 179 (the `sandbox.filesystem.denyRead = workRoots` for Bash sandbox)

Result: `personalOwned` should only have `env`, `set`, `default`, and `hooks` keys

- [ ] **Step 9: Verify `nix/home/claude-lanes.nix` has no "work" references**

Run: `grep -n "work" ~/.dotfiles/nix/home/claude-lanes.nix`
Expected: Only comments remain, no variable/function names with "work"

---

### Task 3: Simplify codemem to personal-only

**Files:**
- Modify: `nix/home/codemem.nix`

- [ ] **Step 1: Edit `nix/home/codemem.nix` — remove work observer config**

Delete lines 42-56 (the `xdg.configFile."codemem/work-ahold.json"` block)

- [ ] **Step 2: Edit `nix/home/codemem.nix` — simplify activation to personal only**

Change line 60 (the activation block) from:
```nix
run mkdir -p ${home}/.codemem/personal ${home}/.codemem/work-ahold
```
to:
```nix
run mkdir -p ${home}/.codemem/personal
```

- [ ] **Step 3: Verify `nix/home/codemem.nix` has no "work" references**

Run: `grep -n "work" ~/.dotfiles/nix/home/codemem.nix`
Expected: No matches

---

### Task 4: Revert git identity and routing to personal-only

**Files:**
- Modify: `nix/hosts/m5/git.nix`

- [ ] **Step 1: Edit `nix/hosts/m5/git.nix` — remove work GitHub owners**

Delete lines 30-33 (the `workGitHubOwners` list)

- [ ] **Step 2: Edit `nix/hosts/m5/git.nix` — change default user identity**

Find the line with `user = { name = "yvanstemmerik-ah"; email = "..."; };` (around line 79-80)

Replace with:
```nix
user = {
  name = "yvan";
  email = "yvanstemmerik@gmail.com";
};
```

- [ ] **Step 3: Edit `nix/hosts/m5/git.nix` — remove work SSH key references and owner routing**

Find and delete any lines that reference:
- `ahold` SSH alias
- Work SSH key paths
- GitHub owner credential mapping for work owners

(These may be in `credential` or `url` blocks — look for patterns like `"https://github.com"` keys with work owner conditions)

- [ ] **Step 4: Verify git config has no work references**

Run: `grep -in "ahold\|devai\|technl\|royalaholddelhaize\|yvanstemmerik-ah" ~/.dotfiles/nix/hosts/m5/git.nix`
Expected: No matches (case-insensitive search should be clean)

---

### Task 5: Clean up and rebuild

**Files:**
- No modifications (just verification and rebuild)

- [ ] **Step 1: Verify no dangling references in other files**

Run: `cd ~/.dotfiles && grep -r "\.claude-work\|work-ahold\|devai-claude\|workRoots" nix/ system/ --include="*.nix" --include="*.sh" --include="*.md" | grep -v "\.git"`
Expected: Matches only in comments or docs (0-5 lines), not in active code

- [ ] **Step 2: Run Nix flake syntax check**

Run: `cd ~/.dotfiles/nix && nix flake check --no-build`
Expected: All hosts pass evaluation (no type errors, missing files, or undefined vars)

- [ ] **Step 3: Commit the reversion**

Run:
```bash
cd ~/.dotfiles
git add -A
git commit -m "chore: remove work-lane (Ahold) infrastructure — personal laptop only

- Remove dual-lane Claude Code system (~/.claude-work, devai-claude)
- Delete work isolation hooks and TechNL/Ahold configuration
- Revert git identity to personal (yvan/yvanstemmerik@gmail.com)
- Remove work GitHub owner routing and SSH key management
- Simplify codemem to personal DB only (~/.codemem/personal)
- Remove Colima Docker separation and work root restrictions

Remaining: single personal lane, personal git identity, personal codemem DB"
```

Expected: Commit succeeds with clean diff showing deletions

- [ ] **Step 4: Apply the rebuild**

Run: `sudo darwin-rebuild switch --flake ~/.dotfiles/nix#$(scutil --get LocalHostName) -v`
Expected: Build succeeds, no errors in activation scripts

---

### Task 6: Verify personal-only setup

**Files:**
- No modifications (just verification)

- [ ] **Step 1: Verify ~/.claude-work does not exist**

Run: `ls -la ~/.claude-work 2>&1 | head -3`
Expected: "No such file or directory"

- [ ] **Step 2: Verify git identity is personal**

Run: `cd ~/.dotfiles && git config user.name && git config user.email`
Expected: Output is `yvan` and `yvanstemmerik@gmail.com`

- [ ] **Step 3: Verify no devai-* commands are available**

Run: `command -v devai-claude devai-claude-desktop cc-work 2>&1 | grep -v "not found" | wc -l`
Expected: Output is `0` (all commands should be "not found")

- [ ] **Step 4: Verify cc-personal function works**

Run: `cc-personal --version 2>&1 | head -1`
Expected: Claude version output (e.g., "Claude Code 1.x.x")

- [ ] **Step 5: Verify no codemem work DB**

Run: `ls -1 ~/.codemem/`
Expected: Only `personal/` directory (no `work-ahold/`)

- [ ] **Step 6: Verify personal lane Bash sandbox allows all personal projects**

Run: `cd ~/.dotfiles && grep "denyRead\|deny = " nix/home/claude-lanes.nix | head -5`
Expected: No output (all deny rules removed)

---

## Review Focus

1. **Orphaned configuration:** References to work lanes or TechNL infrastructure remaining in non-obvious places (e.g., environment variable exports, model aliases in settings.json)
   - **Test:** Grep across the entire `nix/` and `system/` directories for "ahold", "devai", "technl", "work-ahold" — all matches should be in deleted files or comments only

2. **Git identity fallback:** New commits made before verifying git config could go out with work identity instead of personal
   - **Test:** After rebuild, run `git log -1 --format="%an %ae"` in both `~/.dotfiles` and `~/projects/personal/dotfiles` — both must show `yvan yvanstemmerik@gmail.com`

3. **Claude Code settings pollution:** Work-lane settings or environment variables persisting in `~/.claude/settings.json` after rebuild
   - **Test:** After first personal session, grep `~/.claude/settings.json` for "work", "ahold", "devai", "technl" — should be empty

4. **Codemem port conflict:** Old work observer (port 4848) still trying to connect and interfering with personal lane (port 4747)
   - **Test:** Start a personal Claude session, run `ps aux | grep codemem | grep 4848` — should show nothing

5. **Docker engine fallback:** Sandbox or docker commands still pointing to work lane's Colima or Docker Desktop separation
   - **Test:** In a personal Claude session, run `docker ps` — should succeed without errors (Docker Desktop remains active)

---

## Self-Review Checklist

- ✅ **Spec coverage:** The goal is "remove all work-lane infrastructure." All tasks cover the identified work components: Claude lanes, hooks, git config, codemem, Docker/Colima, and file deletions.
- ✅ **Placeholder scan:** All steps contain exact file paths, line numbers, and expected outputs. No "TBD" or "similar to Task X."
- ✅ **Type consistency:** No code generation needed (Nix deletions are straightforward); consistency is in git identity and codemem DB naming.
- ✅ **Review Focus:** Five failure modes identified; each has a specific test command and expected output.

---

## Appendix: Summary of Deletions

| Path | Type | Reason |
|------|------|--------|
| `system/.claude-work/` | Directory | Work-lane config overlay (no personal equivalent) |
| `system/.claude/hooks/work-lane-guard.sh` | File | Personal lane guard against work repos (not needed) |
| `nix/home/claude-lanes.nix` (59, 110-123, 241-258, 320-370, 407-481, line 391) | Sections | All work-lane definitions, Docker profile, zsh functions, activation |
| `nix/home/codemem.nix` (42-56, part of line 60) | Sections | Work observer config and folder creation |
| `nix/hosts/m5/git.nix` (30-33, work identity, work owner routing) | Sections | Work GitHub routing, SSH key management, default identity |

---

## Appendix: Files That Remain Unchanged

- `nix/home/files.nix` — No work-lane file symlinks; no changes needed
- `nix/home/default.nix` — No work-specific imports; no changes needed
- `nix/hosts/m5/default.nix` — No work-only packages; no changes needed
- `nix/hosts/m5/packages.nix` — No work-only tools (feishin, maven, git, jq, etc. are all personal-usable)
- `nix/hosts/m5/homebrew.nix` — No work-only casks/brews (Teams, Outlook, Slack, Discord, VSCode all remain)
- `system/.claude/CLAUDE.md` — No changes; personal global instructions remain
- All other docs, scripts, and configs — Remain as-is
