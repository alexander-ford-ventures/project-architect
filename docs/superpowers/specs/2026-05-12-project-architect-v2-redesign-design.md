# project-architect v2.0 redesign — design spec

**Status:** Approved (brainstorming phase complete)
**Date:** 2026-05-12
**Author:** Vladimir Dukelic (with Claude Opus 4.7, 1M context, max effort)
**Supersedes:** project-architect v1.0 (`skills/project-architect/SKILL.md` @ commit ebc1ae2)
**Next step:** Implementation plan via `superpowers:writing-plans`

---

## 1. Motivation

The current `project-architect` skill (v1.0) is a 3-phase interview that produces a static set of architecture docs plus `CLAUDE.md`. It works, but:

- **Ends too soon** — interviews bottom out before nuance is captured; produces generic-feeling docs.
- **No grounding** — every decision is in the model's head; no web research, no prior-art citations, no current-pricing data.
- **Project-type coverage is thin** — taxonomy is mostly web/mobile/CLI; misses Web3, scientific code, AR/VR, MCP servers, Claude Code plugins, embedded, hardware.
- **No iteration model** — no way to revisit a decision and propagate consequences.
- **No audit trail** — no ADRs; revisiting later means re-deriving "why did we choose X?"
- **All work in main session** — no parallelism for doc drafting; main context fills up.
- **No `.claude/` generation** — produces docs but no project-local Claude Code tooling.
- **No commit cadence** — generated artifacts aren't committed during the bootstrap.

This redesign addresses all of the above and lands a fundamentally different skill: an **orchestrator** that dispatches subagents, runs web research at phase boundaries, files ADRs, supports iteration with consequence propagation, and produces both architecture docs *and* full project-local Claude Code config.

## 2. Scope & non-goals

### In scope

- Full plugin restructure: 1 skill + 5 subagents + ~50 reference templates.
- 7-phase bootstrap (preflight + 0a + 0 + 1 + 2 + 2.5 + 3 + 4 + 5 + 6 + optional 7).
- Universal kickoff that classifies any project type.
- Research-augmented questioning (per-phase + on-demand ad-hoc).
- Architecture Decision Records (ADRs) for every major decision.
- Per-folder CLAUDE.md generation when warranted.
- `.claude/` directory generation: settings, hooks, agents, commands, recommended-plugins.
- Iteration phase with consequence propagation via decision-revisor agent.
- Hybrid versioning: in-place + version snapshots + ADRs.
- Auto-commit cadence at batch/artifact granularity.
- Auto-push at phase boundaries.
- Model + effort + context-window enforcement (Opus 4.7 1M, max effort).
- Optional Phase 7 handoff to `superpowers:writing-plans`.

### Non-goals

1. Modify global `~/.claude/settings.json` — only project-local `.claude/settings.json`.
2. Auto-install marketplace plugins — recommend only; user confirms every install.
3. Auto-push without phase awareness — pushes are explicit at phase boundaries.
4. Write production code — Phase 7 is the handoff; implementation belongs to the superpowers chain (writing-plans → executing-plans → TDD → code-review).
5. Run dev server / build / tests — only the opt-in Phase 6 "bootstrap commands" runs `pnpm install` / `cargo new` / equivalent.
6. Generate icons / branding / mockups — covered by `document-skills:frontend-design`, `canvas-design`, etc.; we *recommend*.
7. Manage CI/CD secrets — we document required env vars; user populates them.
8. Validate the stack works (compile/smoke test) — research-scout finds known issues; runtime validation is Phase 7+ territory.
9. Drive day-to-day project evolution — this is a *bootstrap* tool. Normal superpowers flow takes over for features post-Phase 6.
10. Replace user judgment — for every choice, user picks from options. Research-scout supplies context, not verdicts.
11. Talk to Linear / Jira / Notion / Slack directly — recommended via marketplace plugins.
12. Deploy anywhere — we document deployment strategy; actual deploy is recommended via marketplace plugins.

## 3. Plugin layout

```
project-architect/                                  # plugin v2.0.0
├── .claude-plugin/
│   ├── plugin.json                                 # name, version, deps
│   └── marketplace.json
├── README.md
├── CHANGELOG.md
├── skills/
│   └── project-architect/
│       ├── SKILL.md                                # ~215 lines, orchestration only
│       └── references/                             # 6 reference files (2 existing + 4 new)
│           ├── questioning-flow.md                 # EXISTING (restructured)
│           ├── tech-stack-options.md               # EXISTING (expanded)
│           ├── document-catalog.md                 # NEW — meta-index of templates + selection rules
│           ├── research-prompts.md                 # NEW — prompt templates for research-scout
│           ├── revision-playbook.md                # NEW — decision → affected docs map
│           ├── claude-code-integration.md          # NEW — stack → skills/hooks/agents recipes
│           └── templates/                          # ~56 doc templates
│               ├── (Core)                          PROJECT_OVERVIEW.md, PROJECT_REQUIREMENTS.md,
│               │                                   ADR_TEMPLATE.md, REVISION_LOG_FRAGMENT.md,
│               │                                   CLAUDE_MD_ROOT.md, CLAUDE_MD_SUBFOLDER.md
│               ├── (Architecture)                  AUTHENTICATION_SYSTEM.md, DATABASE_DESIGN.md,
│               │                                   API_GATEWAY.md, UI_UX_DESIGN.md, PLATFORMS.md,
│               │                                   SECURITY_AND_COMPLIANCE.md, DEPLOYMENT.md,
│               │                                   CI_CD.md, TESTING_STRATEGY.md,
│               │                                   THIRD_PARTY_INTEGRATIONS.md,
│               │                                   MONITORING_AND_OBSERVABILITY.md
│               ├── (Feature-area)                  BILLING_AND_PAYMENTS.md, EMAIL_AND_NOTIFICATIONS.md,
│               │                                   FILE_STORAGE.md, AI_AND_ML.md, REAL_TIME.md,
│               │                                   SEARCH.md, CACHING_STRATEGY.md,
│               │                                   INTERNATIONALIZATION.md, ACCESSIBILITY.md,
│               │                                   DATA_PIPELINE.md, BACKGROUND_JOBS.md
│               ├── (Project-type-specific)         MOBILE_SPECIFIC.md, DESKTOP_SPECIFIC.md,
│               │                                   EMBEDDED_SPECIFIC.md, ML_OPS.md,
│               │                                   GAME_SPECIFIC.md, BROWSER_EXTENSION.md,
│               │                                   PLUGIN_SPECIFIC.md, HARDWARE_FIRMWARE.md,
│               │                                   WEB3_SPECIFIC.md, SCIENTIFIC_COMPUTING.md,
│               │                                   AR_VR_SPECIFIC.md, MCP_SERVER_SPECIFIC.md
│               ├── (Operations / reliability)      COST_MODEL.md, RUNBOOK.md, INCIDENT_RESPONSE.md,
│               │                                   DISASTER_RECOVERY.md, SLO_AND_ERROR_BUDGETS.md,
│               │                                   THREAT_MODEL.md, BACKUP_AND_DR.md,
│               │                                   PERFORMANCE_BUDGETS.md
│               └── (Process / structural)          ARCHITECTURE_DIAGRAMS.md, SDK_DESIGN.md,
│                                                   TENANT_AND_ORGANIZATION_MODEL.md,
│                                                   EXPERIMENTS.md, ANALYTICS_AND_TELEMETRY.md,
│                                                   ONBOARDING.md, CONTRIBUTING.md, RELEASE_PROCESS.md
└── agents/
    ├── research-scout.md
    ├── document-author.md
    ├── decision-revisor.md
    ├── claude-md-author.md
    └── claude-tooling-author.md
```

