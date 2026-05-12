# Changelog

All notable changes to the `project-architect` plugin.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-05-12

### Added — Major redesign as an orchestrator

- **9-phase bootstrap model**: preflight → 0a repo init → 0 universal kickoff → 1 vision → 2 tech stack → 2.5 cost → 3 architecture → 4 doc generation → 5 iteration → 6 post-gen setup → optional 7 plan handoff.
- **Universal kickoff** (Q1–Q8) that classifies any project type before branching to type-specific drill-downs.
- **Project-type taxonomy** covering 18 top-level types: web app, mobile, multi-platform, API, CLI, library, desktop, browser extension, game, AI/ML, data pipeline, embedded/IoT, infrastructure, Claude Code plugin, MCP server, Web3, scientific code, AR/VR.
- **5 subagents**: `research-scout`, `document-author`, `decision-revisor`, `claude-md-author`, `claude-tooling-author`. Each dispatched with `model: "opus"` and a max-effort prompt header.
- **Research-augmented questioning**: end-of-phase + on-demand ad-hoc web research via `research-scout`. Findings persisted to `docs/research/`.
- **Architecture Decision Records (ADRs)**: every major decision filed as a sequentially-numbered ADR in `docs/decisions/`. Never reused; supersession chain forms the audit trail.
- **Iteration with consequence propagation**: `decision-revisor` agent reads `revision-playbook.md` to rewrite all affected docs when a decision changes; files a new ADR superseding the prior.
- **Hybrid versioning**: in-place edits + git history + opt-in snapshot bundles in `docs/versions/v<X.Y>/` + ADRs.
- **Per-folder CLAUDE.md** generation for monorepo subdirectories with materially different conventions.
- **Generated `.claude/` directory**: `settings.json` (model: opus 1M, stack-aware permissions, hook wiring), `hooks/` (lint/test/secret-scan scripts), `agents/` (project-specific subagents), `commands/` (project slash commands), `recommended-plugins.md`.
- **Auto-commit cadence**: per batch / per artifact / per phase, via `commit-commands:commit`.
- **Model + effort + 1M-context enforcement** at preflight; `update-config` invocation to set project-local defaults.
- **Optional Phase 7 handoff** to `superpowers:writing-plans` for implementation planning.
- **Resumable state** in `docs/_architect_state.json` with a concurrency lockfile.

### Changed

- SKILL.md restructured from inline workflow to slim orchestrator (~200 lines) that loads references on demand.
- `references/questioning-flow.md` restructured: universal kickoff + per-type drill-down sections.
- `references/tech-stack-options.md` expanded with more options per category.
- Templates moved from monolithic `references/document-templates.md` to one file per template under `references/templates/` (~56 files).

### Removed

- `references/document-templates.md` (content split into `references/templates/*.md`).

## [1.0.0] — 2026-05-01

- Initial release. 3-phase interview (vision, tech stack, architecture deep dive), monolithic template file, generates docs/ and CLAUDE.md.
