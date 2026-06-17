# OpenCode global instructions + agents — shared across all hosts.
#
# This deploys the *global* OpenCode layer (read by every session, both
# `oc-personal` and `oc-work`):
#
#   ~/.config/opencode/AGENTS.md   ← system/opencode/AGENTS.md   (baseline rules)
#   ~/.config/opencode/agent/      ← system/opencode/agent/      (curated agents)
#   ~/.config/opencode/ahold/      ← system/opencode/ahold/      (client overlay)
#
# How the layers stack (verified against opencode 1.17.5):
#   - OpenCode always loads ~/.config/opencode/AGENTS.md, then walks UP from the
#     cwd to the project root collecting any project AGENTS.md, and combines all
#     of them. (A project-level CLAUDE.md is NOT auto-loaded in this version —
#     instruction files must be named AGENTS.md.)
#   - Agents are discovered via the glob {agent,agents}/**/*.md under the config
#     dir and any project .opencode/, so the agents below are available globally.
#   - The Ahold overlay is NOT loaded globally. It is pulled in only by the work
#     lane, via `instructions` in the work opencode.json (see codemem.nix →
#     home.file."projects/ahold/opencode.json"). That file globs
#     "${home}/.config/opencode/ahold/*.md" — OpenCode resolves an absolute entry
#     as glob(basename, {cwd: dirname}), so every *.md in the folder loads (flat,
#     one level). Add files to extend the overlay; new clients = new folder + lane.
#
# Agents intentionally OMIT a `model:` field so they inherit the active lane's
# default model. Hard-coding `anthropic/...` would route an agent to the personal
# Max proxy even under oc-work — a client-data leak. Leaving it unset preserves
# lane isolation.
#
# The source files live in system/opencode/ (git-tracked; flakes only see
# tracked files). They are static, so symlinking read-only into the Nix store is
# safe — OpenCode only reads them.
{ ... }:

{
  xdg.configFile = {
    "opencode/AGENTS.md".source = ../../system/opencode/AGENTS.md;
    # Client overlay folder — every *.md inside is glob'd in by the work lane
    # (see codemem.nix). Add files here to extend Ahold's rules; new clients
    # get their own folder + lane.
    "opencode/ahold".source = ../../system/opencode/ahold;
    # Whole-directory symlink: every system/opencode/agent/*.md becomes a global
    # OpenCode agent.
    "opencode/agent".source = ../../system/opencode/agent;
  };
}
