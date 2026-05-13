<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# Changelog

All notable changes to the `project-architect` plugin.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.2.0 — 2026-05-13

Major architectural release. Implements the four validation sketches + cross-language CLI-UX picker designed during the md2pdf live test (see `docs/tests/2026-05-13-md2pdf-live-test-report.md`).

### Added

- **Sketch B**: New `quality-gate-auditor` agent runs 16 cross-cutting checks after Phase 4 closes. Findings auto-seed the Phase 5 iteration menu. Catches all 13 known live-test bugs plus 1 future code-emission class.
- **Sketch C**: Per-agent runtime budget frontmatter on all 6 agents. Orchestrator wraps every dispatch with an observer that surfaces "silent for too long" and "over budget" warnings. Never auto-kills — observation only. Telemetry feeds future tuning.
- **Sketch D**: Multi-session lifecycle redesign. Phase 4 now generates 4 plan docs (CLAUDE_MD_PLAN, CLAUDE_TOOLING_PLAN, SCAFFOLD_PLAN, NEXT_STEP_PLAN) instead of producing tooling/code directly. New Phase 7 executes plans (claude-md-author and claude-tooling-author refactored to consume plan docs as input). New Phase 8 hands off via CLAUDE.md as router with 3 slash commands (`/scaffold`, `/implement`, `/iterate-design`). Adds `state.locked / version / locked_at` fields and per-phase memory persistence (8-9 memory writes per architect run for cross-session continuity).
- **Sketch A**: Inline validators in `claude-tooling-author` (shellcheck, jq, python yaml). Catches malformed `.sh`/`.json` at write-time before declaring done.
- **Sketch E**: Per-language CLI-UX library picker added to Phase 2 (Rust ratatui/inquire/indicatif/owo-colors, Go bubbletea/lipgloss, Python textual/rich, Node ink/clack, Ruby TTY, C# Spectre.Console + Terminal.Gui). New `CLI_UX_DESIGN.md` template.

### Changed

- Phase 4 no longer generates `CLAUDE.md` or `.claude/*` directly — those move to Phase 7.
- Phase 6 LOCK now snapshots state to `docs/versions/{version}/` and sets `state.locked = true`. Does NOT delete state.json (continuing v2.1.5's bug-#14 fix).
- `claude-md-author` and `claude-tooling-author` now consume plan docs as input rather than reading state directly.
- `state.json` schema gains `locked`, `version`, `locked_at`, `memory_pointer`, `phase_progress[].prerequisites_satisfied`.
- Phase enum extended with `phase_7` and `phase_8`.

### Phase boundary gates

`state.phase_progress[N].prerequisites_satisfied` blocks downstream agent dispatch until upstream phase signals are met. Specifically: Phase 4 won't dispatch document-author until Phase 3's pattern-validation research has returned. Catches the live-test bug-#4 (research dispatched in parallel with Phase 4).

### Migration

Existing v2.1.x users: state.json schema is forward-compatible. New fields default to safe values. The plugin will offer to migrate at startup if it sees a v2.1.x state.

### Test coverage

Full TDD coverage in `tests/`. Run `bash tests/run_all.sh` to verify. 54 test files covering all 16 auditor checks, runtime budgets, plan templates, slash commands, state lifecycle, memory persistence, cross-language CLI-UX picker, and end-to-end Rust/Python/Go fixtures.

## v2.1.5 — 2026-05-13

Tactical fixes for bugs surfaced during the md2pdf live test (see `docs/tests/2026-05-13-md2pdf-live-test-report.md`). Larger architectural improvements ship in v2.2.

### Fixed

- **bug #1** — `state.schema_version` now correctly initializes to `"2.0"` (state-schema version), separate from `state.plugin_version` which carries the plugin's semver. Previously `schema_version` was incorrectly set to the plugin version.
- **bug #2** — All timestamps in `state.json` now use ISO8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`). Previously `started_at` could be written as a date-only string.
- **bug #5** — Phase 4 template selection now force-includes the union of every ADR's `affected_docs`, intersected with the catalog. Previously, ADR-promised docs could be skipped if their `generate_when` expression didn't match.
- **bug #7** — `claude-md-author` and `claude-tooling-author` now use `architect(phase-N): ...` commit subjects instead of `chore: ...`, matching the orchestrator's convention.
- **bug #9** — `decision-revisor` agent prompt now includes explicit scope discipline + cost-budget guidance to prevent runtime overruns on surgical patches.
- **bug #14** — Phase 6 no longer deletes `docs/_architect_state.json`. The state file is preserved as the canonical entry point for future re-invocations (and for `/iterate-design` in v2.2). Only the lockfile is released.

### Added

- Universal CLI-UX gate question in Phase 1 for CLI/TUI projects (sketch E micro-portion). Asks whether the tool is one-shot, interactive prompts, full TUI, or hybrid; routes follow-up questions accordingly. Per-language library picker ships in v2.2.

### Test infrastructure

- New `tests/` directory with shared `lib/test_helpers.sh` and `run_all.sh` runner. Every v2.1.5 fix has a corresponding `tests/test_v215_*.sh` file.

## [2.1.4] — 2026-05-12

### Changed

- **Template footer glyph**: `✨` (sparkle) → `★` (black star) across all 55 user-facing templates. Aligns the markdown-footer attribution with the existing social-preview image attribution (which already used the star glyph). README's Attribution section now explicitly notes the convention: generated-doc footer links to `project-architect` (the skill); the social-preview image credits `Claude Code` (the platform). The link target in the markdown footer is unchanged — still `https://github.com/siliconyouth/project-architect`.

## [2.1.3] — 2026-05-12

### Added

- **Silicon Youth logo** in the social-preview image's top-left publisher line, replacing the `▲` Unicode placeholder. SVG is now tracked at `.github/assets/silicon-youth-logo.svg`; the generator (`.github/social-preview.py`) re-tints the dark-fill SVG to accent blue at render time so it sits cleanly on the dark canvas. Adds `cairosvg` as an optional dependency of the generator script (only needed for regenerating the preview, not for using the skill).

## [2.1.2] — 2026-05-12

### Changed

- **Social-preview image redesigned**: footer right-side now reads "★ Skillfully made with Claude Code" (proper star glyph instead of the previous `*` fallback). The "try it →" inline CTA was removed; replaced with a dedicated pill-shaped **Install →** button in the top-right corner — higher click-conversion shape with dark-on-blue contrast.

## [2.1.1] — 2026-05-12

### Added

- **GitHub social-preview image** (`.github/social-preview.png`, 1280×640 PNG, dark theme, generated by `.github/social-preview.py`). Embedded at the top of README.md for landing-page impact. Regenerable on each release by re-running the script.

## [2.1.0] — 2026-05-12

### Added

- **Modern README** with badges, mermaid architecture diagram, terminal "screenshot" code blocks showing the live UX, comprehensive project-types list, and recommended-plugins table.
- **GitHub repo hardening**: `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`, `config.yml`; `.github/pull_request_template.md`; `CONTRIBUTING.md`.
- **Template beautification** for generated docs: status callout under H1, table-of-contents on long docs, judicious section-emoji prefixes (🎯 🏗️ 🔐 🗄️ 🌐 🎨 🚀 🧪 📊 💰 🔧 ⚙️ 📝 🚦 ↻), Revision Log rendered as a table, "✨ Skillfully made with…" footer (sparkle prefix).

### Changed

- **Marketplace description** rewritten for public release. Now reads: "Public marketplace by Silicon Youth, featuring project-architect — an orchestrator skill that bootstraps any project type with research-augmented questioning, ADR-tracked decisions, parallel doc generation, and project-local Claude Code configuration."

## [2.0.5] — 2026-05-12

### Added

- **MIT LICENSE**.
- **Author attribution comment block** added to every text file in the repo (after YAML frontmatter where applicable, at top otherwise). Carries name, email, repo URL, license.
- **"Skillfully made with…" footer** appended to every doc template so generated user-project docs (PROJECT_OVERVIEW, CLAUDE.md, all architecture docs, etc.) automatically include downstream attribution.
- **Attribution policy + License section** in README.md explaining the social-norm attribution and the MIT terms.

### Changed

- `plugin.json` and `marketplace.json` now declare `license: MIT` and `repository: https://github.com/siliconyouth/project-architect` as standard manifest fields.

## [2.0.4] — 2026-05-12

### Changed

- **Marketplace renamed from `local` to `siliconyouth`** to match the GitHub org. The plugin now surfaces as `project-architect@siliconyouth`. **Breaking change for install commands**: anyone with the marketplace registered under the old `local` alias must re-register under `siliconyouth` (see migration below).

### Migration

```bash
# Refresh + re-register the marketplace
claude plugin marketplace remove local
claude plugin marketplace add siliconyouth/project-architect

# Reinstall the plugin from the renamed marketplace
claude plugin uninstall project-architect@local
claude plugin install project-architect@siliconyouth

# Reload in any active Claude session
/reload-plugins
```

## [2.0.3] — 2026-05-12

### Fixed

- **`commit-commands` dependency resolved to wrong marketplace** (`/doctor` flagged this as a missing-dep error). Bare-string dependencies (`"dependencies": ["commit-commands"]`) resolve to `commit-commands@<same-marketplace-as-this-plugin>` = `commit-commands@siliconyouth`, which doesn't exist. The actual installation lives in `commit-commands@claude-plugins-official`. Changed to the object form `{ "name": "commit-commands", "marketplace": "claude-plugins-official" }` per the canonical Claude Code plugin schema.

### Notes

- Bare strings in `dependencies` work only when the dep ships from the same marketplace as the dependent plugin. For cross-marketplace deps (the common case for plugins reusing Anthropic's official skills), use the object form with explicit `marketplace`.

## [2.0.2] — 2026-05-12

### Added

- **Preflight `Cache hygiene` step**. After the version-freshness check, the architect now proactively removes stale plugin-cache version directories (sibling dirs to `${CLAUDE_PLUGIN_ROOT}`) so future sessions can't accidentally load an older cached version. Replaces the manual `rm -rf` step that used to be in the README versioning-policy procedure.

### Fixed

- **`.remember/logs/` and `.gitignore` for the plugin's own repo**. The architect SKILL pre-creates `.remember/logs/` in Preflight for *generated projects*, but the plugin's own repo (`/Users/vladimir/projects/project-architect/`) was missing both the directory and a `.gitignore`. Anyone working on the architect's own files would see hook-error spam from the `remember` plugin. Added a repo-level `.gitignore` (with `.remember/` listed) and pre-created the empty `.remember/logs/` dir locally.

## [2.0.1] — 2026-05-12

### Fixed

- **Plugin manifest schema conformance** (`1be648b`). `dependencies` was an object map (npm-style); now the canonical array form per the Claude Code plugin schema. Removed `softDependencies` (unrecognized key); recommendations now surface via README, runtime Preflight check, and generated `recommended-plugins.md`. Added a top-level marketplace `description`.
- **`phase_-1` enum mismatch** (`c731879`). The Soft-dependency check saved `state.phase = "phase_-1"`, inconsistent with the canonical phase enum (`"preflight"`). Resume after a Preflight abort would have no matching case. Renamed to `"preflight"` everywhere.
- **Missing `Skill` tool grants** (`c731879`). `claude-md-author` and `claude-tooling-author` agent bodies invoke other skills but `Skill` wasn't in their tools array. Added.

### Added

- **`references/state-schema.md`** (`d1446ac`). Canonical runtime reference for `state.json`: schema, lockfile protocol, migration policy. Replaces the workaround that pointed SKILL.md at the design spec.
- **Soft-dependency Preflight check** (`6eb14a9`, `23cd200`). Lists 6 recommended plugins at startup, scans for missing ones, offers install. Replaces the dropped `softDependencies` manifest field.
- **`.remember/logs/` auto-creation** (`baf31ac`, `675b6d7`). Preflight's first step now `mkdir -p .remember/logs` to silence the `remember` plugin's PostToolUse hook when it's installed. Also adds `.remember/` to the universal-default `.gitignore` Phase 0a writes.
- **Version freshness check** (`cd54887`). Preflight compares `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` against `gh release view --repo siliconyouth/project-architect`; warns if loaded < latest. Best-effort; silently skips if `gh` missing, no network, or no releases.
- **Manual test plan** (`715bca0`). 5 scenarios covering CLI bootstrap, Claude Code plugin bootstrap, iteration/revision, resumability, and snapshot versioning.
- **As-built corrections appendix** (`3992cb6`) on the v2.0 design spec and implementation plan, documenting deltas between design-time assumptions and shipped behavior.

### Changed

- **Preflight subsection order**: `Ambient hooks tolerance` → `Model/effort verification` → `Soft-dependency check` → `Version freshness check`. The mkdir runs first so the `remember` plugin's hook never sees a missing log dir.
- **Doc consistency** (`23cd200`): README, spec, and plan all reference 6 recommended plugins. Test plan corrected re: `/plugin` not showing versions.

### Removed

- `softDependencies` field from `plugin.json` (unrecognized by schema).
- "Soft dep missing" row from the failure-modes table (replaced by proactive Preflight handling).

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
