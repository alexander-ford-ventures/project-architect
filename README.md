# project-architect

A Claude Code plugin (single-plugin marketplace).

**Plugin:** `project-architect` — Project architecture planning and documentation generator. Interviews users in phases to capture vision, tech stack, and architecture decisions, then generates tailored planning documents and `CLAUDE.md`.

## Install

This marketplace is registered under the alias `local` in `~/.claude/plugins/known_marketplaces.json`. The plugin is enabled via `~/.claude/settings.json` under `enabledPlugins["project-architect@local"]`.

## Source

This repo IS the marketplace root. The catalog lives at `.claude-plugin/marketplace.json`; the single plugin's metadata at `.claude-plugin/plugin.json`; the skill files at `skills/project-architect/`.
