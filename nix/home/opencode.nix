# OpenCode global instructions + agents — shared across all hosts.
#
# This deploys the *global* OpenCode layer (read by every session, both
# `oc-personal` and `oc-work`):
#
#   ~/.config/opencode/AGENTS.md   ← system/opencode/AGENTS.md   (baseline rules)
#   ~/.config/opencode/agent/      ← system/opencode/agent/      (curated agents)
#   ~/.config/opencode/ahold.md    ← system/opencode/ahold.md    (client overlay)
#
# How the layers stack (verified against opencode 1.17.5):
#   - OpenCode always loads ~/.config/opencode/AGENTS.md, then walks UP from the
#     cwd to the project root collecting any project AGENTS.md, and combines all
#     of them. (A project-level CLAUDE.md is NOT auto-loaded in this version —
#     instruction files must be named AGENTS.md.)
#   - Agents are discovered via the glob {agent,agents}/**/*.md under the config
#     dir and any project .opencode/, so the agents below are available globally.
#   - The Ahold overlay (ahold.md) is NOT loaded globally. It is pulled in only
#     by the work lane, via `instructions` in the work opencode.json (see
#     codemem.nix → home.file."projects/ahold/opencode.json"). That file lists
#     the absolute path "${home}/.config/opencode/ahold.md", which OpenCode
#     resolves directly. New clients = new overlay file + new lane.
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
    "opencode/ahold.md".source = ../../system/opencode/ahold.md;
    # Whole-directory symlink: every system/opencode/agent/*.md becomes a global
    # OpenCode agent.
    "opencode/agent".source = ../../system/opencode/agent;
  };
}