### Generated-project output

```
<user-project>/
├── CLAUDE.md                                       # root, always
├── apps/web/CLAUDE.md                              # per-folder, only when warranted
├── packages/crypto/CLAUDE.md
├── .claude/
│   ├── settings.json                               # model: opus 1M, stack-aware permissions, hooks wiring
│   ├── hooks/                                      # stack-aware hooks (lint-on-save, test-on-stop, etc.)
│   ├── agents/                                     # project-specific subagents
│   ├── commands/                                   # project-specific slash commands
│   └── recommended-plugins.md                      # curated marketplace install list
└── docs/
    ├── PROJECT_OVERVIEW.md
    ├── PROJECT_REQUIREMENTS.md
    ├── ... (other generated docs)
    ├── decisions/                                  # ADRs, sequential numbering
    │   ├── 0001-language-runtime.md
    │   └── 0007-revisit-database-choice.md
    ├── research/                                   # research-scout findings, indexed by phase
    │   ├── phase0-domain.md
    │   ├── phase1-scope-realism.md
    │   ├── phase2-stack-combination.md
    │   ├── phase2.5-pricing.md
    │   └── phase3-pattern-validation.md
    ├── versions/                                   # snapshot bundles at user-requested milestones
    │   └── v1.0/
    └── _architect_state.json                       # progress / decisions / lock — deleted at Phase 6 cleanup
```

## 4. Phase model

```
Phase -1.  Preflight                  — model + effort + 1M-context verification
Phase 0a.  Project Setup (optional)   — git init + remote creation
Phase 0.   Universal Kickoff          — Q1–Q8, classify project, dispatch research-scout
Phase 1.   Vision & Scope             — type-specific drill-down + ad-hoc + end research
Phase 2.   Tech Stack                 — type-aware option presentation, ADR per major decision
Phase 2.5. Cost Modeling              — pricing research, draft COST_MODEL data
Phase 3.   Architecture Deep Dive     — per-area drill-downs + inline consistency check
Phase 4.   Document Generation        — parallel agent dispatch (document-author × N + claude-md-author + claude-tooling-author)
Phase 5.   Iteration                  — decision-revisor loop, ADR per change, snapshot option
Phase 6.   Post-Generation Setup      — commit/push, plugin install offer, bootstrap commands
Phase 7.   (optional) Plan Handoff    — invoke superpowers:writing-plans
```

### Phase -1: Preflight

Reads current model from harness env metadata. Requires `claude-opus-4-7[1m]` and effort=max.

- Correct model: proceed silently.
- Right family, wrong variant (e.g., `claude-opus-4-7` without `[1m]`): auto-correct settings via `update-config` skill; prompt user to `/model` and pick the 1M variant for the current session.
- Wrong model entirely: refuse to start; prompt user with explicit instructions for `/model` and `/effort max`.

Effort itself isn't surfaced in env metadata; the architect asks the user to verify `/effort max` is set. As a weaker fallback, every subsequent agent prompt prepended with a "use maximum effort, extended thinking, be thorough" directive.

### Phase 0a: Project Setup (optional)

- Detect existing repo: `git rev-parse --is-inside-work-tree`.
- If not a repo: ask "Initialize git here? yes / yes+remote / no."
- If yes+remote AND `gh auth status` succeeds: ask repo name (default = cwd basename), visibility, description.
- Execute: `git init`, write universal-default `.gitignore` (OS files, editor files, common envs — augmented later in Phase 6 with stack-specific entries), `gh repo create <name> --<vis> --source . --remote origin --description "..."`.
- Initial commit via `commit-commands:commit`: `chore: initialize project repo`.

### Phase 0: Universal Kickoff

Always asked first, in 3 `AskUserQuestion` batches:

| # | Question | Format |
|---|----------|--------|
| 1 | One-sentence elevator pitch — what is it, who's it for, why | open-ended |
| 2 | Top-level project type (taxonomy below) | multiple choice |
| 3 | Sub-type within that category | multiple choice (options depend on Q2) |
| 4 | Project stage — greenfield / extending / rewriting / migrating / PoC only | multiple choice |
| 5 | Primary problem & target users | open-ended |
| 6 | Constraints — budget / regulated / timeline / pre-existing tech / open-source vs proprietary | multi-select |
| 7 | Team & scale — solo / small / larger; hobby / MVP / growth / enterprise | multiple choice |
| 8 | Hard pre-existing decisions ("must be on AWS", "must use Postgres") | open-ended |

After Q8: dispatch `research-scout` for domain research. Findings → `docs/research/phase0-domain.md`.

**Stage detection (Q4) also drives branch strategy** — greenfield commits on `main`; any other stage spawns `bootstrap/architect-YYYY-MM-DD` branch.

### Project type taxonomy (Q2 + Q3)

