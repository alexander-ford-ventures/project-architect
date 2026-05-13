<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

<p align="center">
  <img src=".github/social-preview.png" alt="project-architect — Bootstrap any project end-to-end inside Claude Code · Skillfully made with Claude Code" width="100%" />
</p>

<div align="center">

# project-architect

**An orchestrator skill that bootstraps any project end-to-end inside Claude Code.**

From _"I want to build X"_ to _"docs, CLAUDE.md, ADRs, and a `.claude/` config — all committed."_

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/siliconyouth/project-architect?include_prereleases&label=release)](https://github.com/siliconyouth/project-architect/releases)
[![Stars](https://img.shields.io/github/stars/siliconyouth/project-architect?style=social)](https://github.com/siliconyouth/project-architect)
[![Last commit](https://img.shields.io/github/last-commit/siliconyouth/project-architect)](https://github.com/siliconyouth/project-architect/commits/main)
[![Plugin validate](https://img.shields.io/badge/plugin%20validate-✓%20passing-success)](.claude-plugin/plugin.json)
[![Tests](https://img.shields.io/badge/tests-54%20files%20·%20passing-success)](tests/)

</div>

---

## What's new in v2.2.0 _(2026-05-13)_

Major architectural release. Four validation sketches + a cross-language CLI-UX picker, all designed during the md2pdf live test and now shipped as a single coherent bundle. See the [full live-test report](docs/tests/2026-05-13-md2pdf-live-test-report.md), the [sketches spec](docs/superpowers/specs/2026-05-13-v2.2-validation-sketches.md), and [CHANGELOG.md](CHANGELOG.md) for the unabridged release notes.

| Sketch | What it ships |
|---|---|
| **B** quality-gate-auditor | New 6th subagent. Runs 16 cross-cutting checks (link integrity, ADR coverage, shellcheck, JSON validity, hierarchy, attribution, placeholders, TODOs, YAML frontmatter, schema version, ISO8601 timestamps, state drift, numerical consistency, phase-prerequisite gates). Findings auto-seed the Phase 5 iteration menu. |
| **C** runtime budgets | Per-agent `runtime_budget` frontmatter on all 6 agents. Orchestrator observer surfaces "silent for too long" and "over budget" warnings — observation only, never auto-kills. |
| **D** multi-session lifecycle | Phase 4 now emits 4 plan docs (CLAUDE_MD_PLAN, CLAUDE_TOOLING_PLAN, SCAFFOLD_PLAN, NEXT_STEP_PLAN). New Phase 7 executes plans. New Phase 8 hands off via CLAUDE.md router with 3 slash commands (`/scaffold`, `/implement`, `/iterate-design`). Per-phase memory persistence + `state.locked/version/locked_at` for cross-session continuity. |
| **A** inline validators | `claude-tooling-author` now runs shellcheck on `.sh`, `jq` on `.json`, and `python -c yaml.safe_load` on `.yml` before declaring done. Catches malformed tooling at write-time. |
| **E** CLI-UX picker | Phase 2 per-language library picker: Rust (ratatui/inquire/indicatif/owo-colors), Go (bubbletea/lipgloss), Python (textual/rich), Node (ink/clack), Ruby (TTY), C# (Spectre.Console + Terminal.Gui). New `CLI_UX_DESIGN.md` template. Builds on v2.1.5's universal CLI-UX gate question. |

**Phase boundary gates** — `state.phase_progress[N].prerequisites_satisfied` blocks downstream dispatch until upstream phases finish. Catches the live-test bug-#4 class (research dispatched in parallel with Phase 4).

**Migration from v2.1.x** — state.json schema is forward-compatible. New fields default to safe values. The plugin offers to migrate at startup if it sees a v2.1.x state.

**Test coverage** — 55 test files covering all 16 auditor checks, runtime budgets, plan templates, slash commands, state lifecycle, memory persistence, cross-language CLI-UX picker, and end-to-end Rust/Python/Go fixtures.

```bash
bash tests/run_all.sh
# Test files passed: 54 · All tests passed.
```

<details>
<summary>v2.1.5 — tactical fixes _(2026-05-13)_</summary>

Fixes for 6 bugs surfaced during the md2pdf live test:

| Bug | Fix |
|---|---|
| **#1** state.schema_version conflated with plugin version | `schema_version` now correctly initializes to literal `"2.0"`, separate from `state.plugin_version` |
| **#2** date-only timestamps | All `state.json` timestamps now use ISO8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`) |
| **#5** ADR-promised docs sometimes missed | Phase 4 now force-includes the union of every ADR's `affected_docs`, intersected with the catalog |
| **#7** wrong commit-subject prefix from agents | `claude-md-author` and `claude-tooling-author` now use `architect(phase-N): ...` instead of `chore: ...` |
| **#9** `decision-revisor` cost overruns | Agent prompt now has explicit scope discipline + `PARTIAL_COMPLETION` escape hatch |
| **#14** state.json deleted at Phase 6 | State file is now preserved as the canonical re-invocation entry point; only the lockfile is released |

Plus: Universal CLI-UX gate question in Phase 1 (the per-language library picker shipped in v2.2 above).

</details>

---

## What it does

`project-architect` is a Claude Code **orchestrator skill** that walks you through **9 phases** — from the elevator pitch to a fully-committed project with architecture docs, ADRs, per-folder `CLAUDE.md`, and a stack-aware `.claude/` configuration.

Under the hood it dispatches **5 specialized subagents** (research-scout, document-author, decision-revisor, claude-md-author, claude-tooling-author) in parallel where it's safe, files Architecture Decision Records as the interview progresses, and ends with an optional handoff to `superpowers:writing-plans` for an MVP implementation plan.

## Quick start

```bash
# 1. Add this marketplace to your Claude Code installation
claude plugin marketplace add siliconyouth/project-architect

# 2. Install the plugin
claude plugin install project-architect@siliconyouth

# 3. Verify (optional)
claude plugin validate

# 4. In a fresh project dir, start a Claude Code session and invoke
cd ~/your-new-project
claude
```

Then inside Claude:

```
/effort max
/model       → Opus 4.7 (1M context)
/project-architect
```

## What it looks like

**Preflight banner (silent on a healthy setup):**

```console
$ /project-architect

✓ Preflight (v2.2.0)
  ✓ Model: claude-opus-4-7[1m]   ✓ Effort: max
  ✓ Recommended plugins: 6/6
  ✓ Version freshness: current
  ✓ Cache hygiene: clean
```

**Universal Kickoff (3 batches of multi-choice questions):**

```console
Phase 0 — Universal Kickoff

? One-sentence elevator pitch:
› A CLI to convert markdown files to PDF.

? Top-level project type:
  ○ Web application
  ● CLI tool / Developer tool
  ○ Mobile application
  ○ Library / SDK / package
  ○ Claude Code plugin
  ... (14 more)

? Sub-type:
  ● Developer tool
  ○ System utility
  ○ Data/CSV tool
  ○ Package manager / Build tool / Scaffolder
  ...
```

**Research-augmented questioning (between phases):**

```console
[research-scout] Phase 0 domain research dispatched...
  → docs/research/phase0-domain.md  (3 similar projects, 5 pitfalls, 2 implications)

Implications for this project:
• Pandoc-based pipelines dominate; printpdf is the modern Rust-native alternative
• Bundle size matters for `cargo install` — keep static deps lean
• Most similar tools skip stdin → align (decision recorded in ADR 0003)
```

**Iteration menu (Phase 5):**

```console
✓ Bootstrap complete.

  ┌─ DECISIONS ────────────────────────────────────────────┐
  │  Tech stack                                              │
  │    • Language: Rust (ADR 0001)                          │
  │    • CLI framework: clap (ADR 0002)                     │
  │    • PDF: printpdf (ADR 0003)                           │
  │  Generated: 14 docs · 6 ADRs · 4 research findings      │
  └──────────────────────────────────────────────────────────┘

? What next?
  ● (a) Approve all → Phase 6
  ○ (b) Revisit a decision
  ○ (c) Snapshot current as v1.0
  ○ (d) Generate the implementation plan
  ○ (e) Show full decision tree
  ○ (f) Exit (resume later)
```

## Phases at a glance

| # | Phase | What happens |
|---|---|---|
| -1 | **Preflight** | Verify Opus 4.7 (1M context) at max effort. Auto-fix `.remember/logs/`. Check soft-deps. Compare cached version to latest release. Clean stale cache dirs. |
| 0a | **Repo Init** _(optional)_ | `git init` and optionally `gh repo create`. |
| 0 | **Universal Kickoff** | 3 batches of multi-choice questions (Q1–Q8). Classifies the project type. Dispatches the first research-scout. |
| 1 | **Vision & Scope** | Type-specific drill-down. Ad-hoc + end-of-phase research. |
| 2 | **Tech Stack** | Type-aware option presentation. ADR per major decision. End-of-phase research on stack gotchas. |
| 2.5 | **Cost Modeling** | Pricing research → `COST_MODEL.md` data. |
| 3 | **Architecture Deep Dive** | Per-area drill-downs + inline consistency check. |
| 4 | **Document Generation** | Parallel `document-author` × N + `claude-md-author` + `claude-tooling-author`. |
| 5 | **Iteration** | Decision-revisor loop, snapshot option, or proceed. |
| 6 | **Post-Generation Setup** | Plugin install offers, push, optional `cargo new` / `pnpm install`. |
| 7 | **Plan Handoff** _(optional)_ | Hand off to `superpowers:writing-plans` for MVP plan. |

## Architecture

```mermaid
flowchart LR
    User([User]) --> SKILL[SKILL.md Orchestrator]
    SKILL --> Phase0[Phase 0<br/>Universal Kickoff]
    Phase0 --> Phase123[Phases 1-3<br/>Vision · Stack · Architecture]
    Phase123 --> Research[research-scout<br/>per phase + ad-hoc]
    Phase123 --> Phase4[Phase 4<br/>Doc Generation]
    Phase4 --> DocAgents[document-author × N<br/>parallel batches]
    Phase4 --> MdAgent[claude-md-author<br/>root + per-folder]
    Phase4 --> ToolAgent[claude-tooling-author<br/>.claude/ config]
    Phase4 --> Phase5[Phase 5<br/>Iteration]
    Phase5 -->|revise| Revisor[decision-revisor<br/>+ ADR supersession]
    Phase5 -->|approve| Output([Generated Project])
    Output --> Docs[docs/<br/>+ ADRs<br/>+ research/]
    Output --> Claude[CLAUDE.md<br/>+ per-folder]
    Output --> ClaudeConfig[.claude/<br/>settings · hooks · agents · commands]
```

## What it generates

```text
<your-project>/
├── CLAUDE.md                           ← root, loaded into every Claude session
├── apps/web/CLAUDE.md                  ← per-folder when conventions differ
├── packages/crypto/CLAUDE.md
├── .claude/
│   ├── settings.json                   ← model: opus 1M, stack-aware permissions, hooks
│   ├── hooks/                          ← lint-on-save, test-on-stop, dangerous-command guard
│   ├── agents/                         ← test-runner, migration-checker, deploy-verifier
│   ├── commands/                       ← /feature, /run-tests, /deploy-preview
│   └── recommended-plugins.md
└── docs/
    ├── PROJECT_OVERVIEW.md             ← master hub
    ├── PROJECT_REQUIREMENTS.md
    ├── AUTHENTICATION_SYSTEM.md        ← when auth.enabled
    ├── DATABASE_DESIGN.md              ← when DB present
    ├── API_GATEWAY.md                  ← when building an API
    ├── ... 40+ more conditional templates
    ├── decisions/                      ← ADRs, sequential, supersession-chain audit trail
    │   ├── 0001-language-runtime.md
    │   └── 0007-revisit-database-choice.md
    ├── research/                       ← findings from research-scout
    │   ├── phase0-domain.md
    │   └── phase2-stack-combination.md
    └── versions/                       ← snapshot bundles at milestones
        └── v1.0/
```

## Project types supported (18+)

- Web app (SaaS / marketplace / dashboard / e-commerce / community / wiki / newsletter / portfolio / internal tool)
- Mobile (consumer / B2B / enterprise / health / finance / productivity / media)
- Multi-platform system (web + mobile + desktop + API)
- API service (REST / GraphQL / gRPC / WebSocket / event-driven / webhook / proxy / scheduled)
- CLI tool (developer / system utility / data / network-security / package manager / build / scaffolder / REPL)
- Library / SDK (service SDK / framework / utility / type lib / FFI / code-gen / linter / test lib)
- Desktop (macOS / Windows / Linux / cross-platform / menu bar / system extension / daemon)
- Browser extension (Chrome / Firefox / Safari / cross-browser)
- Game (2D / 3D / mobile / web / console / VR-AR)
- AI/ML (training / inference / RAG / agents / vision / NLP / recommendation / time-series / RL / multi-modal)
- Data pipeline (batch / streaming / ETL / reverse-ETL / CDC / analytics / feature store)
- Embedded / IoT (Cortex-M / RP2 / ESP32 / STM32 / edge gateway / hardware combo)
- Infrastructure tool (IaC / CLI / IDP / cluster operator / observability / CI/CD)
- **Claude Code plugin** (commands / skills / agents / hooks / full)
- **MCP server** (stdio / HTTP-SSE / Cloudflare Workers / other)
- Web3 / smart contracts (EVM / Solana / Aptos-Sui / Starknet)
- Scientific computing (numerical / data analysis / reproducible / bio / GIS)
- AR / VR / spatial (visionOS / Quest / mobile AR / WebXR)

## Recommended plugins (Preflight auto-detects)

| Plugin | Role |
|---|---|
| `commit-commands` _(required)_ | Auto-commit cadence per batch / artifact / phase |
| `superpowers` | Optional Phase 7 handoff to `writing-plans` |
| `claude-md-management` | Audits the generated `CLAUDE.md` files |
| `claude-code-setup` | Source of stack → skill recommendations |
| `hookify` | Hook authoring patterns for generated `.claude/hooks/` |
| `document-skills` | Writing-quality conventions absorbed by `document-author` |
| `fewer-permission-prompts` | Tightens the generated `.claude/settings.json` permissions allowlist |

## Tests

`tests/` ships with the plugin. Each v2.1.5 bug fix has a corresponding `tests/test_v215_*.sh`. The infrastructure is:

```text
tests/
├── lib/test_helpers.sh          ← shared assert_eq, assert_contains, assert_file_exists, etc.
├── run_all.sh                   ← discovers and runs every test_*.sh
├── test_v215_state_schema.sh
├── test_v215_iso8601_timestamps.sh
├── test_v215_affected_docs_enforcement.sh
├── test_v215_decision_revisor_scope.sh
├── test_v215_commit_subjects.sh
├── test_v215_cli_ux_gate.sh
├── test_v215_no_state_deletion.sh
└── test_v215_version_bump.sh
```

Run the full suite:

```bash
bash tests/run_all.sh
```

Tests are pure Bash (using the helpers in `lib/test_helpers.sh`) and assert against the actual plugin files (`SKILL.md`, `agents/*.md`, `references/*.md`, `.claude-plugin/plugin.json`). No external test framework needed; only `bash`, `jq`, and the standard Unix toolchain.

## Versioning policy

Every change bumps `plugin.json` and creates a matching tag. See [CHANGELOG.md](CHANGELOG.md) for the full history.

Procedure for maintainers:

```bash
# 1. Bump plugin.json
python3 -c "import json,sys; p='.claude-plugin/plugin.json'; d=json.load(open(p)); d['version']=sys.argv[1]; open(p,'w').write(json.dumps(d,indent=2)+'\n')" 2.1.1

# 2. Add a [<version>] block to CHANGELOG.md

# 3. Commit, tag, push
git add .claude-plugin/plugin.json CHANGELOG.md
git commit -m "chore(release): bump to 2.1.1"
git tag -a v2.1.1 -m "..."
git push origin main && git push origin v2.1.1

# 4. Refresh local cache (only needed if you're testing your own change locally)
claude plugin marketplace update siliconyouth
claude plugin uninstall project-architect@siliconyouth
claude plugin install project-architect@siliconyouth
```

Semver rules: **patch** = bug fix / doc / refactor; **minor** = backward-compatible feature; **major** = breaking change.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow. PRs welcome; for substantial changes, open an issue first.

## Attribution

When you use `project-architect`, the generated docs end with:

> *★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*

This is a social-norm attribution — please keep it visible in `PROJECT_OVERVIEW.md`, `CLAUDE.md`, and other top-level docs so others can discover the tool. The MIT license doesn't legally require this, but it's a polite norm and costs you nothing.

If you fork the skill itself or build on top of it, the source-file attribution comments must remain per the MIT terms (the LICENSE file must be included in any redistribution).

> **Note:** the social-preview image (`.github/social-preview.png`) carries a different attribution line — `★ Skillfully made with Claude Code` — to credit the underlying platform. That line is image-only; the markdown footer that ships in generated docs uses "project-architect" as shown above.

## License

[MIT](LICENSE) — © 2026 Vladimir Dukelic / Silicon Youth.

## Source

This repo is its own Claude Code marketplace. The plugin manifest is at `.claude-plugin/plugin.json`; the orchestrator skill body is at `skills/project-architect/SKILL.md`; references and templates live under `skills/project-architect/references/`; subagents live under `agents/`.

The full v2.0 design spec is at [`docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md`](docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md) and the implementation plan at [`docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md`](docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md). Reading those is the fastest way to understand *how* it was built — and the strongest signal that this isn't a toy.
