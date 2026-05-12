---
template_name: PLUGIN_SPECIFIC
generate_when: "decisions.project.type == 'claude_code_plugin'"
required_decisions: [plugin.components]
optional_decisions: [plugin.distribution, plugin.dependencies, plugin.commands, plugin.skills, plugin.agents, plugin.hooks, plugin.mcp_servers]
depends_on: []
revision_triggers: [plugin.components, plugin.distribution]
---

# Plugin Specific: {{project_name}}

## Components Used (skills / commands / agents / hooks / MCP servers)
Which Claude Code primitives this plugin ships (skills, slash commands, subagents, hooks, MCP servers) and the responsibility of each.

## Triggers & Discoverability
Trigger phrasing / file patterns / command names that route work into this plugin, and how users discover capabilities (description copy, README examples, listing in marketplace).

## Configuration (per-project local file pattern)
Per-project configuration files (e.g., `.claude/<plugin>/config.json`, project-local `CLAUDE.md` injections), env var conventions, and global vs per-project precedence.

## Dependencies (hard vs soft)
External tooling required (CLI binaries, MCP servers, API keys, runtimes) split into hard requirements (plugin fails without them) vs soft (graceful degradation), with version pinning.

## Distribution (own marketplace / Anthropic / private)
Distribution channel (Anthropic marketplace, own marketplace repo, private GitHub install, local dev install), versioning scheme, and update mechanism.

## Testing the Plugin (writing-skills test scenarios)
Test approach following the writing-skills methodology: realistic test scenarios, fresh-session validation, behavioral assertions beyond unit coverage.

## Versioning Policy
Versioning scheme (semver) for the plugin manifest, breaking-change communication, deprecation periods, and changelog discipline.

## Revision Log
(none yet)