```
Web application          → SaaS | marketplace | content/blog | dashboard | social | portfolio
                           | internal tool | e-commerce | course/LMS | community forum
                           | wiki/knowledge base | newsletter platform
Mobile application       → consumer | B2B | enterprise | utility | game (→ Game)
                           | health & fitness | finance/banking | productivity
                           | media (streaming/social)
Multi-platform system    → web + mobile + desktop + API combined
API / backend service    → REST | GraphQL | gRPC | WebSocket | event-driven | hybrid
                           | webhook receiver | proxy/gateway | batch processor | scheduled service
CLI tool                 → developer tool | system utility | data/CSV tool | network/security tool
                           | package manager | build tool | scaffolder | REPL | productivity CLI
Library / SDK / package  → SDK for a service | framework | utility lib | type lib
                           | language binding / FFI | code generator | linter/formatter | test library
Desktop application      → macOS | Windows | Linux | cross-platform
                           | full app | menu bar / tray utility | system extension | daemon
Browser extension        → Chrome/Edge | Firefox | Safari | cross-browser
                           | productivity | content filter | DevTools | security/privacy
Game                     → 2D | 3D | mobile | web | console | VR/AR
AI/ML application        → model training | inference serving | RAG | agents | classical ML
                           | computer vision | NLP | recommendation | time-series
                           | reinforcement | multi-modal
Data pipeline / ETL      → batch | streaming | hybrid
                           | ETL | reverse-ETL | CDC | analytics pipeline | feature store
Embedded / firmware/IoT  → MCU class (Cortex-M/RP2/ESP32/STM32) | edge gateway | hardware combo
Infrastructure tool      → IaC | CLI for infra | platform / internal developer platform
                           | cluster operator | observability/monitoring tool | CI/CD tool | networking
Claude Code plugin       → command-focused | skill-focused | agent-focused | full plugin
MCP server               → stdio | HTTP/SSE | Cloudflare Workers | other host
                           | tool-focused | resource-focused | prompt-focused | full
Web3 / smart contracts   → EVM (Solidity) | Solana (Rust/Anchor) | Move (Aptos/Sui) | Cairo (Starknet)
Scientific / research    → numerical sim | data analysis (notebooks) | reproducible study
                           | bioinformatics | geospatial/GIS
AR / VR / spatial        → visionOS | Meta Quest | mobile AR (ARKit/ARCore) | WebXR
Other                    → describe; route to closest neighbor
```

### Phases 1, 2, 2.5, 3 — adaptive batches

Number of batches per phase is **not fixed**; it's bound by what's relevant:

| Phase | Typical batches | Bound by |
|---|---|---|
| Phase 1 Vision | 3–7 | complexity of feature set |
| Phase 2 Tech Stack | 5–10 | applicable categories from catalog (skip the rest) |
| Phase 2.5 Cost | 1–2 | priced services in stack |
| Phase 3 Architecture | 5–12 | applicable areas (auth/db/api/security/frontend/testing/devops/monitoring/integrations) |

Per-phase research:
- End-of-phase: 1 `research-scout` dispatch on phase-specific topic.
- Ad-hoc during phase: when architect detects a red flag (deprecated tool, regulated industry + non-compliant default, vendor-lock on critical path, scaling concern, novel security pattern, cost outlier).

Inline consistency check at end of Phase 3: cross-checks decisions before doc gen. Any contradictions surfaced to user; resolution may dispatch `decision-revisor`.

### Phase 4: Document Generation

- Read `document-catalog.md` to select templates by `generate_when` rules.
- Topologically sort selected templates by `depends_on`.
- Dispatch `document-author` agents in parallel batches of 8.
- In parallel with last doc batch: `claude-md-author` (root + per-folder CLAUDE.md) and `claude-tooling-author` (`.claude/*`).
- ADRs are filed as decisions finalize (during Phase 2 & 3, not Phase 4); doc-gen references existing ADRs.

### Phase 5: Iteration

Decision summary menu:
```
What next?
  (a) Approve all → Phase 6
  (b) Revisit a decision → type its key
  (c) Snapshot current as v1.0 → docs/versions/v1.0/ and continue
  (d) Generate the implementation plan → Phase 7
  (e) Show full decision tree
  (f) Exit (resume later)
```

On `(b)`: capture reason, re-ask the question, dispatch `decision-revisor` with `{key, old, new, reason}`. Revisor rewrites affected docs (per `revision-playbook.md`), appends to revision logs, files new ADR superseding prior. Commit via `commit-commands:commit`.

On `(c)`: copy `docs/*.md` to `docs/versions/v<X.Y>/`, update state, commit.

On `(e)`: print all decisions grouped, with ADR IDs.

### Phase 6: Post-Generation Setup

- Iterate `recommended-plugins.md`: for each, ask `Install plugin X? yes/no/all`. If yes: `claude plugin install <plugin>`.
- If `repo_init && has_remote`: `git push origin <branch>`.
- Ask: "Run project bootstrap commands now? (`pnpm install` / `cargo new` / equivalent)" — yes/no.
- If yes: execute stack-specific commands.
- Final commit via `commit-commands:commit`: `chore: bootstrap complete`.
- Delete `docs/_architect_state.json`. Commit cleanup.

### Phase 7: Implementation Plan Handoff (optional)

Invoke `superpowers:writing-plans` with context: `spec_path=docs/PROJECT_REQUIREMENTS.md`, `state_path=docs/_architect_state.json`. Architect returns control to writing-plans.

## 5. Auto-commit & push cadence

Hybrid commit strategy — per-batch for decisions, per-artifact for docs/ADRs/research.

| Trigger | Commit message pattern | Staged paths |
|---|---|---|
| Phase 0a repo init | `chore: initialize project repo` | `.gitignore`, `README.md` skeleton |
| AskUserQuestion batch returns | `architect(phaseN): record decisions — <topic-summary>` | `docs/_architect_state.json` |
| research-scout returns | `architect(phaseN-research): <topic>` | `docs/research/phaseN-<topic>.md` |
| Doc generated | `docs: generate <DOC_NAME>` | `docs/<DOC>.md` |
| ADR filed | `adr: 00NN <title>` | `docs/decisions/00NN-*.md` |
| Revision | `architect(revise): <decision> — see ADR 00NN` | rewritten docs + new ADR + revision-log entries |
| Per-folder CLAUDE.md | `chore: add CLAUDE.md for <path>` | `<path>/CLAUDE.md` |
| `.claude/` tooling | `chore: add Claude Code project config` | `.claude/**` |
| Version snapshot | `chore: snapshot docs as v<X.Y>` | `docs/versions/v<X.Y>/**` |
| Phase 6 final | `chore: bootstrap complete` | remaining + state.json cleanup |

