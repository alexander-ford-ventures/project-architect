# project-architect (v2.0)

A Claude Code plugin that bootstraps a new project end-to-end.

## What it does

`project-architect` is an **orchestrator skill** that walks the user through
9 phases — from "I want to build X" to "here are docs, CLAUDE.md, .claude/
config, ADRs, and an optional implementation plan, all committed."

| Phase | What happens |
|---|---|
| Preflight | Verify Opus 4.7 (1M context) at max effort |
| 0a Repo init (optional) | `git init` + `gh repo create` |
| 0 Universal kickoff | Classify the project (Q1–Q8) + first research dispatch |
| 1 Vision & Scope | Type-specific drill-down + end-of-phase research |
| 2 Tech Stack | Type-aware option presentation + ADR per major decision |
| 2.5 Cost Modeling | Pricing research → `COST_MODEL.md` |
| 3 Architecture Deep Dive | Per-area drill-downs + inline consistency check |
| 4 Document Generation | Parallel `document-author` × N + CLAUDE.md + `.claude/` config |
| 5 Iteration | Decision-revisor loop, snapshot option |
| 6 Post-Generation Setup | Plugin install offers, push, bootstrap commands |
| 7 Plan Handoff (optional) | Invoke `superpowers:writing-plans` |

## Plugin layout

- `.claude-plugin/{plugin,marketplace}.json` — plugin manifest.
- `skills/project-architect/SKILL.md` — orchestrator (~450-650 lines).
- `skills/project-architect/references/` — 7 reference files including `templates/` (~56 docs).
- `agents/` — 5 subagents dispatched by the orchestrator.

## Install

This marketplace is registered under the alias `local` in
`~/.claude/plugins/known_marketplaces.json`. The plugin is enabled via
`~/.claude/settings.json` under `enabledPlugins["project-architect@local"]`.

## Dependencies

**Required:**
- `commit-commands@claude-plugins-official` (used for auto-commit cadence).

**Recommended:**
- `superpowers` (for the optional `writing-plans` handoff).
- `claude-md-management` (for CLAUDE.md audit).
- `claude-code-setup` (for skill/hook/agent recommendations).
- `hookify` (for hook design principles).
- `document-skills` (for writing-quality principles).
- `fewer-permission-prompts` (used by `claude-tooling-author` to tighten the generated `.claude/settings.json` permissions allowlist).

## Usage

```
/project-architect
```

Or describe what you want to build — e.g. "set up a new project", "scaffold
project docs", "bootstrap a CLI tool", "design the architecture for X" — and
the architect should trigger automatically.

## Versioning policy

Every meaningful change to the skill bumps `plugin.json` and creates a matching git tag. The Preflight `Version freshness check` reads both `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and the latest tag at `siliconyouth/project-architect`; when they diverge, users see a one-line "an update is available" notice with the refresh command.

Procedure for maintainers:

```bash
# 1. Bump plugin.json version (patch / minor / major per semver)
python3 -c "import json,sys; p='.claude-plugin/plugin.json'; d=json.load(open(p)); d['version']=sys.argv[1]; open(p,'w').write(json.dumps(d,indent=2)+'\n')" 2.0.2

# 2. Add a [<version>] block to CHANGELOG.md describing the change

# 3. Commit
git add .claude-plugin/plugin.json CHANGELOG.md
git commit -m "chore(version): bump to 2.0.2"

# 4. Tag (annotated, with release notes from CHANGELOG)
git tag -a v2.0.2 -m "<short summary>"

# 5. Push commits + tag
git push origin main
git push origin v2.0.2

# 6. Refresh local cache so the new version is loaded
claude plugin marketplace update local
claude plugin uninstall project-architect@local
claude plugin install project-architect@local
```

Versioning rules (semver):
- **Patch (`2.0.X`)** — bug fixes, doc tightening, internal refactors with no user-visible behavior change.
- **Minor (`2.X.0`)** — backward-compatible new features (new phase, new agent, new template).
- **Major (`X.0.0`)** — breaking changes (renaming phases, removing decision keys, schema migrations).

## Source

Repo root IS the marketplace root. See `CHANGELOG.md` for version history.
The full v2.0 design spec is at
`docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md`.