Mechanism: invoke `commit-commands:commit` skill at every commit point. Fall back to direct `git add` + `git commit -m "..."` only for ADR-style messages with specific patterns.

Push strategy: **default `per_phase`** (push after Phase 0a, 1, 2, 2.5, 3, 4, 5, 6). User can override to `per_commit` or `end_only` via `state.git.push_strategy`.

Branch strategy:
- Greenfield (Phase 0 Q4): commit on `main`.
- Extending / rewriting / migrating: create `bootstrap/architect-YYYY-MM-DD` branch; open PR at Phase 6.

Failure handling:
- Commit fails (e.g., pre-commit hook): surface error, ask user; never retry with `--no-verify`.
- Push fails: commit locally, queue retry at next phase boundary.
- Repo not initialized (user said "no" at Phase 0a): skip all git steps; state notes `repo_init: false`.

## 6. Model, effort, & 1M-context enforcement

| Requirement | Value |
|---|---|
| Model | `claude-opus-4-7` (family identifier) |
| Context variant | `[1m]` |
| Effort | `max` |

### Preflight detection & correction

1. Read current model from harness env metadata.
2. If `claude-opus-4-7[1m]`: proceed.
3. If right family, wrong variant: invoke `update-config` to set `model: claude-opus-4-7` and `env.ANTHROPIC_CONTEXT_VARIANT: "1m"` in global settings (takes effect next session); for current session, prompt user to `/model` switch.
4. If wrong model entirely: refuse to start; prompt with `/model` and `/effort max` instructions; wait for "continue" confirmation.

Effort isn't surfaced in env metadata; architect asks user to verify `/effort max`. Best-effort fallback: every agent prompt prepended with a "use maximum effort, extended thinking, be thorough" directive.

### Subagent dispatch envelope

Every `Agent` tool call from the orchestrator:
```json
{
  "subagent_type": "project-architect:<agent-name>",
  "model": "opus",
  "description": "<3-5 word task>",
  "prompt": "[MODEL DIRECTIVE]\nRun with maximum effort. Apply extended thinking. Be thorough.\n\n[CONTEXT]\n...\n[TASK]\n...\n[OUTPUT]\n..."
}
```

Notes:
- `model: "opus"` constrains family, not variant. The Agent tool's enum is `"sonnet" | "opus" | "haiku"`. Subagents inherit the harness's variant configuration; as long as parent is on `claude-opus-4-7[1m]`, subagents land on the same variant.
- Effort isn't an Agent-tool parameter. Propagated via prompt header.
- Skill-tool invocations (e.g., `commit-commands:commit`) run in parent context — model preflight ensures inheritance.

### Generated-project model defaults

Architect writes to project's `.claude/settings.json`:
```json
{
  "model": "claude-opus-4-7",
  "env": { "ANTHROPIC_CONTEXT_VARIANT": "1m" },
  "permissions": { "allow": [/* stack-aware */] },
  "hooks": { /* stack-aware */ }
}
```

`recommended-plugins.md` mentions `/effort max` as a per-session step.

### Failure modes

| Situation | Behavior |
|---|---|
| `update-config` not available | Fall back to user-prompt |
| User declines to switch model | Refuse to start with clear message |
| Mid-session user `/model`-switches to weaker model | Architect detects at phase boundary; pauses, re-prompts |
| `gh` not installed AND preflight fails | Surface both issues at once |

## 7. Subagent contracts

All five agents share the dispatch envelope above. Each lives in `agents/<name>.md` with frontmatter:
```yaml
---
name: <agent-name>
description: <when this agent is dispatched>
tools: [WebSearch, WebFetch, Read, Write, Grep, Bash, ...]
model: opus
---
```

### Agent 1 — `research-scout`

| Field | Value |
|---|---|
| Trigger | End of phases 0/1/2/2.5/3 + ad-hoc red-flag |
| Inputs | topic, project-context snapshot, specific questions, recency window, output file path |
| Tools | WebSearch, WebFetch, Read, Write, Grep, Bash (read-only) |
| Skills used | none — pure search + synthesis |
| Output | Writes `docs/research/<topic>.md`. Returns ≤20-line summary. |
| Dispatch | 1–3 parallel per phase boundary; 1 at a time for ad-hoc |

System prompt outline: "You research similar projects, best practices, and pitfalls. Cite URLs. Prefer recent sources (< recency_floor). Output sections: Summary / Similar projects / Best practices / Pitfalls / Production issues / Emerging alternatives / Implications for this project / Sources. Make 'Implications' crisp — one bullet per implication, naming the decision/question affected."

### Agent 2 — `document-author`

| Field | Value |
|---|---|
| Trigger | Phase 4 doc-gen, one dispatch per applicable doc |
| Inputs | template name, full `state.json` (or relevant slice), research findings paths, output path, cross-references |
| Tools | Read, Write, Edit, Grep, Bash (read-only) |
| Skills used | none — *reads* `document-skills:doc-coauthoring` SKILL.md as a reference for writing principles, doesn't invoke |
| Output | Writes `docs/<DOC>.md`. Optionally writes an ADR for a decision finalized during drafting. Returns 1-line confirmation + ADR ID if any. |
| Dispatch | Massively parallel; batches of 8 |

System prompt outline: "Write ONE doc from the template, populated with project-specific decisions. No boilerplate. Every section must contain real decisions or be omitted. Concise, specific, scannable, active voice. Cite decision rationale inline. Cross-link to other docs by relative path. End with `## Revision Log` (`(none yet)` for first version)."

### Agent 3 — `decision-revisor`

| Field | Value |
|---|---|
| Trigger | Phase 5 iteration, one dispatch per user-requested change |
| Inputs | decision key, old value, new value, reason, current state.json, `revision-playbook.md` |
| Tools | Read, Write, Edit, Glob, Grep, Bash |
| Skills used | none directly (reads `revision-playbook.md` for propagation rules) |
| Output | Modified docs, new ADR, updated state.json. Returns: file list + ADR ID. |
| Dispatch | Sequential (one revision at a time, user-driven) |

System prompt outline: "A decision changed. Look up the decision key in revision-playbook.md to find affected docs. For each affected doc: rewrite affected sections surgically (don't churn unrelated content), append a Revision Log entry. File a new ADR documenting: prior decision, new decision, reason, alternatives reconsidered, consequences, rollback plan. Update state.json. Never break cross-references."

### Agent 4 — `claude-md-author`

| Field | Value |
|---|---|
| Trigger | Phase 4, parallel with `claude-tooling-author` |
| Inputs | full decisions context, project structure (subdirs warranting their own CLAUDE.md), all generated doc paths |
| Tools | Read, Write, Edit, Glob, Bash, Skill |
| Skills used | `claude-md-management:claude-md-improver` (audit pass after writing each file) |
| Output | `/CLAUDE.md` + sub-CLAUDE.md files. Returns file list + audit results. |
| Dispatch | 1 — handles all CLAUDE.md files internally |

System prompt outline: "Write root `/CLAUDE.md`: concise project overview, tech stack table, structure, dev commands, conventions, key architectural decisions (one-line each), links to `docs/`. Identify subdirectories with materially different conventions and write one CLAUDE.md per. Each per-folder focuses on what differs from root. After each write, invoke `claude-md-improver` to audit; apply improvements until it passes."

Per-folder CLAUDE.md gating triggers (explicit, in the system prompt):
- Different primary language vs root
- Different test framework
- Different deploy target
- Different conventions explicitly recorded in state (e.g., `frontend.framework: Next.js` for `apps/web/` vs `language.primary: Rust` for `packages/crypto/`)
- Substantial enough to warrant its own context — heuristic: ≥10 source files OR ≥1 significant subsystem.

### Agent 5 — `claude-tooling-author`

| Field | Value |
|---|---|
| Trigger | Phase 4, parallel with `claude-md-author` |
| Inputs | full decisions context, tech stack, project type, generated doc paths |
| Tools | Read, Write, Edit, Glob, Bash, Skill |
| Skills used | `update-config`, `hookify:writing-rules`, `fewer-permission-prompts`, `claude-code-setup:claude-automation-recommender` |
| Output | All `.claude/*` files. Returns file list + reasoning summary. |
| Dispatch | 1 — handles all `.claude/*` internally |

System prompt outline: "Write the `.claude/` directory: (1) `settings.json` with `model: claude-opus-4-7`, `env.ANTHROPIC_CONTEXT_VARIANT=1m`, stack-aware permissions allowlist, stack-aware hook wiring. (2) `hooks/` — one script per hook event (post-tool-use: format on save; stop: ensure last test run was green; pre-tool-use: block dangerous commands). (3) `agents/` — project-specific subagents (test-runner with project test command, migration-checker, deploy-verifier). (4) `commands/` — slash commands (`/feature`, `/run-tests`, `/deploy-preview`). (5) `recommended-plugins.md` — curated marketplace list with install commands. Consult `references/claude-code-integration.md` for stack → skill mapping."

## 8. Template library + doc selection

### Template file format

Each template in `references/templates/<NAME>.md` has YAML frontmatter:

```yaml
---
template_name: AUTHENTICATION_SYSTEM
generate_when: "decisions.auth.enabled == true"
required_decisions:
  - auth.provider
  - auth.methods
  - auth.session_strategy
optional_decisions:
  - auth.oauth_providers
  - auth.multi_tenancy
depends_on:
  - SECURITY_AND_COMPLIANCE
  - DATABASE_DESIGN
revision_triggers:
  - auth.provider
  - auth.methods
  - auth.session_strategy
  - auth.multi_tenancy
---
```

Body uses placeholder syntax (`{{key}}`, `{{#if optional}}...{{/if}}`) as a hint for the document-author agent — not a literal templating engine. The agent fills in based on `state.json`, omits sections that don't apply, expands sections that need more depth.

### Document catalog (`references/document-catalog.md`)

```markdown
# Document Catalog

## Selection rules (pseudocode)
def select_templates(state):
    selected = list(ALWAYS_TEMPLATES)
    for template in CONDITIONAL_TEMPLATES:
        if matches(template.generate_when, state):
            selected.append(template)
    return topological_sort(selected, key="depends_on")

## Always: PROJECT_OVERVIEW, PROJECT_REQUIREMENTS, CLAUDE_MD_ROOT

## Type-anchored (at least one selected per top-level type)
| Project type | Anchored templates |
|---|---|
| Web app | UI_UX_DESIGN |
| Mobile app | MOBILE_SPECIFIC + PLATFORMS (if cross-platform) |
| Multi-platform | PLATFORMS |
| API | API_GATEWAY |
| CLI | (no anchor) |
| Library/SDK | SDK_DESIGN |
| Desktop | DESKTOP_SPECIFIC |
| Browser extension | BROWSER_EXTENSION |
| Game | GAME_SPECIFIC |
| AI/ML | AI_AND_ML + ML_OPS |
| Data pipeline | DATA_PIPELINE |
| Embedded/IoT | EMBEDDED_SPECIFIC (+ HARDWARE_FIRMWARE if hw combo) |
| Infrastructure | DEPLOYMENT + CI_CD anchored |
| Claude Code plugin | PLUGIN_SPECIFIC |
| MCP server | MCP_SERVER_SPECIFIC |
| Web3 | WEB3_SPECIFIC + THREAT_MODEL |
| Scientific | SCIENTIFIC_COMPUTING |
| AR/VR | AR_VR_SPECIFIC (+ MOBILE_SPECIFIC if mobile-AR) |

## Conditional matrix (excerpt)
| Template | Generated when |
|---|---|
| AUTHENTICATION_SYSTEM | decisions.auth.enabled |
| DATABASE_DESIGN | decisions.database.engine != null |
| BILLING_AND_PAYMENTS | decisions.monetization.enabled |
| INTERNATIONALIZATION | decisions.i18n.languages.length > 1 |
| THREAT_MODEL | decisions.security.formal_threat_model OR decisions.regulated_industry |
| COST_MODEL | decisions.scale != "hobby" OR managed_services_in_stack |
| DISASTER_RECOVERY | decisions.scale >= "growth" AND production_bound |
| TENANT_AND_ORGANIZATION_MODEL | decisions.multi_tenancy |
| SDK_DESIGN | project_type == "library" OR exposes_sdk |
```

### Dependency / generation order (topological)

```
PROJECT_OVERVIEW
└─ PROJECT_REQUIREMENTS
   ├─ AUTHENTICATION_SYSTEM
   ├─ DATABASE_DESIGN
   ├─ API_GATEWAY ← depends on AUTH, DATABASE
   ├─ UI_UX_DESIGN
   ├─ PLATFORMS
   ├─ SECURITY_AND_COMPLIANCE ← depends on AUTH, DATABASE
   ├─ TESTING_STRATEGY
   ├─ DEPLOYMENT
   ├─ CI_CD ← depends on TESTING_STRATEGY, DEPLOYMENT
   └─ MONITORING_AND_OBSERVABILITY
      ↓
CLAUDE_MD_ROOT (depends on all)
```

### Revision playbook (`references/revision-playbook.md`)

Decision → affected docs map. Powers `decision-revisor`'s propagation logic:

| Decision key | Affected docs |
|---|---|
| auth.provider | AUTHENTICATION_SYSTEM, SECURITY_AND_COMPLIANCE, API_GATEWAY*, CLAUDE_MD_ROOT |
| auth.methods | AUTHENTICATION_SYSTEM, UI_UX_DESIGN* |
| auth.session_strategy | AUTHENTICATION_SYSTEM, SECURITY_AND_COMPLIANCE |
| database.engine | DATABASE_DESIGN, API_GATEWAY, BACKUP_AND_DR, COST_MODEL, CLAUDE_MD_ROOT |
| database.orm | DATABASE_DESIGN, API_GATEWAY, CLAUDE_MD_ROOT |
| frontend.framework | UI_UX_DESIGN, DEPLOYMENT, CI_CD, CLAUDE_MD_ROOT |
| backend.framework | API_GATEWAY, DEPLOYMENT, CI_CD, CLAUDE_MD_ROOT |
| hosting.frontend | DEPLOYMENT, CI_CD, COST_MODEL |
| hosting.backend | DEPLOYMENT, CI_CD, COST_MODEL, MONITORING_AND_OBSERVABILITY |
| ... | ... |

`*` = "regenerate only if section X exists" (conditional propagation).

### Template authoring guidelines

1. Frontmatter required for every template.
2. Body uses placeholder syntax as a hint, not strict spec.
3. Sections gated by `optional_decisions` keys wrapped in `{{#if ...}}` conditionals as visual cue.
4. Cross-references use **template name** (not final filename); agent resolves at write time.
5. Every body ends with `## Revision Log` (empty `(none yet)` at first write).
6. Templates do NOT duplicate content from other templates; cross-link instead.

### Adding new templates over time

When architect detects a gap during Phase 3 ("project has concern X but no template covers it"), offers to:
- Create the doc inline (one-off)
- AND save a reusable template to the catalog
- Adding to catalog: drop file in `references/templates/`, add entry to `document-catalog.md` and `revision-playbook.md` if relevant. Single plugin commit, no SKILL.md change.

## 9. Research integration + ADR loop

### Research prompt templates (`references/research-prompts.md`)

**Phase 0 — Domain research:**
> "Research the project domain: (1) 3–5 similar existing projects (commercial or OSS) with one-line summaries, (2) common pitfalls for [project_type/subtype], (3) regulatory implications for [target_users + domain], (4) market context. Cite URLs. Market data must be < 12 months old; foundational pitfalls can be older."

**Phase 1 — Scope realism:**
> "For an MVP with [features] at [scale] built by [team_size]: (1) which features are typically v1 vs deferred in similar projects, (2) which are over-scoped (often cut), (3) which are under-scoped (need supporting features), (4) timeline benchmarks. Cite specific projects."

**Phase 2 — Stack combination gotchas:**
> "For this stack: [full_stack], find: (1) known integration gotchas between these specific tools, (2) version compatibility issues, (3) production issues reported in last 12 months, (4) emerging alternatives gaining traction. Cite docs and GitHub issues."

**Phase 2.5 — Pricing research:**
> "For these managed services [services] at [usage_tier], find: (1) base tier costs, (2) per-unit costs (egress, requests, storage), (3) commonly-forgotten line items, (4) free tier limits. Cite official pricing pages, recency floor 6 months. Estimate $/month at MVP / growth / enterprise."

**Phase 3 — Pattern validation:**
> "For this architecture: [decisions_summary], find: (1) prior-art projects using similar patterns and how they scaled, (2) anti-patterns to avoid for this combination, (3) OSS reference implementations worth studying, (4) production failure modes. Cite incidents and post-mortems where possible."

**Ad-hoc — Red-flag triggers:**

| Trigger | Prompt |
|---|---|
| Deprecated tool mentioned | "Is [tool] deprecated/sunsetting? Recommended successor? Migration cost?" |
| Regulated industry + non-compliant default | "What [GDPR/HIPAA/PCI-DSS/SOC2] requirements does this approach violate? Specific remediations?" |
| Critical-path vendor lock | "Migration cost off [vendor]? Portability patterns?" |
| Scaling ceiling concern | "Known scaling limits for [tool] at [scale]?" |
| Novel security architecture | "Cryptographic/security weaknesses in this approach? Audit findings?" |
| Cost outlier | "Why is [service] significantly more expensive than alternatives at [scale]?" |

### Research output format

`docs/research/<phase>-<topic>.md`:
```markdown
---
phase: 2
topic: stack-combination
dispatched_at: 2026-05-12T14:30:00Z
queries: [...]
recency_floor: 2025-05-01
---

# Research: Stack Combination

## Summary
{{3–5 sentence executive summary}}

## Similar projects / prior art
- [Project](url) — what they did, what worked, what didn't

## Known integration gotchas
- {{issue}} — citation

## Production issues (last 12 months)
- {{issue}} — date, severity, status, citation

## Emerging alternatives
- {{alternative}} — why it's gaining traction

## Implications for this project          ← architect reads this first
- {{actionable implication}} — drives question Y or revisits decision Z

## Sources
- [Title](url) — accessed 2026-05-12
```

### ADR format

`docs/decisions/NNNN-<slug>.md`:
```markdown
---
adr_id: 0007
title: Revisit database choice — Postgres → SQLite + Turso
date: 2026-05-12
status: accepted              # proposed | accepted | superseded | deprecated
supersedes: 0003              # null if first decision on this key
superseded_by: null           # filled when a future ADR supersedes this one
affected_docs: [...]
decision_keys: [database.engine, database.host]
research_refs: [...]
---

# ADR 0007: ...

## Status
## Context
## Prior decision (ADR 0003)
## New decision
## Alternatives reconsidered
## Consequences
## Rollback plan
## References
```

Numbering: sequential from 0001, never reused. Next ID tracked in `state.json.next_adr_id`. Slug = kebab-case of title, ≤60 chars.

ADRs filed:
- Phase 2: one ADR per major tech-stack decision (language, framework, db, auth, host).
- Phase 3: one ADR per architecture area (auth flow, multi-tenancy model, API style, etc.).
- Phase 5: new ADR superseding prior on every revision.
- Trivial choices (e.g., pnpm vs npm for solo dev): no ADR — keep the trail signal-rich.

### Iteration UX details

See Section 4 (Phase 5).

Edge cases handled by iteration loop:
- Revisit X with dependents whose ADRs were earlier: revisor regenerates docs *and* updates the prior ADRs' `superseded_by` to point at new ADR.
- Multiple revisions in one iteration session: one revisor dispatch per change; one ADR each; one commit each.
- Revert: new ADR supersedes prior (the original ADR isn't re-activated — trail stays linear).
- Snapshot v1.0 → 5 revisions → wholesale revert: `cp docs/versions/v1.0/*.md docs/` (architect offers), file ADR explaining the revert.

## 10. Skill composition

### Invoked at runtime

| Skill | Phase | Why |
|---|---|---|
| `update-config` | -1, 4 | Set/verify global model; design generated project's `.claude/settings.json` |
| `commit-commands:commit` | every commit point | Auto-commit cadence |
| `claude-md-management:claude-md-improver` | 4 (inside `claude-md-author`) | Audit each generated CLAUDE.md |
| `hookify:writing-rules` | 4 (inside `claude-tooling-author`) | Design `.claude/hooks/` scripts |
| `fewer-permission-prompts` | 4 (inside `claude-tooling-author`) | Build `.claude/settings.json` permissions allowlist |
| `claude-code-setup:claude-automation-recommender` | 4 (inside `claude-tooling-author`) | Curate `recommended-plugins.md` |
| `superpowers:writing-plans` | 7 (optional) | Final handoff |

### Referenced (read, not invoked)

| Skill | Read by | Why |
|---|---|---|
| `document-skills:doc-coauthoring` | `document-author` | Technical-writing principles (non-interactive use) |
| `document-skills:docx` | `document-author` | Structural conventions |
| `superpowers:brainstorming` | architect | Pattern inspiration |
| `plugin-dev:plugin-structure` | `document-author` (only when `project_type == Claude Code plugin`) | Fill PLUGIN_SPECIFIC.md |
| `mcp-server-dev:build-mcp-server` | `document-author` (only when `project_type == MCP server`) | Fill MCP_SERVER_SPECIFIC.md |

### Plugin dependencies (`plugin.json`)

```json
{
  "name": "project-architect",
  "version": "2.0.0",
  "dependencies": {
    "commit-commands": "*"
  },
  "softDependencies": {
    "superpowers": "*",
    "claude-md-management": "*",
    "claude-code-setup": "*",
    "hookify": "*",
    "document-skills": "*"
  }
}
```

Hard dependencies: startup check, bail if missing. Soft: checked at point of use; if missing, internal fallback + note in `recommended-plugins.md`.

### Recommended skills for generated projects (`claude-code-integration.md` excerpt)

Universal:
- `superpowers:brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `using-git-worktrees`
- `claude-md-management:revise-claude-md`, `claude-md-improver`

Conditional on stack:
- Cloudflare → `cloudflare:cloudflare`, `wrangler`, `durable-objects`, `workers-best-practices`, `agents-sdk` (if agents)
- Supabase → `supabase:supabase`, `supabase-postgres-best-practices`
- Vercel/Next.js → `vercel:nextjs`, `vercel-cli`, `next-cache-components`, `react-best-practices`, `shadcn` (if shadcn/ui)
- AWS → `aws-dev-toolkit:aws-architect` + service-specific (`lambda`, `ec2`, `eks`, `s3`, `dynamodb`, `bedrock`)
- Azure → `azure:azure-prepare`, `azure-deploy` + service-specific
- Expo/RN → `expo:building-native-ui`, `expo-deployment`, `upgrading-expo`, `native-data-fetching`
- Auth0 → `auth0:auth0-quickstart` + stack-specific
- Stripe → `stripe:stripe-best-practices`
- Playwright → `playwright-cli:playwright-cli`
- HuggingFace/ML → `huggingface-skills:huggingface-llm-trainer`, `transformers-js`, `huggingface-datasets`
- Figma → `figma:figma-use`, `figma-implement-design`, `figma-code-connect`
- MCP server → `mcp-server-dev:build-mcp-server`, `document-skills:mcp-builder`
- Mintlify → `mintlify:mintlify`
- Atlassian → `atlassian:*`
- Slack → `slack:slack-messaging`, `slack-search`
- Astronomer/Airflow → `astronomer-data:*`
- Datadog → `datadog:ddsetup`, `ddconfig`
- Sourcegraph → `sourcegraph:searching-sourcegraph`
- (full table maintained in `references/claude-code-integration.md`)

Conditional on project type:
- Claude Code plugin → `plugin-dev:*` (create-plugin, plugin-structure, skill-development, agent-development, command-development, hook-development, mcp-integration)
- Skill → `document-skills:skill-creator`, `skill-creator:skill-creator`
- UI-heavy → `document-skills:frontend-design`, `web-artifacts-builder`, `theme-factory`
- Documentation-heavy → `document-skills:doc-coauthoring`, `internal-comms`, `mintlify:mintlify`

Quality/process:
- `coderabbit:code-review`, `semgrep:setup-semgrep-plugin`, `chrome-devtools-mcp:debug-optimize-lcp`, `cloudflare:web-perf`, `superpowers:dispatching-parallel-agents`, `subagent-driven-development`

## 11. State management

### Schema (full)

```json
{
  "schema_version": "2.0",
  "plugin_version": "2.0.0",
  "started_at": "2026-05-12T14:00:00Z",
  "last_updated_at": "2026-05-12T16:30:00Z",

  "phase": "preflight | phase_0a | phase_0 | phase_1 | phase_2 | phase_2.5 | phase_3 | phase_4 | phase_5 | phase_6 | phase_7 | complete",
  "current_doc_version": "1.0",
  "snapshots": ["v1.0"],

  "git": {
    "repo_init": true,
    "has_remote": true,
    "remote_url": "git@github.com:owner/repo.git",
    "branch": "main",
    "push_strategy": "per_phase"
  },

  "model_state": {
    "verified_at_startup": true,
    "model_id": "claude-opus-4-7[1m]",
    "effort": "max",
    "warnings": []
  },

  "decisions": {
    "project.name": "...",
    "project.type": "...",
    "project.subtype": "...",
    "project.stage": "...",
    "project.target_users": "...",
    "project.scale": "...",
    "project.constraints": [...],
    "language.primary": "...",
    "frontend.framework": "...",
    "database.engine": "...",
    "auth.provider": "...",
    "...": "..."
  },

  "phase_progress": {
    "preflight":  { "complete": true,  "completed_at": "..." },
    "phase_0a":   { "complete": true,  "completed_at": "..." },
    "phase_0":    { "complete": true,  "completed_at": "..." },
    "phase_1":    { "complete": true,  "batches_completed": 4 },
    "phase_2":    { "complete": false, "batches_completed": 2, "categories_remaining": [...] },
    "phase_2.5":  { "complete": false },
    "phase_3":    { "complete": false, "areas_remaining": [...] },
    "phase_4":    { "complete": false, "docs_remaining": [...] },
    "phase_5":    { "complete": false, "revisions_made": 0 },
    "phase_6":    { "complete": false, "plugins_installed": [...] },
    "phase_7":    { "complete": false, "handoff_invoked": false }
  },

  "documents_pending": [...],
  "documents_generated": [{ "name": "...", "path": "...", "version": "1.0", "generated_at": "..." }],

  "adrs_filed": [{ "id": "0001", "title": "...", "date": "...", "status": "accepted", "supersedes": null }],
  "next_adr_id": "0007",

  "research_findings": [{ "phase": "...", "topic": "...", "file": "...", "dispatched_at": "..." }],

  "recommended_plugins": [{ "name": "...", "reason": "...", "installed": false }],

  "lock": { "pid": 42, "host": "macbook-air", "acquired_at": "..." }
}
```

### Resume mechanics

On every invocation:
1. Check `docs/_architect_state.json`.
2. If exists: validate schema version, check lock (warn if held by different pid > 30 min ago = stale, offer clear), re-run preflight (model/effort), print resume summary, jump to right phase.
3. If not exists: start at Phase -1.

State committed at every batch checkpoint. State deleted at end of Phase 6 cleanup. To re-bootstrap: `rm docs/_architect_state.json` and re-invoke; existing docs become reference material.

## 12. Failure modes & recovery

| Failure | Recovery |
|---|---|
| User exits mid-phase | State saved at every batch; resume reads state, prints summary, continues. |
| Agent dispatch fails / malformed output | Retry once with clarification; if still failing, fall back to inline completion (architect drafts the doc itself). |
| Commit fails (hook rejects) | Surface error, ask user; never `--no-verify`. |
| Push fails | Commit locally, queue push for next phase boundary. |
| Required dep missing (`commit-commands`) | Refuse to start with clear error. |
| Soft dep missing | Continue with fallback; note in `recommended-plugins.md`. |
| User said "no" to repo init then tries to commit | Detect at next commit attempt; offer to init now. |
| Two terminals running architect concurrently | Lock file detects; prompts user to clear if stale. |
| Mid-session model switch to weaker model | Detect at phase boundary; pause, re-prompt. |
| `gh` not authed | Skip remote creation; document in state; user can add remote later. |

## 13. Open issues (to resolve during writing-plans)

1. `AskUserQuestion` is a deferred tool — implementation must `ToolSearch` it at startup; define fallback for environments where it's unavailable (plain text prompts).
2. `gh auth status` exit code as detection mechanism — confirm exact bail-out behavior.
3. State trimming for agent dispatch — define per-agent slices so we don't pass full 5–20 KB state to every agent.
4. Plugin install state detection — verify required/soft deps are *enabled*, not just installed.
5. Auto-memory integration — decide whether architect writes a project entry to user's memory system at Phase 6, or leaves it to user.
6. Marketplace volatility — set "review `claude-code-integration.md` every minor version" reminder in CHANGELOG.md.
7. `AskUserQuestion` wrapper abstraction — clean interface so swapping is mechanical.
8. State migration across plugin versions — define migration path policy.
9. Concurrency lock — file path / timeout policy needs spec (proposed: `docs/_architect_state.lock`, 30-min stale window).
10. Phase 7 handoff format — confirm `superpowers:writing-plans` expected context shape.
11. Per-folder CLAUDE.md gating logic — concrete triggers listed (Section 7 `claude-md-author`); refine during plan.
12. Research recency policy — parameterize in `research-prompts.md` so tuning is easy.
13. Plugin dependency declaration syntax — verify Claude Code plugin spec supports `dependencies`/`softDependencies`; if not, fall back to runtime checks.

## 14. Implementation handoff

Next step: invoke `superpowers:writing-plans` to convert this design into an executable plan with:
- Discrete tasks per agent file, per template, per reference file
- Dependency ordering so we don't author downstream pieces before their upstream foundations
- Verification steps per task (mostly "does the architect still work end-to-end after this change?")
- Worktree strategy if appropriate (`superpowers:using-git-worktrees`)
- Test strategy — at minimum, manual smoke test of a small project bootstrap; ideally a few archetypal project types (CLI, web app, plugin) to exercise the type-branching.

## Revision Log

(none yet)
