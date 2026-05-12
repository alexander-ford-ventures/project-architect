# project-architect v2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the project-architect skill from a 3-phase interview that produces static docs into an orchestrator that dispatches 5 subagents across 9 phases, runs web research at phase boundaries, files ADRs, supports iteration with consequence propagation, and generates docs + per-folder CLAUDE.md + project-local `.claude/` config.

**Architecture:** One slim orchestrator skill (~200-line SKILL.md) calls into 6 reference files and dispatches 5 subagents in parallel where possible. Templates (~56 files) live under `references/templates/` and are loaded on-demand. State persists in `docs/_architect_state.json`. Every commit goes through `commit-commands:commit`.

**Tech Stack:** Markdown + YAML frontmatter (no executable code in the plugin itself). Claude Code plugin packaging conventions. `gh` CLI for remote repo creation. `git` for commits. `Agent` tool for subagent dispatch (with `model: "opus"` + max-effort prompt header). `Skill` tool for invoking other skills.

**Source spec:** `docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md` (918 lines, committed as `0075964`).

---

## File Structure

### New files (created by this plan)

```
project-architect/
├── CHANGELOG.md                                         [Phase A]
├── agents/
│   ├── research-scout.md                                [Phase D]
│   ├── document-author.md                               [Phase D]
│   ├── decision-revisor.md                              [Phase D]
│   ├── claude-md-author.md                              [Phase D]
│   └── claude-tooling-author.md                         [Phase D]
└── skills/project-architect/references/
    ├── document-catalog.md                              [Phase B]
    ├── research-prompts.md                              [Phase B]
    ├── revision-playbook.md                             [Phase B]
    ├── claude-code-integration.md                       [Phase B]
    └── templates/                                       [Phase C — 56 files]
        ├── PROJECT_OVERVIEW.md
        ├── PROJECT_REQUIREMENTS.md
        ├── ADR_TEMPLATE.md
        ├── REVISION_LOG_FRAGMENT.md
        ├── CLAUDE_MD_ROOT.md
        ├── CLAUDE_MD_SUBFOLDER.md
        ├── AUTHENTICATION_SYSTEM.md, DATABASE_DESIGN.md, API_GATEWAY.md, UI_UX_DESIGN.md,
        │   PLATFORMS.md, SECURITY_AND_COMPLIANCE.md, DEPLOYMENT.md, CI_CD.md,
        │   TESTING_STRATEGY.md, THIRD_PARTY_INTEGRATIONS.md, MONITORING_AND_OBSERVABILITY.md
        ├── BILLING_AND_PAYMENTS.md, EMAIL_AND_NOTIFICATIONS.md, FILE_STORAGE.md, AI_AND_ML.md,
        │   REAL_TIME.md, SEARCH.md, CACHING_STRATEGY.md, INTERNATIONALIZATION.md,
        │   ACCESSIBILITY.md, DATA_PIPELINE.md, BACKGROUND_JOBS.md
        ├── MOBILE_SPECIFIC.md, DESKTOP_SPECIFIC.md, EMBEDDED_SPECIFIC.md, ML_OPS.md,
        │   GAME_SPECIFIC.md, BROWSER_EXTENSION.md, PLUGIN_SPECIFIC.md, HARDWARE_FIRMWARE.md,
        │   WEB3_SPECIFIC.md, SCIENTIFIC_COMPUTING.md, AR_VR_SPECIFIC.md, MCP_SERVER_SPECIFIC.md
        ├── COST_MODEL.md, RUNBOOK.md, INCIDENT_RESPONSE.md, DISASTER_RECOVERY.md,
        │   SLO_AND_ERROR_BUDGETS.md, THREAT_MODEL.md, BACKUP_AND_DR.md, PERFORMANCE_BUDGETS.md
        └── ARCHITECTURE_DIAGRAMS.md, SDK_DESIGN.md, TENANT_AND_ORGANIZATION_MODEL.md,
            EXPERIMENTS.md, ANALYTICS_AND_TELEMETRY.md, ONBOARDING.md, CONTRIBUTING.md,
            RELEASE_PROCESS.md
```

### Modified files

```
project-architect/
├── .claude-plugin/
│   ├── plugin.json                                      [Phase A — bump to 2.0.0, add deps]
│   └── marketplace.json                                 [Phase A — update description]
├── README.md                                            [Phase A — describe v2]
└── skills/project-architect/
    ├── SKILL.md                                         [Phase E — rewrite top-to-bottom]
    └── references/
        ├── questioning-flow.md                          [Phase B — restructure for universal kickoff + per-type]
        └── tech-stack-options.md                        [Phase B — expand]
```

### Deleted files

```
skills/project-architect/references/document-templates.md   [Phase C — content split into templates/]
```

### Phase dependency graph

```
A. Plugin scaffolding (3 tasks, sequential)
  └─→ B. References (6 tasks; B1, B2 sequential; B3–B6 parallel-eligible)
        └─→ C. Templates (6 tasks; all parallel-eligible)
              └─→ D. Subagents (5 tasks; all parallel-eligible)
                    └─→ E. Orchestrator SKILL.md (3 tasks, sequential)
                          └─→ F. Verification (2 tasks)
                                └─→ G. Wrap (1 task)
```

Total: **26 tasks**. Parallel-eligible: 4 in B + all 6 in C + all 5 in D = **15 tasks dispatchable concurrently in batches**.

---

## Phase A — Plugin scaffolding

### Task A1: Bump plugin version and add dependencies

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: Read existing plugin.json**

Run: `cat .claude-plugin/plugin.json`
Expected: shows `"version": "1.0.0"` and minimal fields.

- [ ] **Step 2: Replace plugin.json**

Overwrite `.claude-plugin/plugin.json` with:

```json
{
  "name": "project-architect",
  "version": "2.0.0",
  "description": "Project architecture orchestrator. Interviews across 9 phases (preflight → repo init → kickoff → vision → tech stack → cost → architecture → docs → iteration → setup → optional plan), dispatches research-scout / document-author / decision-revisor / claude-md-author / claude-tooling-author subagents, files ADRs, generates docs + per-folder CLAUDE.md + .claude/ project config.",
  "author": {
    "name": "Vladimir Dukelic",
    "email": "vladimir@dukelic.com"
  },
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

- [ ] **Step 3: Replace marketplace.json**

Overwrite `.claude-plugin/marketplace.json` with:

```json
{
  "$schema": "https://code.claude.com/schemas/marketplace.json",
  "name": "local",
  "owner": {
    "name": "Vladimir Dukelic",
    "email": "vladimir@dukelic.com"
  },
  "plugins": [
    {
      "name": "project-architect",
      "source": "./",
      "description": "Project architecture orchestrator with research-augmented questioning, ADR-tracked decisions, parallel doc generation, per-folder CLAUDE.md, and .claude/ project tooling. Supports web apps, mobile, CLI, libraries, APIs, multi-platform, desktop, browser extensions, games, AI/ML, data pipelines, embedded, infrastructure, Claude Code plugins, MCP servers, Web3, scientific code, AR/VR, and more."
    }
  ]
}
```

- [ ] **Step 4: Verify JSON is well-formed**

Run: `python3 -m json.tool .claude-plugin/plugin.json && python3 -m json.tool .claude-plugin/marketplace.json`
Expected: both pretty-print without error.

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "$(cat <<'EOF'
chore(plugin): bump to v2.0.0 and declare dependencies

Hard dep: commit-commands (auto-commit cadence).
Soft deps: superpowers, claude-md-management, claude-code-setup,
hookify, document-skills.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task A2: Create CHANGELOG.md

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Write CHANGELOG.md**

Create `CHANGELOG.md` at plugin root with:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "$(cat <<'EOF'
docs: add CHANGELOG with v2.0.0 release notes

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task A3: Update README.md and create directory scaffolding

**Files:**
- Modify: `README.md`
- Create (empty directories): `agents/`, `skills/project-architect/references/templates/`

- [ ] **Step 1: Replace README.md**

Overwrite `README.md` with:

```markdown
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
- `skills/project-architect/SKILL.md` — orchestrator (~200 lines).
- `skills/project-architect/references/` — 6 reference files including `templates/` (~56 docs).
- `agents/` — 5 subagents dispatched by the orchestrator.

## Install

This marketplace is registered under the alias `local` in
`~/.claude/plugins/known_marketplaces.json`. The plugin is enabled via
`~/.claude/settings.json` under `enabledPlugins["project-architect@local"]`.

## Dependencies

**Required:**
- `commit-commands` (used for auto-commit cadence).

**Recommended:**
- `superpowers` (for the optional `writing-plans` handoff).
- `claude-md-management` (for CLAUDE.md audit).
- `claude-code-setup` (for skill/hook/agent recommendations).
- `hookify` (for hook design principles).
- `document-skills` (for writing-quality principles).

## Usage

```
/project-architect
```

Or describe what you want to build — e.g. "set up a new project", "scaffold
project docs", "bootstrap a CLI tool", "design the architecture for X" — and
the architect should trigger automatically.

## Source

Repo root IS the marketplace root. See `CHANGELOG.md` for version history.
The full v2.0 design spec is at
`docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md`.
```

- [ ] **Step 2: Create directories**

Run:
```bash
mkdir -p agents
mkdir -p skills/project-architect/references/templates
```

Expected: directories exist (verify with `ls -la agents skills/project-architect/references/templates`).

- [ ] **Step 3: Add `.gitkeep` so empty dirs commit**

Run:
```bash
touch agents/.gitkeep skills/project-architect/references/templates/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
git add README.md agents/.gitkeep skills/project-architect/references/templates/.gitkeep
git commit -m "$(cat <<'EOF'
chore: update README for v2 + scaffold agents/ and templates/ dirs

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase B — References

### Task B1: Restructure `questioning-flow.md`

**Files:**
- Modify: `skills/project-architect/references/questioning-flow.md` (replace contents entirely)

- [ ] **Step 1: Replace file contents**

Overwrite `skills/project-architect/references/questioning-flow.md` with:

````markdown
# Questioning Flow Reference

The interview is a tree: **universal kickoff** (always asked) → **per-type drill-down** (one branch) → **architecture deep dive** (per-area). Skip questions that prior answers render irrelevant.

## Table of Contents
- [Universal Kickoff (Phase 0)](#universal-kickoff-phase-0)
- [Per-Type Drill-Downs (Phase 1)](#per-type-drill-downs-phase-1)
- [Tech Stack Drill-Downs (Phase 2)](#tech-stack-drill-downs-phase-2)
- [Cost Modeling (Phase 2.5)](#cost-modeling-phase-25)
- [Architecture Deep Dive (Phase 3)](#architecture-deep-dive-phase-3)
- [Routing Rules](#routing-rules)

---

## Universal Kickoff (Phase 0)

Always asked first, in 3 `AskUserQuestion` batches.

### Batch 1 — Identity & Type
1. **Elevator pitch.** One sentence: what is it, who is it for, why does it exist? *(open-ended)*
2. **Top-level project type.** *(multiple-choice from the taxonomy below)*
3. **Sub-type within that category.** *(multiple-choice; options depend on Q2)*

### Batch 2 — Stage & Problem
4. **Project stage.** *(multiple-choice: greenfield / extending existing / rewriting / migrating / PoC only)*
5. **Primary problem & target users.** *(open-ended)*

### Batch 3 — Constraints & Scale
6. **Constraints.** *(multi-select: budget tight / regulated (GDPR/HIPAA/PCI-DSS/SOC2) / tight timeline / pre-existing tech mandates / open-source vs proprietary)*
7. **Team & scale.** *(multiple-choice combining team size {solo / small / larger} × scale tier {hobby / MVP / growth / enterprise})*
8. **Hard pre-existing decisions.** "Must be on AWS", "Must use Postgres", etc. *(open-ended)*

After Batch 3: dispatch `research-scout` for **domain research** (similar projects, pitfalls for this type/domain, regulatory implications, market context). Findings → `docs/research/phase0-domain.md`.

### Top-level project type taxonomy

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
Embedded / firmware/IoT  → MCU class (Cortex-M / RP2 / ESP32 / STM32) | edge gateway | hardware combo
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

---

## Per-Type Drill-Downs (Phase 1)

Adaptive — keep asking batches until each relevant area is locked. Typical 3–7 batches per project. Dispatch ad-hoc `research-scout` on red flags (see `research-prompts.md`). End-of-phase: `research-scout` for scope realism.

### Web application
- Which platforms (web only / web + PWA / web + mobile)? Browser support floor?
- Offline / sync requirements?
- Public-facing vs auth-walled? Sign-up flow expectations?
- Real-time features (chat, presence, live updates)?
- Content / media handling (uploads, video, large files)?
- Search needs (full-text, faceted, semantic)?

### Mobile application
- Platforms (iOS / Android / both / cross-platform)? Minimum OS versions?
- Distribution (App Store + Play / TestFlight / enterprise / sideload)?
- Offline capability and sync model?
- Push notifications and background tasks?
- Native integrations needed (camera, biometrics, payments, HealthKit, location)?

### Multi-platform system
- Which platforms in scope (web / iOS / Android / macOS / Windows / Linux / API)?
- Code-sharing strategy goal (max share / per-platform native UI)?
- Sync / state model across clients?
- Release cadence per platform?

### API / backend service
- Consumers (internal-only / public-API / partner-only / SDK-distributed)?
- Sync vs async vs event-driven boundary?
- Auth required at the API edge?
- Versioning policy (URL path / header / none)?
- Rate-limiting needs?
- Real-time delivery (WebSocket / SSE / polling)?

### CLI tool
- Distribution channel (homebrew / cargo / npm / pip / binary release / pkg manager combos)?
- Interactive vs strictly scriptable? TTY assumptions?
- Config file format (TOML / YAML / JSON / env)?
- Plugin / extension model?
- Cross-platform (Windows in scope)?
- Telemetry policy (opt-in / opt-out / none)?

### Library / SDK / package
- Target consumers (other devs / specific platform / public)?
- Public-API discipline (semver, deprecation policy)?
- Bundled docs site (Mintlify / TypeDoc / Sphinx / Rustdoc)?
- Example projects shipped alongside?
- Tree-shaking / bundle-size targets?
- TypeScript types shipped?

### Desktop application
- macOS / Windows / Linux / cross? Native vs Electron vs Tauri?
- Distribution (App Store / Developer ID + notarization / direct download / package managers)?
- Auto-update mechanism?
- System integration (menu bar, tray, services, file associations, deep links)?
- Sandboxing requirements?

### Browser extension
- Manifest V3? Cross-browser (Chrome / Firefox / Safari / Edge)?
- Permissions (content scripts / activeTab / host permissions / declarativeNetRequest)?
- DevTools panel / sidebar / popup?
- Distribution (Chrome Web Store / Mozilla Add-ons / enterprise self-host)?
- Data sync (chrome.storage.sync limits)?

### Game
- Engine (Unity / Unreal / Godot / custom / web-native)?
- 2D / 3D / hybrid?
- Single-player / multiplayer (netcode requirements)?
- Platforms (mobile / PC / console / web / VR-AR)?
- Monetization (paid / freemium / IAP / subscription / ads)?
- Save / progression storage (local / cloud)?

### AI/ML application
- Training vs inference vs both?
- Model source (own model / fine-tuned / API-only / open weights / mixture)?
- Dataset handling and provenance?
- Evaluation framework / benchmarks?
- Inference latency targets?
- Cost ceiling per request?
- Vector store needs (RAG / semantic search)?

### Data pipeline
- Sources / sinks (databases, warehouses, APIs, files)?
- Batch / streaming / hybrid?
- Orchestrator (Airflow / Dagster / Prefect / Argo / cron / managed)?
- Schedule / SLA?
- Schema evolution policy?
- Data quality / observability (Great Expectations / Soda / OpenLineage)?

### Embedded / IoT
- MCU class / SoC (Cortex-M / ESP32 / RP2 / STM32 / Linux SoC)?
- RTOS? Bare-metal?
- Power budget?
- Connectivity (BLE / Wi-Fi / LoRa / cellular / none)?
- OTA update mechanism?
- Hardware combo (PCB design / off-the-shelf dev board)?

### Infrastructure tool
- Target users (own team / customers / OSS community)?
- Cloud focus (multi-cloud / single)?
- IaC integration (Terraform / Pulumi / CDK / CloudFormation / Crossplane)?
- Operator / controller model (Kubernetes)?
- Observability / logging / metrics?

### Claude Code plugin
- Components (skills / commands / agents / hooks / MCP servers / mix)?
- Triggers (slash command / natural language / file change / event)?
- Distribution (own marketplace / Anthropic marketplace / private)?
- Configurable per project (`.claude/plugin-name.local.md`)?

### MCP server
- Host environment (stdio / HTTP+SSE / Cloudflare Workers / Vercel / other)?
- Surface (tools / resources / prompts / mix)?
- Auth model (OAuth / API key / none)?
- Stateful (durable per-user) or stateless?
- Languages (TypeScript / Python / Rust / Go)?

### Web3 / smart contracts
- Chain (Ethereum / L2s / Solana / Aptos / Sui / Starknet)?
- Smart-contract language (Solidity / Rust / Move / Cairo)?
- Indexing layer (The Graph / Goldsky / custom)?
- Front-end integration (RainbowKit / wagmi / web3.js / ethers / web3.swift)?
- Upgradeability pattern?
- Audit budget / firm?

### Scientific / research
- Reproducibility requirements (environment freeze, seeds, container/Nix)?
- Notebook vs scripts vs both?
- Data scale (fits-in-RAM / out-of-core / cluster)?
- Computation backend (NumPy / JAX / PyTorch / cuDF / Spark / Ray)?
- Publication / pre-print artifacts?
- Domain-specific tooling (bioinformatics, geospatial, etc.)?

### AR / VR / spatial
- Headset / device target (visionOS / Quest / smartphone AR / WebXR)?
- Tracking / input (controllers / hand tracking / gaze / voice)?
- Rendering engine (Unity / Unreal / RealityKit / Three.js / custom)?
- Mixed-reality vs immersive?
- Multi-user / shared sessions?
- App-store distribution?

---

## Tech Stack Drill-Downs (Phase 2)

For each category that applies (skip categories based on prior answers — see Routing Rules). See `tech-stack-options.md` for option tables.

Grouped batches:
1. **Language & runtime** (+ build/package manager)
2. **Frontend framework** (skip if no frontend)
3. **Backend framework** (skip if pure client-side)
4. **Database + ORM** (skip if no persistence)
5. **Authentication** (skip if no accounts)
6. **Hosting (frontend + backend separately) + CDN**
7. **Styling & UI** (skip if no frontend)
8. **Payments** (skip if no monetization)
9. **Email / notifications** (skip if not needed)
10. **File storage** (skip if no files)
11. **AI / ML integration** (skip if no AI features)
12. **Observability stack** (skip if scale = hobby)
13. **Testing stack**
14. **CI / CD**

For each major decision, the orchestrator files an ADR (one per major: language, framework choice, db engine, auth provider, host, etc.).

End-of-phase: `research-scout` on stack-combination gotchas. Findings → `docs/research/phase2-stack.md`.

---

## Cost Modeling (Phase 2.5)

1. Dispatch `research-scout` with the pricing-research prompt (see `research-prompts.md`).
2. Walk the user through the findings: base costs, per-unit costs, hidden line items, free-tier limits.
3. Optionally revise tech-stack decisions in light of cost reality (any revision spawns the `decision-revisor`).
4. Capture cost estimates in `COST_MODEL.md` at MVP / growth / enterprise tiers.

---

## Architecture Deep Dive (Phase 3)

Per-area drill-downs. Only ask about areas that apply (per prior phases). Each area concludes a "ready to record" question — if yes, file an ADR.

### Auth (if auth chosen)
- Session strategy (JWT / cookies / hybrid)?
- Token storage (httpOnly / secure storage / both)?
- RBAC / ABAC / simple permissions?
- Multi-tenancy isolation model?
- OAuth providers list?
- Lockout / rate-limit policy?
- MFA support (TOTP / passkeys / SMS)?

### Database design (if DB chosen)
- Normalization level (3NF / denormalized / event-sourced)?
- Migration strategy (code-first / SQL-first / hybrid)?
- Key entities + relationships (high-level ERD)?
- Soft vs hard deletes?
- Audit-logging needs?
- Read replicas / sharding?
- Multi-tenancy data isolation (shared DB / schema-per-tenant / DB-per-tenant)?

### API design (if API)
- Style (REST / GraphQL / gRPC / tRPC / hybrid)?
- Versioning (URL path / header / none)?
- Rate-limiting policy?
- Pagination (cursor / offset / keyset)?
- API docs (OpenAPI / GraphQL introspection / manual)?
- Real-time channel (WebSocket / SSE / polling)?
- Webhook outbound (events, retry, signature)?

### Security architecture (if regulated OR security flagged)
- Encryption at rest / in transit?
- Secret management (env vars / Vault / Infisical / KMS)?
- Input validation library / schema enforcement?
- CORS policy?
- CSP?
- Dep-vuln scanning (Snyk / GitHub Advanced Security / Trivy)?
- Post-quantum / E2E encryption needs?
- Compliance gates (SOC2 / HIPAA / PCI-DSS / GDPR)?

### Frontend architecture (if frontend)
- State management (Context / Zustand / Redux / Jotai / signals)?
- Data fetching (TanStack Query / SWR / tRPC / Apollo)?
- Routing model (file-based / manual)?
- Rendering strategy (SSR / SSG / CSR / ISR / mix)?
- i18n requirements?
- a11y target (WCAG level)?
- Form library?
- Animation library?

### Testing strategy
- Unit framework (Vitest / Jest / pytest / cargo test / etc.)?
- Integration / API test framework?
- E2E framework (Playwright / Cypress / Detox / XCTest / Espresso)?
- Coverage target?
- CI integration cadence?
- Visual / snapshot tests?

### DevOps & deployment
- Environment tiers (dev / staging / production)?
- CI / CD platform?
- IaC (Terraform / Pulumi / SST / CDK / Crossplane / none)?
- Containerization (Docker / Podman / native)?
- Preview deploys (per-PR / per-branch)?
- Blue-green / canary?

### Monitoring & observability (if scale > MVP)
- Error tracking (Sentry / Bugsnag / Datadog)?
- APM (Datadog / New Relic / Grafana Cloud)?
- Logging (Loki / Datadog / Axiom / CloudWatch)?
- Uptime monitoring?
- Analytics (PostHog / Plausible / Mixpanel / Amplitude)?
- Alerting destinations (Slack / PagerDuty / email)?

### Third-party integrations
- Which services are critical (which are nice-to-have)?
- Webhook handling needs?
- Queue / event system?
- Background jobs / scheduled tasks?
- SDK quality / portability concerns?

After all areas: **inline consistency check** (architect cross-checks decisions; surfaces contradictions for user resolution before doc gen).

End-of-phase: `research-scout` on pattern validation. Findings → `docs/research/phase3-architecture.md`.

---

## Routing Rules

Skip questions when prior answers make them irrelevant.

| Phase 0 answer | Skip in later phases |
|---|---|
| Project type = Library / SDK | Auth, database, hosting, UI, payments, notifications |
| Project type = CLI tool | Frontend, UI, payments (usually), styling |
| No user accounts | All auth questions |
| No persistence | Database, ORM, schema design |
| No frontend | Styling, components, frontend architecture |
| No monetization | Payments & billing |
| Budget = free-tier only | Bias options toward open-source / self-hosted |
| Scale = hobby/personal | Monitoring deep dive, enterprise security, multi-tenancy |
| Solo team | Simplify CI/CD; skip team collaboration tooling |
| No regulatory requirements | Compliance section in security |
| Offline = yes | Add sync strategy, local-first patterns |
| Real-time = yes | WebSocket/SSE architecture, presence model |
| AI features = yes | AI/ML section, vector DB, embeddings |
| Stage = greenfield | Commit on `main`; no branch strategy questions |
| Stage = extending/rewriting/migrating | Create `bootstrap/architect-<date>` branch |
````

- [ ] **Step 2: Verify file length and key sections**

Run: `wc -l skills/project-architect/references/questioning-flow.md && grep -c "^##" skills/project-architect/references/questioning-flow.md`
Expected: ~330–400 lines; at least 6 top-level `##` sections (Universal, Per-Type, Tech Stack, Cost, Architecture, Routing Rules).

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/references/questioning-flow.md
git commit -m "$(cat <<'EOF'
refactor(questioning-flow): restructure for universal kickoff + per-type drill-downs

Adds 18-type taxonomy, drill-down per type, ADR-per-major-decision in Phase 2,
inline consistency check at end of Phase 3, routing rules table.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task B2: Expand `tech-stack-options.md`

**Files:**
- Modify: `skills/project-architect/references/tech-stack-options.md` (append additional rows)

The v1 file already has tables per category. We *add* options that the v2 type taxonomy now requires, without restructuring the existing tables.

- [ ] **Step 1: Read the current file**

Run: `cat skills/project-architect/references/tech-stack-options.md | head -50`
Confirm the v1 structure (Frontend Frameworks, Backend Frameworks, Databases, ORMs, Auth, Hosting, CSS, Component Libraries, State, Testing, CI/CD, Monitoring, Payments, Email, File Storage, AI & ML, Package Managers).

- [ ] **Step 2: Append the following sections to the end of the file**

```markdown

---

## Web3 / Smart Contracts

| Layer | Options | Trade-offs |
|---|---|---|
| **Chain (EVM)** | Ethereum mainnet, Optimism, Arbitrum, Base, Polygon zkEVM, Linea, Scroll | mainnet = highest security + cost; L2s = cheap + fast, ecosystem-fragmented |
| **Chain (non-EVM)** | Solana, Aptos, Sui, Starknet, Near | high throughput, different tooling, smaller dev ecosystems |
| **Contract language** | Solidity (EVM), Vyper (EVM), Rust+Anchor (Solana), Move (Aptos/Sui), Cairo (Starknet) | Solidity = most learning material; Rust = strong typing; Move = resource-oriented |
| **Dev framework** | Foundry, Hardhat, Truffle (deprecated), Anchor, Starknet Foundry | Foundry = Rust-fast tests; Hardhat = JS-native; Anchor = Solana standard |
| **Indexing** | The Graph, Goldsky, Subsquid, Ponder, custom | hosted vs self-host; cost vs control |
| **Wallet integration** | RainbowKit, ConnectKit, wagmi, ethers, viem, web3.js (legacy) | wagmi+viem = modern TS-first |
| **Audits** | Trail of Bits, OpenZeppelin, Sherlock contest, Code4rena | firm vs contest; cost vs depth |

## Game Engines

| Option | Best for | Trade-offs |
|---|---|---|
| **Unity** | Cross-platform, mobile, AR/VR, indie + AAA | C#, royalty model after threshold |
| **Unreal Engine** | High-fidelity 3D, AAA, console | C++ + Blueprints, heavier |
| **Godot** | 2D + 3D indie, OSS | GDScript / C#, smaller ecosystem |
| **Bevy** | Rust-based, OSS, ECS | Rust expertise required, younger |
| **PlayCanvas / Phaser / Pixi.js** | Web-native games | Browser only, no native AOT |

## Mobile-Specific Tooling

| Layer | Options | Trade-offs |
|---|---|---|
| **Cross-platform framework** | React Native (bare or Expo), Flutter, .NET MAUI, NativeScript, KMP+Compose Multiplatform | RN+Expo = JS speed; Flutter = pixel-perfect; KMP = native UI per platform |
| **Native (iOS)** | SwiftUI, UIKit (legacy) | SwiftUI = modern, UIKit needed for some controls |
| **Native (Android)** | Jetpack Compose, View system (legacy) | Compose = modern, Views needed for some libs |
| **State (RN/Flutter)** | Zustand+Jotai (RN), Riverpod+BLoC (Flutter) | per-ecosystem standard |
| **Distribution / OTA** | EAS Update (Expo), CodePush (deprecated), Shorebird (Flutter), App Center | EAS for Expo; Shorebird for Flutter dart hot updates |
| **In-app purchases** | RevenueCat (cross-platform), StoreKit 2 (iOS native), Google Play Billing (Android native) | RevenueCat = subscription unification |

## Embedded / Firmware

| Layer | Options | Trade-offs |
|---|---|---|
| **MCU class** | Cortex-M0+/M3/M4F/M7 (STM32, NXP), RP2040/RP2350 (Raspberry Pi), ESP32 (Espressif), nRF52/nRF53 (Nordic BLE) | RP2040 = cheap+RP; ESP32 = built-in WiFi+BLE; nRF = BLE-first |
| **RTOS** | FreeRTOS, Zephyr, ThreadX (Azure RTOS), bare-metal | Zephyr = modular + DTS; FreeRTOS = simplest |
| **Language** | C, C++ (modern), Rust (embedded-hal), MicroPython | Rust = memory safety, learning curve |
| **OTA** | esp-idf OTA, MCUboot, Nordic DFU, custom | MCUboot = vendor-neutral |
| **Connectivity** | BLE, Wi-Fi, Thread/Matter, LoRa(WAN), NB-IoT, Cellular (LTE-M / 4G / 5G), Ethernet | Matter = unified IoT; LoRa = long-range low-power |
| **Tooling** | PlatformIO, esp-idf, STM32CubeIDE, Zephyr west, probe-rs | PlatformIO unifies across MCUs |

## Browser Extensions

| Layer | Options | Trade-offs |
|---|---|---|
| **Manifest** | Manifest V3 (required for Chrome new submissions), Manifest V2 (Firefox supports longer) | MV3 = service worker model |
| **Framework** | WXT, Plasmo, CRXJS, vanilla | WXT/Plasmo = DX boost, type-safe |
| **Cross-browser** | webextension-polyfill, browser API shims | extension code largely portable |
| **Distribution** | Chrome Web Store, Mozilla Add-ons, Edge Add-ons, Safari (Mac App Store) | Safari requires Xcode wrapper |

## Desktop App Frameworks

| Option | Best for | Trade-offs |
|---|---|---|
| **Tauri** | Rust backend + web frontend, small bundle | Rust learning |
| **Electron** | Max compatibility, large ecosystem | Heavy memory, large bundle |
| **Wails** | Go backend + web frontend | Smaller ecosystem |
| **SwiftUI (macOS-only)** | Native macOS UX | Apple only |
| **WinUI 3 (Windows-only)** | Native Windows UX | Microsoft only |
| **GTK / Qt** | Native Linux + cross-platform | Older stacks, harder UX polish |

## AR / VR / Spatial

| Layer | Options | Trade-offs |
|---|---|---|
| **Headset/device** | Apple Vision Pro (visionOS), Meta Quest 2/3/Pro, smartphone AR (ARKit/ARCore), WebXR | visionOS = native spatial; Quest = standalone; WebXR = browser-only |
| **Engine** | Unity (broad support), Unreal, RealityKit (Apple), Three.js+react-three-fiber (WebXR) | Unity = most cross-platform; RealityKit = visionOS native |
| **Tracking** | controllers, hand-tracking, eye-tracking, gaze, voice | varies by device capability |
| **Multi-user** | Photon, Mirror, Normcore, ROS (research) | Photon = managed; Mirror = open-source Unity |

## MCP Server Hosts

| Option | Best for | Trade-offs |
|---|---|---|
| **stdio** | Local development, Claude Desktop integration | Single-user, no remote |
| **HTTP + SSE** | Remote, multi-user, web auth | Need hosting + auth |
| **Cloudflare Workers (McpAgent)** | Edge, durable state via DO, OAuth | Cloudflare-coupled |
| **Vercel Functions** | Serverless, Next.js-adjacent | Cold starts |

## Claude Code Plugin Components

| Layer | When to use | Notes |
|---|---|---|
| **Skills** | Reusable techniques, workflows, references | Default unit — see `skill-creator:skill-creator` |
| **Commands** | User-invoked slash commands | See `plugin-dev:command-development` |
| **Agents** | Long-running, isolated context tasks | See `plugin-dev:agent-development` |
| **Hooks** | Event-driven (PreToolUse, PostToolUse, Stop, etc.) | See `plugin-dev:hook-development` |
| **MCP servers** | External tool integrations | See `plugin-dev:mcp-integration` |

## Scientific / Research Stacks

| Layer | Options | Trade-offs |
|---|---|---|
| **Compute backend** | NumPy / SciPy, PyTorch, JAX, cuDF, Polars, DuckDB, Dask, Ray | JAX = autodiff + JIT; Polars/DuckDB = OLAP local |
| **Notebooks** | Jupyter, marimo, Pluto.jl (Julia), Quarto | marimo = reactive; Quarto = publication |
| **Environment** | conda / mamba, uv, pixi, Nix, devcontainer | pixi = conda+lockfile speed; Nix = full reproducibility |
| **Workflow** | Snakemake, Nextflow, Pachyderm (data versioning) | Nextflow = bioinformatics standard |
| **Publication** | Quarto, Pandoc, LaTeX, Manuscripts | Quarto unifies notebooks + papers |

## Data Pipeline Orchestrators

| Option | Best for | Trade-offs |
|---|---|---|
| **Airflow (Astronomer-managed)** | Mature, large community | Heavy, complex |
| **Dagster** | Modern, asset-aware | Newer, less battle-tested |
| **Prefect** | Python-native, dynamic | Smaller community than Airflow |
| **Argo Workflows** | Kubernetes-native | K8s required |
| **Temporal** | Durable execution, code-defined | Different mental model |
| **GitHub Actions / cron** | Simple schedules | Limited for complex DAGs |

## IaC / Cloud Infrastructure

| Option | Best for | Trade-offs |
|---|---|---|
| **Terraform / OpenTofu** | Multi-cloud, mature ecosystem | HCL learning |
| **Pulumi** | Real programming languages | Smaller community |
| **AWS CDK** | AWS-only, TypeScript/Python | AWS lock-in |
| **SST** | Serverless + Next.js + AWS | Opinionated |
| **Crossplane** | K8s-native infrastructure | K8s required |
```

- [ ] **Step 3: Verify**

Run: `wc -l skills/project-architect/references/tech-stack-options.md`
Expected: ~450–550 lines (was ~306).

Run: `grep -c "^## " skills/project-architect/references/tech-stack-options.md`
Expected: at least 27 H2 headings.

- [ ] **Step 4: Commit**

```bash
git add skills/project-architect/references/tech-stack-options.md
git commit -m "$(cat <<'EOF'
docs(tech-stack-options): expand for v2 project types

Adds option tables for: Web3/smart contracts, game engines, mobile-specific,
embedded/firmware, browser extensions, desktop frameworks, AR/VR/spatial,
MCP server hosts, Claude Code plugin components, scientific stacks,
data pipeline orchestrators, IaC/cloud.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task B3: Create `document-catalog.md`

**Files:**
- Create: `skills/project-architect/references/document-catalog.md`

- [ ] **Step 1: Write the file**

Create `skills/project-architect/references/document-catalog.md` with:

````markdown
# Document Catalog

The orchestrator queries this catalog before Phase 4 to decide which templates to dispatch `document-author` for. Templates live in `templates/<NAME>.md` with YAML frontmatter that mirrors fields used here.

## Table of Contents
- [Selection algorithm](#selection-algorithm)
- [Always-generated templates](#always-generated-templates)
- [Type-anchored templates](#type-anchored-templates)
- [Conditional matrix](#conditional-matrix)
- [Dependency / generation order](#dependency--generation-order)

---

## Selection algorithm

```
def select_templates(state):
    selected = list(ALWAYS_TEMPLATES)
    # type-anchored
    for tmpl in TYPE_ANCHORS[state.decisions["project.type"]]:
        selected.append(tmpl)
    # conditional
    for tmpl in CONDITIONAL_TEMPLATES:
        if matches(tmpl.generate_when, state):
            selected.append(tmpl)
    # de-duplicate
    selected = unique(selected)
    # respect dependencies — write upstream before downstream
    return topological_sort(selected, key="depends_on")
```

`matches(expr, state)` evaluates the simple boolean expressions used in template frontmatter (e.g., `decisions.auth.enabled == true`, `decisions.scale != "hobby"`). The orchestrator parses these — no real engine, just key-lookup + comparison + `AND` / `OR` / `NOT`.

## Always-generated templates

| Template | File |
|---|---|
| PROJECT_OVERVIEW | `templates/PROJECT_OVERVIEW.md` |
| PROJECT_REQUIREMENTS | `templates/PROJECT_REQUIREMENTS.md` |
| CLAUDE_MD_ROOT | `templates/CLAUDE_MD_ROOT.md` |

(ADR_TEMPLATE and REVISION_LOG_FRAGMENT also live in `templates/` but are used by agents, not selected as standalone docs.)

## Type-anchored templates

Selected automatically when the top-level project type matches.

| Top-level project type | Anchored templates |
|---|---|
| Web application | UI_UX_DESIGN, PLATFORMS (if multi-target) |
| Mobile application | MOBILE_SPECIFIC, PLATFORMS (if cross-platform) |
| Multi-platform system | PLATFORMS |
| API / backend service | API_GATEWAY |
| CLI tool | *(no anchor — naturally smaller doc set)* |
| Library / SDK / package | SDK_DESIGN |
| Desktop application | DESKTOP_SPECIFIC |
| Browser extension | BROWSER_EXTENSION |
| Game | GAME_SPECIFIC |
| AI/ML application | AI_AND_ML, ML_OPS |
| Data pipeline | DATA_PIPELINE |
| Embedded / IoT | EMBEDDED_SPECIFIC, HARDWARE_FIRMWARE (if hardware combo) |
| Infrastructure tool | DEPLOYMENT, CI_CD (both anchored) |
| Claude Code plugin | PLUGIN_SPECIFIC |
| MCP server | MCP_SERVER_SPECIFIC |
| Web3 / smart contracts | WEB3_SPECIFIC, THREAT_MODEL |
| Scientific / research | SCIENTIFIC_COMPUTING |
| AR / VR / spatial | AR_VR_SPECIFIC, MOBILE_SPECIFIC (if mobile-AR) |

## Conditional matrix

| Template | `generate_when` expression |
|---|---|
| AUTHENTICATION_SYSTEM | `decisions.auth.enabled == true` |
| DATABASE_DESIGN | `decisions.database.engine != null` |
| API_GATEWAY | `decisions.api.enabled == true` *(also type-anchored for API projects)* |
| UI_UX_DESIGN | `decisions.frontend.framework != null` *(also type-anchored for web)* |
| PLATFORMS | `decisions.platforms.length > 1` |
| SECURITY_AND_COMPLIANCE | `decisions.auth.enabled == true OR decisions.constraints.includes('regulated')` |
| DEPLOYMENT | `decisions.hosting.frontend != null OR decisions.hosting.backend != null` |
| CI_CD | `decisions.devops.cicd != null` |
| TESTING_STRATEGY | `decisions.scale != "hobby" OR decisions.project.type != "library"` |
| THIRD_PARTY_INTEGRATIONS | `decisions.integrations.length > 0` |
| MONITORING_AND_OBSERVABILITY | `decisions.scale != "hobby" AND decisions.production_bound == true` |
| BILLING_AND_PAYMENTS | `decisions.monetization.enabled == true` |
| EMAIL_AND_NOTIFICATIONS | `decisions.notifications.enabled == true` |
| FILE_STORAGE | `decisions.file_handling.enabled == true` |
| AI_AND_ML | `decisions.ai.enabled == true` *(also type-anchored)* |
| REAL_TIME | `decisions.realtime.enabled == true` |
| SEARCH | `decisions.search.enabled == true` |
| CACHING_STRATEGY | `decisions.scale >= "growth" OR decisions.caching.enabled == true` |
| INTERNATIONALIZATION | `decisions.i18n.languages.length > 1` |
| ACCESSIBILITY | `decisions.frontend.framework != null AND decisions.a11y.target != null` |
| DATA_PIPELINE | `decisions.data_pipeline.enabled == true` *(also type-anchored)* |
| BACKGROUND_JOBS | `decisions.background_jobs.enabled == true` |
| COST_MODEL | `decisions.scale != "hobby" OR decisions.managed_services_in_stack == true` |
| RUNBOOK | `decisions.production_bound == true AND decisions.scale >= "growth"` |
| INCIDENT_RESPONSE | `decisions.production_bound == true AND decisions.scale >= "growth"` |
| DISASTER_RECOVERY | `decisions.production_bound == true AND decisions.scale >= "growth"` |
| SLO_AND_ERROR_BUDGETS | `decisions.scale >= "growth"` |
| THREAT_MODEL | `decisions.constraints.includes('regulated') OR decisions.security.formal_threat_model == true` *(also type-anchored for Web3)* |
| BACKUP_AND_DR | `decisions.database.engine != null AND decisions.scale != "hobby"` |
| PERFORMANCE_BUDGETS | `decisions.frontend.framework != null OR decisions.api.enabled == true` |
| ARCHITECTURE_DIAGRAMS | `decisions.scale >= "growth" OR decisions.complexity == "high"` |
| SDK_DESIGN | `decisions.project.type == "library" OR decisions.exposes_sdk == true` |
| TENANT_AND_ORGANIZATION_MODEL | `decisions.multi_tenancy == true` |
| EXPERIMENTS | `decisions.feature_flags.enabled == true OR decisions.ab_testing.enabled == true` |
| ANALYTICS_AND_TELEMETRY | `decisions.analytics.enabled == true` |
| ONBOARDING | `decisions.team_size != "solo"` |
| CONTRIBUTING | `decisions.open_source == true` |
| RELEASE_PROCESS | `decisions.production_bound == true` |

## Dependency / generation order

The architect topologically sorts selected templates by `depends_on` before parallel dispatch, so cross-references resolve.

```
PROJECT_OVERVIEW
└─ PROJECT_REQUIREMENTS
   ├─ AUTHENTICATION_SYSTEM ──────────────┐
   ├─ DATABASE_DESIGN ────────────────────┤
   ├─ UI_UX_DESIGN                        │
   ├─ PLATFORMS                           │
   ├─ TESTING_STRATEGY                    │
   ├─ DEPLOYMENT ─────────────────┐       │
   ├─ TENANT_AND_ORGANIZATION_MODEL│      │
   ├─ EXPERIMENTS                  │      │
   ├─ ANALYTICS_AND_TELEMETRY      │      │
   │                               │      │
   ├─ API_GATEWAY ◄────────────────┼──────┤  depends on AUTH + DATABASE
   ├─ SECURITY_AND_COMPLIANCE ◄────┴──────┤  depends on AUTH + DATABASE
   │                                      │
   ├─ CI_CD ◄──────────────────── DEPLOYMENT + TESTING_STRATEGY
   ├─ MONITORING_AND_OBSERVABILITY ◄──────┘
   ├─ BACKUP_AND_DR ◄──── DATABASE_DESIGN
   ├─ COST_MODEL ◄──── DEPLOYMENT + DATABASE_DESIGN
   ├─ THIRD_PARTY_INTEGRATIONS
   ├─ THREAT_MODEL ◄──── SECURITY_AND_COMPLIANCE
   ├─ RUNBOOK ◄──── DEPLOYMENT + MONITORING_AND_OBSERVABILITY
   ├─ INCIDENT_RESPONSE ◄──── MONITORING_AND_OBSERVABILITY + RUNBOOK
   ├─ DISASTER_RECOVERY ◄──── BACKUP_AND_DR + DEPLOYMENT
   ├─ SLO_AND_ERROR_BUDGETS ◄──── MONITORING_AND_OBSERVABILITY
   ├─ ARCHITECTURE_DIAGRAMS ◄──── most architecture docs
   ├─ PERFORMANCE_BUDGETS ◄──── UI_UX_DESIGN + API_GATEWAY
   │
   ├─ MOBILE_SPECIFIC | DESKTOP_SPECIFIC | EMBEDDED_SPECIFIC | ML_OPS | GAME_SPECIFIC |
   │   BROWSER_EXTENSION | PLUGIN_SPECIFIC | HARDWARE_FIRMWARE | WEB3_SPECIFIC |
   │   SCIENTIFIC_COMPUTING | AR_VR_SPECIFIC | MCP_SERVER_SPECIFIC
   │   (each independent of the others; depends on PROJECT_OVERVIEW)
   │
   ├─ AI_AND_ML | DATA_PIPELINE | REAL_TIME | SEARCH | BILLING_AND_PAYMENTS |
   │   EMAIL_AND_NOTIFICATIONS | FILE_STORAGE | CACHING_STRATEGY |
   │   INTERNATIONALIZATION | ACCESSIBILITY | BACKGROUND_JOBS |
   │   ONBOARDING | CONTRIBUTING | RELEASE_PROCESS | SDK_DESIGN
   │   (feature-area templates; depend on PROJECT_REQUIREMENTS only)
   ↓
CLAUDE_MD_ROOT (depends on all)
CLAUDE_MD_SUBFOLDER (per-folder, depends on root + folder-relevant docs)
```

The `claude-md-author` agent writes CLAUDE.md files **after** all other docs are committed. The `claude-tooling-author` runs in parallel with `claude-md-author`.
````

- [ ] **Step 2: Verify**

Run: `wc -l skills/project-architect/references/document-catalog.md && grep -c "^## " skills/project-architect/references/document-catalog.md`
Expected: ~180–220 lines; at least 5 H2 sections.

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/references/document-catalog.md
git commit -m "$(cat <<'EOF'
docs(catalog): add document-catalog with selection rules and topological order

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task B4: Create `research-prompts.md`

**Files:**
- Create: `skills/project-architect/references/research-prompts.md`

- [ ] **Step 1: Write the file**

Create `skills/project-architect/references/research-prompts.md` with:

````markdown
# Research Prompts

Prompt templates the orchestrator hands to the `research-scout` agent. The agent substitutes `{{...}}` placeholders with values from `state.decisions` and the current phase summary.

## Table of Contents
- [Phase-level prompts](#phase-level-prompts)
- [Ad-hoc red-flag prompts](#ad-hoc-red-flag-prompts)
- [Output format the scout returns](#output-format-the-scout-returns)
- [Recency policy per phase](#recency-policy-per-phase)

---

## Phase-level prompts

### Phase 0 — Domain research
> Research the project domain. Find: **(1)** 3–5 similar existing projects (commercial or OSS) with one-line summaries and links. **(2)** Common pitfalls developers hit when building a `{{decisions.project.subtype}}` `{{decisions.project.type}}` for `{{decisions.project.target_users}}`. **(3)** Regulatory implications given target users and domain (privacy, accessibility, financial, healthcare, etc.). **(4)** Market context — is this space crowded / emerging / niche? **(5)** What's *actually hard* about this kind of project that newcomers underestimate? Cite URLs. Market data must be < 12 months old; foundational pitfalls can be older. Write findings to `{{output_path}}`. End with an "Implications for this project" section listing concrete follow-up questions for the architect to consider.

### Phase 1 — Scope realism
> For an MVP with features `{{decisions.features}}` at `{{decisions.scale}}` scale built by a `{{decisions.team_size}}` team in a `{{decisions.timeline}}` timeframe, research: **(1)** Which of these features are typically v1 vs deferred to v2 in similar projects (cite examples). **(2)** Which features are over-scoped — commonly cut in similar projects. **(3)** Which features are under-scoped — typically need supporting features that aren't listed. **(4)** Realistic timeline benchmarks for similar feature sets. **(5)** Where similar projects most often fail (technical, market, ops). Cite specific projects and post-mortems. Write findings to `{{output_path}}`.

### Phase 2 — Stack combination gotchas
> For this stack: `{{stack_summary}}`, find: **(1)** Known integration gotchas between these specific tools (cite docs and GitHub issues). **(2)** Version compatibility issues to watch for. **(3)** Production issues reported in the last 12 months. **(4)** Emerging alternatives gaining traction the user might want to know about. **(5)** Any tool in this stack that is deprecated, sunsetting, or has had a major maintainer change. Be specific about versions where relevant. Write findings to `{{output_path}}`.

### Phase 2.5 — Pricing research
> For these managed services `{{services_with_tiers}}` at expected `{{decisions.scale}}` usage, find: **(1)** Base tier costs from official pricing pages. **(2)** Per-unit costs (egress, requests, storage, compute-time, function invocations). **(3)** Commonly-forgotten line items (data transfer between regions, log retention, snapshot storage, IP addresses, etc.). **(4)** Free-tier limits and what triggers paid tiers. **(5)** Pricing changes in the last 6 months. Cite official pricing pages only — no third-party calculators unless verifying against official sources. Estimate $/month at MVP / growth / enterprise tiers in a table. Write findings to `{{output_path}}`.

### Phase 3 — Pattern validation
> For this architecture: `{{architecture_summary}}`, find: **(1)** Prior-art projects using similar patterns and how they scaled (or didn't). **(2)** Anti-patterns to avoid for this combination. **(3)** Open-source reference implementations worth studying. **(4)** Common production failure modes — cite real incidents and post-mortems where possible. **(5)** Whether any pattern in this architecture is considered outdated by current industry consensus. Write findings to `{{output_path}}`.

---

## Ad-hoc red-flag prompts

The orchestrator dispatches the scout on these triggers mid-phase. Each is shorter and more targeted than phase-level prompts.

| Trigger | Prompt |
|---|---|
| Deprecated tool mentioned | "Is `{{tool}}` deprecated, sunsetting, or has it had a recent major maintainer change? What's the recommended successor? Migration cost / breaking changes? Cite official announcements and recent GitHub activity." |
| Regulated industry + non-compliant default | "What specific `{{regulation}}` requirements does an architecture using `{{component}}` typically violate? List the precise remediations needed and any OSS or commercial compliance helpers." |
| Critical-path vendor lock | "What is the migration cost off `{{vendor}}` if the project needs to switch? Portability patterns? Has anyone documented such a migration?" |
| Scaling ceiling concern | "What are the known scaling limits for `{{tool}}` at `{{scale}}`? Cite known production deployments at similar scale and any horror stories." |
| Novel security architecture | "Are there known cryptographic or security weaknesses in this approach: `{{approach}}`? Audit findings? Academic critique?" |
| Cost outlier | "Why is `{{service}}` significantly more expensive than `{{alternative}}` at `{{scale}}` scale? What's included that the alternative lacks?" |

---

## Output format the scout returns

The scout writes a markdown file at the path the orchestrator specified, with this structure:

```markdown
---
phase: {{phase_number}}
topic: {{topic_slug}}
dispatched_at: {{ISO8601}}
queries: [...]                  # list of search queries the scout actually ran
recency_floor: {{YYYY-MM-DD}}   # oldest acceptable source date
---

# Research: {{Topic}}

## Summary
{{3-5 sentence executive summary — the architect reads this first}}

## Similar projects / prior art
- [Project](url) — what they did, what worked, what didn't

## Known gotchas / issues
- {{issue}} — citation

## Production issues (last 12 months)
- {{issue}} — date, severity, status, citation

## Emerging alternatives
- {{alternative}} — why it's gaining traction

## Implications for this project          ← architect reads this second
- {{actionable implication}} — drives question Y or revisits decision Z

## Sources
- [Title](url) — accessed {{YYYY-MM-DD}}
```

The scout's return value to the orchestrator is a short text summary (≤20 lines) — NOT the full file. The full file lives on disk for the user and future iterations.

---

## Recency policy per phase

| Phase | Recency floor |
|---|---|
| 0 — Domain | 12 months for market context; foundational pitfalls can be older |
| 1 — Scope realism | 12 months |
| 2 — Stack gotchas | 12 months for production issues; tool deprecation status as-of-today |
| 2.5 — Pricing | 6 months; cite "as of `{{date}}`" |
| 3 — Pattern validation | 24 months for foundational papers; 12 months for production reports |
| Ad-hoc | depends on trigger; default 12 months unless specified |

Tune these per project if the user has unusual stability or recency requirements.
````

- [ ] **Step 2: Verify**

Run: `wc -l skills/project-architect/references/research-prompts.md`
Expected: ~140–180 lines.

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/references/research-prompts.md
git commit -m "$(cat <<'EOF'
docs(research-prompts): add per-phase and ad-hoc prompt templates

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task B5: Create `revision-playbook.md`

**Files:**
- Create: `skills/project-architect/references/revision-playbook.md`

- [ ] **Step 1: Write the file**

Create `skills/project-architect/references/revision-playbook.md` with:

````markdown
# Revision Playbook

The `decision-revisor` agent reads this file to learn which docs are affected when a specific decision changes. The orchestrator passes the revisor a `decision_key`; the revisor looks it up here and rewrites every doc listed.

## Table of Contents
- [How the revisor uses this](#how-the-revisor-uses-this)
- [Decision → affected docs map](#decision--affected-docs-map)
- [ADR conventions](#adr-conventions)
- [Revision Log conventions](#revision-log-conventions)
- [Cross-reference preservation rules](#cross-reference-preservation-rules)

---

## How the revisor uses this

```
Input: { decision_key, old_value, new_value, reason }

Steps:
  1. Look up decision_key in the map below.
  2. For each affected doc in the list:
     a. Read the current doc.
     b. Identify sections that reference the old decision (search for old_value
        plus any common synonyms).
     c. Rewrite only those sections; preserve everything else.
     d. Append a Revision Log entry: "{date} — {decision_key} changed
        {old_value} → {new_value} (ADR {new_adr_id})"
  3. File a new ADR with full diff, rationale, alternatives reconsidered,
     consequences, rollback plan. Set supersedes: <prior_adr_id> if applicable.
  4. Update state.json: set decisions[decision_key] = new_value;
     append to adrs_filed.
  5. Run inline validation:
     - All cross-references in modified docs still resolve to files that exist.
     - No remaining mentions of old_value in unchanged sections.
     - ADR frontmatter validates.
  6. Return { files_changed: [...], adr_id: NNNN }
```

If validation in step 5 fails, surface to orchestrator, which surfaces to user. Do not commit until the user confirms or revises further.

---

## Decision → affected docs map

A `*` annotation means "regenerate only if the doc contains a section referencing this decision" (conditional propagation).

### Project meta

| decision_key | affected docs |
|---|---|
| project.name | PROJECT_OVERVIEW, CLAUDE_MD_ROOT, all per-folder CLAUDE.md, README* |
| project.type | PROJECT_OVERVIEW, CLAUDE_MD_ROOT, *(type change may invalidate other docs — flag user)* |
| project.subtype | PROJECT_OVERVIEW, type-anchored doc |
| project.scale | PROJECT_OVERVIEW, COST_MODEL, MONITORING_AND_OBSERVABILITY, SLO_AND_ERROR_BUDGETS, BACKUP_AND_DR |
| project.constraints | SECURITY_AND_COMPLIANCE, THREAT_MODEL, DEPLOYMENT*, ALL docs* (revisor flags scope) |
| project.target_users | PROJECT_OVERVIEW, PROJECT_REQUIREMENTS, ANALYTICS_AND_TELEMETRY*, ACCESSIBILITY* |

### Language / runtime

| decision_key | affected docs |
|---|---|
| language.primary | CLAUDE_MD_ROOT, all per-folder CLAUDE.md in that language, TESTING_STRATEGY, CI_CD |
| language.runtime | CLAUDE_MD_ROOT, DEPLOYMENT, CI_CD |
| package_manager | CLAUDE_MD_ROOT, CI_CD |
| monorepo_tool | CLAUDE_MD_ROOT, CI_CD, per-folder CLAUDE.md |

### Frontend

| decision_key | affected docs |
|---|---|
| frontend.framework | UI_UX_DESIGN, DEPLOYMENT, CI_CD, CLAUDE_MD_ROOT, apps/web/CLAUDE.md* |
| frontend.styling | UI_UX_DESIGN, BRAND_AND_DESIGN_TOKENS* |
| frontend.component_library | UI_UX_DESIGN |
| frontend.state | UI_UX_DESIGN |
| frontend.data_fetching | UI_UX_DESIGN, API_GATEWAY* |
| frontend.rendering | UI_UX_DESIGN, DEPLOYMENT, PERFORMANCE_BUDGETS |
| frontend.routing | UI_UX_DESIGN |

### Backend / API

| decision_key | affected docs |
|---|---|
| backend.framework | API_GATEWAY, DEPLOYMENT, CI_CD, CLAUDE_MD_ROOT |
| backend.api_style | API_GATEWAY |
| backend.versioning | API_GATEWAY, RELEASE_PROCESS* |
| backend.rate_limiting | API_GATEWAY, SECURITY_AND_COMPLIANCE |
| backend.realtime_protocol | API_GATEWAY, REAL_TIME |

### Database

| decision_key | affected docs |
|---|---|
| database.engine | DATABASE_DESIGN, API_GATEWAY, BACKUP_AND_DR, COST_MODEL, CLAUDE_MD_ROOT |
| database.host | DATABASE_DESIGN, DEPLOYMENT, COST_MODEL, BACKUP_AND_DR |
| database.orm | DATABASE_DESIGN, API_GATEWAY, CLAUDE_MD_ROOT |
| database.migration_strategy | DATABASE_DESIGN, CI_CD, RUNBOOK |
| database.normalization | DATABASE_DESIGN |
| database.multi_tenancy_isolation | DATABASE_DESIGN, TENANT_AND_ORGANIZATION_MODEL, SECURITY_AND_COMPLIANCE |

### Auth

| decision_key | affected docs |
|---|---|
| auth.provider | AUTHENTICATION_SYSTEM, SECURITY_AND_COMPLIANCE, API_GATEWAY*, CLAUDE_MD_ROOT |
| auth.methods | AUTHENTICATION_SYSTEM, UI_UX_DESIGN* |
| auth.session_strategy | AUTHENTICATION_SYSTEM, SECURITY_AND_COMPLIANCE |
| auth.oauth_providers | AUTHENTICATION_SYSTEM |
| auth.multi_tenancy | AUTHENTICATION_SYSTEM, TENANT_AND_ORGANIZATION_MODEL, DATABASE_DESIGN |
| auth.mfa | AUTHENTICATION_SYSTEM, SECURITY_AND_COMPLIANCE |

### Hosting / deployment

| decision_key | affected docs |
|---|---|
| hosting.frontend | DEPLOYMENT, CI_CD, COST_MODEL |
| hosting.backend | DEPLOYMENT, CI_CD, COST_MODEL, MONITORING_AND_OBSERVABILITY |
| hosting.cdn | DEPLOYMENT, PERFORMANCE_BUDGETS, EDGE_AND_CACHING* |
| deployment.environments | DEPLOYMENT, CI_CD |
| deployment.iac | DEPLOYMENT, CI_CD |

### Security

| decision_key | affected docs |
|---|---|
| security.encryption_at_rest | SECURITY_AND_COMPLIANCE, DATABASE_DESIGN, BACKUP_AND_DR |
| security.encryption_in_transit | SECURITY_AND_COMPLIANCE, API_GATEWAY |
| security.secret_management | SECURITY_AND_COMPLIANCE, DEPLOYMENT, CI_CD |
| security.input_validation | SECURITY_AND_COMPLIANCE, API_GATEWAY |
| security.cors | API_GATEWAY, SECURITY_AND_COMPLIANCE |
| security.csp | UI_UX_DESIGN, SECURITY_AND_COMPLIANCE |
| security.dep_scanning | CI_CD, SECURITY_AND_COMPLIANCE |

### Testing

| decision_key | affected docs |
|---|---|
| testing.unit_framework | TESTING_STRATEGY, CI_CD, CLAUDE_MD_ROOT |
| testing.e2e_framework | TESTING_STRATEGY, CI_CD |
| testing.coverage_target | TESTING_STRATEGY, CI_CD |

### Monitoring

| decision_key | affected docs |
|---|---|
| monitoring.error_tracking | MONITORING_AND_OBSERVABILITY, INCIDENT_RESPONSE |
| monitoring.apm | MONITORING_AND_OBSERVABILITY, PERFORMANCE_BUDGETS |
| monitoring.logging | MONITORING_AND_OBSERVABILITY, DEPLOYMENT |
| monitoring.uptime | MONITORING_AND_OBSERVABILITY, INCIDENT_RESPONSE |
| monitoring.analytics | ANALYTICS_AND_TELEMETRY |

### Payments / billing

| decision_key | affected docs |
|---|---|
| payments.provider | BILLING_AND_PAYMENTS, COST_MODEL, SECURITY_AND_COMPLIANCE* |
| payments.model | BILLING_AND_PAYMENTS |

### Notifications

| decision_key | affected docs |
|---|---|
| notifications.email_provider | EMAIL_AND_NOTIFICATIONS, COST_MODEL |
| notifications.push_provider | EMAIL_AND_NOTIFICATIONS, MOBILE_SPECIFIC* |
| notifications.multi_channel_provider | EMAIL_AND_NOTIFICATIONS |

### File storage

| decision_key | affected docs |
|---|---|
| file_storage.provider | FILE_STORAGE, COST_MODEL, SECURITY_AND_COMPLIANCE* |
| file_storage.cdn | FILE_STORAGE, PERFORMANCE_BUDGETS, EDGE_AND_CACHING* |

### AI / ML

| decision_key | affected docs |
|---|---|
| ai.llm_provider | AI_AND_ML, COST_MODEL, SECURITY_AND_COMPLIANCE* |
| ai.sdk | AI_AND_ML |
| ai.vector_db | AI_AND_ML, DATABASE_DESIGN |
| ai.embeddings_model | AI_AND_ML, COST_MODEL |

### Real-time

| decision_key | affected docs |
|---|---|
| realtime.protocol | REAL_TIME, API_GATEWAY |
| realtime.broker | REAL_TIME, COST_MODEL |

### Data pipeline

| decision_key | affected docs |
|---|---|
| data_pipeline.orchestrator | DATA_PIPELINE, COST_MODEL |
| data_pipeline.warehouse | DATA_PIPELINE, COST_MODEL |

### CI / CD

| decision_key | affected docs |
|---|---|
| cicd.platform | CI_CD, DEPLOYMENT |
| cicd.branch_strategy | CI_CD, CONTRIBUTING* |

### Misc

| decision_key | affected docs |
|---|---|
| i18n.languages | INTERNATIONALIZATION, UI_UX_DESIGN |
| feature_flags.provider | EXPERIMENTS, ANALYTICS_AND_TELEMETRY |
| ab_testing.provider | EXPERIMENTS, ANALYTICS_AND_TELEMETRY |
| analytics.product | ANALYTICS_AND_TELEMETRY, MONITORING_AND_OBSERVABILITY |
| open_source | CONTRIBUTING, README, LICENSE |

---

## ADR conventions

- File path: `docs/decisions/NNNN-<kebab-slug>.md`
- NNNN is sequential, zero-padded to 4 digits, never reused
- Slug is kebab-case of title, max 60 chars
- Frontmatter required: `adr_id`, `title`, `date`, `status`, `supersedes`, `superseded_by`, `affected_docs`, `decision_keys`, `research_refs`
- Status values: `proposed | accepted | superseded | deprecated`
- When ADR Y supersedes ADR X: set Y.supersedes = X.adr_id AND update X.superseded_by = Y.adr_id (revisor MUST update the old ADR's frontmatter, not just write the new one)

## Revision Log conventions

Every generated doc ends with `## Revision Log`. Initial value is `(none yet)`. Each revision appends one line:

```
- 2026-05-12 — database.engine changed PostgreSQL → SQLite+Turso (ADR 0007)
```

Ordered newest-to-oldest at the top of the list (most recent change first).

## Cross-reference preservation rules

When the revisor rewrites a section:
1. **Preserve all `[text](path)` links to other docs** unless the linked doc is being deleted in the same revision.
2. **Preserve ADR references** (`see ADR 0007`); add new ADR reference for the current change.
3. **Preserve diagrams** unless the diagram explicitly depicts the changing decision.
4. **Preserve `## Revision Log` ordering** (append, don't reorder).
5. If a section heading changes, **grep the rest of the doc-set** for back-references and update them in the same revision.
````

- [ ] **Step 2: Verify**

Run: `wc -l skills/project-architect/references/revision-playbook.md && grep -c "^### " skills/project-architect/references/revision-playbook.md`
Expected: ~220–270 lines; at least 15 H3 sections (one per decision-key group).

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/references/revision-playbook.md
git commit -m "$(cat <<'EOF'
docs(revision-playbook): add decision→affected-docs map and ADR conventions

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task B6: Create `claude-code-integration.md`

**Files:**
- Create: `skills/project-architect/references/claude-code-integration.md`

- [ ] **Step 1: Write the file**

Create `skills/project-architect/references/claude-code-integration.md` with:

````markdown
# Claude Code Integration Recipes

The `claude-tooling-author` agent reads this file to decide which `.claude/` artifacts to write for the generated project. Stack-aware hooks, permissions, agents, commands, and plugin recommendations live here.

## Table of Contents
- [Universal recommendations (every project)](#universal-recommendations-every-project)
- [Stack-conditional recommendations](#stack-conditional-recommendations)
- [Project-type-conditional recommendations](#project-type-conditional-recommendations)
- [Quality / process recommendations](#quality--process-recommendations)
- [Hook templates](#hook-templates)
- [Permission allowlist templates](#permission-allowlist-templates)
- [Project-local agent templates](#project-local-agent-templates)
- [Slash command templates](#slash-command-templates)

---

## Universal recommendations (every project)

These go in every generated `recommended-plugins.md` regardless of stack:

| Plugin / skill | Why |
|---|---|
| `superpowers:brainstorming` | Any new feature should brainstorm first |
| `superpowers:writing-plans` | Multi-step task planning |
| `superpowers:executing-plans` | Plan execution discipline |
| `superpowers:test-driven-development` | TDD discipline |
| `superpowers:systematic-debugging` | Bug investigation |
| `superpowers:verification-before-completion` | Prevent premature "done" claims |
| `superpowers:requesting-code-review` | Before merges |
| `superpowers:using-git-worktrees` | Isolation for feature work |
| `claude-md-management:revise-claude-md` | Keep CLAUDE.md current |
| `claude-md-management:claude-md-improver` | Audit CLAUDE.md quality |
| `commit-commands:commit` | Quick commit workflow |

## Stack-conditional recommendations

Selected when `decisions.<key>` matches.

### Hosting / cloud

| Stack signal | Recommended plugins |
|---|---|
| Cloudflare (Workers / Pages / D1 / R2 / KV / Durable Objects / Queues) | `cloudflare:cloudflare`, `cloudflare:wrangler`, `cloudflare:durable-objects`, `cloudflare:workers-best-practices` |
| Cloudflare + AI agents | + `cloudflare:agents-sdk`, `cloudflare:sandbox-sdk` |
| Cloudflare + email | + `cloudflare:cloudflare-email-service` |
| Cloudflare + perf concerns | + `cloudflare:web-perf` |
| Vercel + Next.js | `vercel:nextjs`, `vercel:vercel-cli`, `vercel:next-cache-components`, `vercel:react-best-practices` |
| Vercel + shadcn/ui | + `vercel:shadcn` |
| Vercel + AI | + `vercel:ai-sdk`, `vercel:ai-gateway`, `vercel:chat-sdk` |
| Vercel + auth | + `vercel:auth` |
| AWS | `aws-dev-toolkit:aws-architect`, `aws-dev-toolkit:aws-plan` + service-specific (`lambda`, `ec2`, `eks`, `ecs`, `s3`, `dynamodb`, `bedrock`, `rds-aurora`, `iam`, `networking`, `observability`) |
| AWS serverless | `aws-serverless:aws-lambda`, `aws-serverless:api-gateway`, `aws-serverless:aws-serverless-deployment` |
| Azure | `azure:azure-prepare`, `azure:azure-deploy` + service-specific (`azure-compute`, `azure-kubernetes`, `azure-storage`, `azure-ai`) |
| GCP / Firebase | `plugin_firebase:firebase`, `cloud-sql-postgresql:*` |
| Netlify | `netlify-skills:netlify-deploy`, `netlify-skills:netlify-functions`, `netlify-skills:netlify-edge-functions` |
| Fastly | `fastly-agent-toolkit:fastly`, `fastly-agent-toolkit:fastly-cli` |

### Databases / data

| Stack signal | Recommended plugins |
|---|---|
| Supabase (any product) | `supabase:supabase`, `supabase:supabase-postgres-best-practices` |
| Postgres (any host) | `supabase:supabase-postgres-best-practices` |
| CockroachDB | `cockroachdb:*` (start with `cockroachdb-sql`, `setting-up-local-cluster`) |
| MongoDB | `mongodb:mongodb-schema-design`, `mongodb:mongodb-query-optimizer`, `mongodb:mongodb-natural-language-querying` |
| Pinecone / vector DB | `pinecone:quickstart`, `pinecone:cli`, `pinecone:docs` |
| Qdrant | `qdrant:qdrant-clients-sdk`, `qdrant:qdrant-performance-optimization` |
| Zilliz / Milvus | `zilliz:quickstart`, `zilliz:vector` |
| Snowflake | `snowflake-cortex-code:cortex-setup`, `snowflake-cortex-code:cortex-router` |
| Airflow / Astronomer | `astronomer-data:airflow`, `astronomer-data:authoring-dags`, `astronomer-data:debugging-dags` |
| AlloyDB | `alloydb:alloydb-postgres-admin`, `alloydb:alloydb-postgres-optimize` |

### Frontend

| Stack signal | Recommended plugins |
|---|---|
| Figma design hand-off | `figma:figma-use`, `figma:figma-implement-design`, `figma:figma-code-connect` |
| Tailwind CSS | implicit via vercel:shadcn or figma recommendations |
| Frontend (any) | `document-skills:frontend-design`, `chrome-devtools-mcp:debug-optimize-lcp` |

### Mobile

| Stack signal | Recommended plugins |
|---|---|
| Expo / React Native | `expo:building-native-ui`, `expo:expo-deployment`, `expo:upgrading-expo`, `expo:native-data-fetching`, `expo:expo-cicd-workflows` |
| Expo + Tailwind | + `expo:expo-tailwind-setup` |
| Expo + native modules | + `expo:expo-module` |

### Auth

| Stack signal | Recommended plugins |
|---|---|
| Auth0 (any) | `auth0:auth0-quickstart` |
| Auth0 + Next.js | + `auth0:auth0-nextjs` |
| Auth0 + React | + `auth0:auth0-react` |
| Auth0 + Express | + `auth0:auth0-express` or `auth0:express-oauth2-jwt-bearer` |
| Auth0 + Vue | + `auth0:auth0-vue` |
| Auth0 + Angular | + `auth0:auth0-angular` |
| Auth0 + iOS / macOS | + `auth0:auth0-swift` |
| Auth0 + Android | + `auth0:auth0-android` |
| Auth0 + React Native / Expo | + `auth0:auth0-react-native` or `auth0:auth0-expo` |
| Auth0 + FastAPI | + `auth0:auth0-fastapi-api` |
| Auth0 + Flask | + `auth0:auth0-flask` |
| Auth0 + Spring Boot | + `auth0:auth0-springboot-api` |
| Auth0 + ASP.NET Core | + `auth0:auth0-aspnetcore-api` |
| Auth0 + MFA needs | + `auth0:auth0-mfa` |
| Auth0 + custom universal login | + `auth0:acul-screen-generator` |

### Payments / billing

| Stack signal | Recommended plugins |
|---|---|
| Stripe | `stripe:stripe-best-practices`, `stripe:test-cards`, `stripe:explain-error` |
| MercadoPago | `mercadopago:mp-setup`, `mercadopago:mp-checkout-online`, `mercadopago:mp-subscriptions` |

### Notifications / messaging

| Stack signal | Recommended plugins |
|---|---|
| Twilio (SMS / voice / WhatsApp) | `twilio-developer-kit:*` (start with `twilio-cli-reference`) |
| Twilio SendGrid (email) | `twilio-developer-kit:twilio-sendgrid-email-send`, `twilio-developer-kit:twilio-sendgrid-deliverability-advisor` |
| Slack integration | `slack:slack-messaging`, `slack:slack-search` |
| Telegram bot | `telegram:configure`, `telegram:access` |
| iMessage | `imessage:configure`, `imessage:access` |
| Discord | `discord:configure`, `discord:access` |
| Zoom | `zoom-plugin:plan-zoom-product`, `zoom-plugin:choose-zoom-approach` + product-specific |

### Testing

| Stack signal | Recommended plugins |
|---|---|
| Playwright (E2E) | `playwright-cli:playwright-cli`, `document-skills:webapp-testing` |
| Chrome DevTools debugging | `chrome-devtools-mcp:chrome-devtools`, `chrome-devtools-mcp:a11y-debugging`, `chrome-devtools-mcp:memory-leak-debugging` |

### AI / ML

| Stack signal | Recommended plugins |
|---|---|
| HuggingFace ecosystem | `huggingface-skills:hf-cli`, `huggingface-skills:huggingface-best`, `huggingface-skills:huggingface-llm-trainer` |
| HuggingFace + vision | + `huggingface-skills:huggingface-vision-trainer`, `transformers-js` |
| HuggingFace + Gradio app | + `huggingface-skills:huggingface-gradio` |
| Anthropic API integration | `claude-api` |
| Sentence-transformers | `huggingface-skills:train-sentence-transformers` |
| FiftyOne (computer vision) | `fiftyone:quickstart`, `fiftyone:fiftyone-dataset-curation` |
| Pydantic-AI agents | `ai:building-pydantic-ai-agents` |
| Vercel AI Gateway | `vercel:ai-gateway`, `vercel:ai-sdk` |

### Observability

| Stack signal | Recommended plugins |
|---|---|
| Sentry (errors) | `sentry:sentry-sdk-setup`, `sentry:sentry-workflow`, `sentry:seer` |
| Datadog | `datadog:ddsetup`, `datadog:ddconfig`, `datadog:ddtoolsets` |
| Logfire | `logfire:instrument`, `logfire:logfire-query`, `logfire:dev-session` |
| PostHog | `posthog:llma-cc-setup`, `posthog:instrument-product-analytics` + use-case specific |
| Amplitude | `amplitude:add-analytics-instrumentation`, `amplitude:create-dashboard` |
| FullStory | `fullstory:general-analysis` |
| PagerDuty | `pagerduty:pre-commit-risk-scoring` |

### Quality / security

| Stack signal | Recommended plugins |
|---|---|
| CodeRabbit | `coderabbit:code-review`, `coderabbit:autofix` |
| Semgrep | `semgrep:setup-semgrep-plugin` |
| SonarQube | `sonarqube:sonar-analyze`, `sonarqube:sonar-quality-gate` |
| Aikido | `aikido:setup`, `aikido:scan` |
| NightVision (DAST) | `nightvision:scan-configuration`, `nightvision:api-discovery` |
| 42Crunch (API security) | `api-security-testing:42crunch-setup`, `api-security-testing:42crunch-scan` |
| Vanta (compliance) | `vanta:list-tests`, `vanta:test-remediation` |
| JFrog | `jfrog:jfrog` |

### Documentation sites

| Stack signal | Recommended plugins |
|---|---|
| Mintlify | `mintlify:mintlify` |
| Generic doc co-authoring | `document-skills:doc-coauthoring`, `document-skills:internal-comms` |

### Project management / collaboration

| Stack signal | Recommended plugins |
|---|---|
| Atlassian (Jira / Confluence) | `atlassian:search-company-knowledge`, `atlassian:spec-to-backlog`, `atlassian:triage-issue` |
| Notion | `Notion:search`, `Notion:create-page`, `Notion:tasks:setup` |
| Linear | *(no first-party skill yet — recommend manual)* |
| Miro | `miro:miro-diagram`, `miro:miro-doc` |

### Code intelligence

| Stack signal | Recommended plugins |
|---|---|
| Sourcegraph | `sourcegraph:searching-sourcegraph` |

---

## Project-type-conditional recommendations

| Project type | Recommended plugins |
|---|---|
| Claude Code plugin | `plugin-dev:create-plugin`, `plugin-dev:plugin-structure`, `plugin-dev:skill-development`, `plugin-dev:command-development`, `plugin-dev:agent-development`, `plugin-dev:hook-development`, `plugin-dev:mcp-integration`, `plugin-dev:plugin-settings` |
| MCP server | `mcp-server-dev:build-mcp-server`, `mcp-server-dev:build-mcp-app`, `mcp-server-dev:build-mcpb`, `document-skills:mcp-builder` |
| Skill development | `skill-creator:skill-creator`, `document-skills:skill-creator` |
| Heavy UI / dashboards | `document-skills:frontend-design`, `document-skills:web-artifacts-builder`, `document-skills:theme-factory`, `document-skills:brand-guidelines` |
| Browser extension | *(no first-party plugin yet — manual)* |
| Game | *(no first-party plugin yet — manual)* |
| Documentation-heavy | `document-skills:doc-coauthoring`, `document-skills:internal-comms`, `mintlify:mintlify` |
| Web3 / smart contracts | *(no first-party plugin yet — recommend Foundry / Hardhat manuals)* |
| Embedded / firmware | *(no first-party plugin yet — manual)* |

---

## Quality / process recommendations

Recommend for any production-bound project:

| Plugin | Why |
|---|---|
| `coderabbit:code-review` | AI code review before merge |
| `semgrep:setup-semgrep-plugin` | Static analysis + secret scanning |
| `pr-review-toolkit:review-pr` | Specialized PR review agents |
| `code-review:code-review` | Default code-review skill |
| `superpowers:dispatching-parallel-agents` | Parallel work patterns |
| `superpowers:subagent-driven-development` | Plan execution with subagents |
| `feature-dev:feature-dev` | Guided feature development |
| `update-config` | Configure Claude Code via settings.json |
| `fewer-permission-prompts` | Reduce permission prompts |
| `hookify:hookify` | Create hooks from conversation |

---

## Hook templates

The agent writes these to `<generated-project>/.claude/hooks/` and wires them in `.claude/settings.json` under the `hooks` key.

### `post-tool-use.sh` — format on save

```bash
#!/usr/bin/env bash
# Format files after Edit/Write tool use.
# Stack-specific: if project uses Prettier / Biome / rustfmt / gofmt / black / etc.,
# the architect picks the right formatter at generation time.

set -e

# Read tool output from stdin (Claude Code hook protocol)
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.file_path // empty')

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  exit 0
fi

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.md)
    # if Prettier / Biome present
    pnpm exec biome format --write "$FILE" 2>/dev/null \
      || pnpm exec prettier --write "$FILE" 2>/dev/null \
      || true
    ;;
  *.rs)
    rustfmt "$FILE" 2>/dev/null || true
    ;;
  *.go)
    gofmt -w "$FILE" 2>/dev/null || true
    ;;
  *.py)
    ruff format "$FILE" 2>/dev/null \
      || black "$FILE" 2>/dev/null \
      || true
    ;;
esac
```

### `stop.sh` — ensure tests green before stopping

```bash
#!/usr/bin/env bash
# Run quick test suite before Claude declares "done."
# Stack-specific: command is filled in by claude-tooling-author at generation time.

set -e

# Example for a pnpm + Vitest project:
if pnpm test:quick --silent 2>&1 | tail -5; then
  exit 0
else
  echo "Tests failing — fix before claiming task complete." >&2
  exit 2
fi
```

### `pre-tool-use.sh` — block dangerous commands

```bash
#!/usr/bin/env bash
# Block obviously-dangerous commands from the Bash tool.

set -e

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ "$TOOL" != "Bash" ]]; then exit 0; fi

DANGEROUS=(
  'rm -rf /'
  'rm -rf ~'
  'git push --force.*main'
  'git push --force.*master'
  'git reset --hard origin'
)

for pattern in "${DANGEROUS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "Blocked dangerous command: $CMD" >&2
    exit 2
  fi
done

exit 0
```

### `session-start.sh` — print recent commits + open TODOs

```bash
#!/usr/bin/env bash
# Greet a new session with recent project state.

echo "=== Recent commits ==="
git log --oneline -10 2>/dev/null || true
echo
echo "=== Open TODOs ==="
rg -n "TODO|FIXME" --max-count=5 2>/dev/null | head -20 || true
```

The `claude-tooling-author` agent customizes commands and patterns to match the chosen stack.

---

## Permission allowlist templates

The agent writes these to `<generated-project>/.claude/settings.json` under `permissions.allow`. Pick the rows that match the stack.

| Stack | Allow rules |
|---|---|
| Any project | `Bash(git status)`, `Bash(git diff:*)`, `Bash(git log:*)`, `Bash(git branch:*)`, `Bash(ls:*)`, `Bash(pwd)`, `Bash(cat:*)`, `Bash(rg:*)`, `Bash(find:*)`, `Bash(echo:*)` |
| Node / TypeScript | `Bash(pnpm install)`, `Bash(pnpm dev)`, `Bash(pnpm build)`, `Bash(pnpm test:*)`, `Bash(pnpm lint:*)`, `Bash(pnpm typecheck)`, `Bash(node:*)`, `Bash(npx:*)` |
| Rust | `Bash(cargo build:*)`, `Bash(cargo test:*)`, `Bash(cargo check:*)`, `Bash(cargo clippy:*)`, `Bash(cargo fmt:*)`, `Bash(cargo run:*)` |
| Python | `Bash(uv:*)`, `Bash(pip install:*)`, `Bash(pytest:*)`, `Bash(ruff:*)`, `Bash(black:*)`, `Bash(mypy:*)`, `Bash(python:*)` |
| Go | `Bash(go build:*)`, `Bash(go test:*)`, `Bash(go run:*)`, `Bash(go mod:*)`, `Bash(gofmt:*)`, `Bash(go vet:*)` |
| Wrangler (Cloudflare) | `Bash(wrangler:*)` |
| Vercel | `Bash(vercel:*)` |
| Supabase | `Bash(supabase:*)` |
| GitHub | `Bash(gh pr:*)`, `Bash(gh issue:*)`, `Bash(gh repo view)`, `Bash(gh auth status)` |
| Docker | `Bash(docker ps)`, `Bash(docker logs:*)`, `Bash(docker compose up:*)`, `Bash(docker compose down)` |
| Test browsers | `mcp__plugin_playwright_playwright__*` |

---

## Project-local agent templates

The agent writes these to `<generated-project>/.claude/agents/<name>.md`. Each agent knows the project's specific commands.

### `test-runner.md`
```markdown
---
name: test-runner
description: Run the project's test suite and report failures. Use when the user asks to "run tests", or proactively before declaring a task complete.
tools: [Bash, Read, Grep]
model: opus
---

# Test Runner

Run the test suite for this project using the project's standard command:

```
{{stack-specific test command — e.g., pnpm test, cargo test, pytest, go test ./...}}
```

If tests fail, do NOT attempt fixes. Return a structured report:
- Total tests, passed, failed, skipped
- For each failure: file:line, error message, last-N lines of context
- Suggested next steps for the orchestrator (debug? skip? mark blocked?)
```

### `migration-checker.md` (when database present)
```markdown
---
name: migration-checker
description: Validate that database migrations are forward and backward compatible. Use before applying any migration in production.
tools: [Bash, Read, Grep, Glob]
model: opus
---

# Migration Checker

Check the latest migration for:
1. **Forward-compat**: does the migration run cleanly against a fresh DB at HEAD?
2. **Backward-compat**: can the prior app version run against the new schema (no breaking column drops, no NOT NULL without default)?
3. **Rollback**: does the down-migration exist and reverse cleanly?
4. **Lock pressure**: does it acquire long locks on hot tables?
5. **Data backfills**: are large UPDATEs batched?

Return a structured report with PASS/FAIL per check.
```

### `deploy-verifier.md` (when production-bound)
```markdown
---
name: deploy-verifier
description: Smoke-test a deployment after it lands. Use after `wrangler deploy` / `vercel --prod` / equivalent.
tools: [Bash, Read]
model: opus
---

# Deploy Verifier

Run smoke tests against the deployed environment:
1. Health endpoint returns 200
2. Auth flow completes
3. Critical user paths complete (paste-in or framework-specific)
4. Error tracker shows no new spike
5. APM shows no new latency regression

Return PASS/FAIL with citations from logs / metrics.
```

---

## Slash command templates

The agent writes these to `<generated-project>/.claude/commands/<name>.md`.

### `feature.md`
```markdown
---
description: Start a new feature with brainstorming → plan → implementation workflow
---

# /feature

Start a new feature in this project.

## Workflow
1. Invoke `superpowers:brainstorming` to refine the idea.
2. Invoke `superpowers:writing-plans` to write an implementation plan.
3. Decide subagent-driven vs inline execution.
4. Invoke `superpowers:subagent-driven-development` or `superpowers:executing-plans`.

Project stack:
{{stack summary}}

Project conventions:
- {{key conventions from CLAUDE.md}}

Begin by asking the user: "What feature do you want to build?"
```

### `run-tests.md`
```markdown
---
description: Run the project test suite
---

# /run-tests

Dispatch the `test-runner` project agent. Summarize failures (if any) and offer to investigate the first one.
```

### `deploy-preview.md` (web projects)
```markdown
---
description: Deploy a preview to {{platform}} for the current branch
---

# /deploy-preview

Run:
```
{{stack-specific preview deploy command}}
```

Report the preview URL when the deploy completes.
```
````

- [ ] **Step 2: Verify**

Run: `wc -l skills/project-architect/references/claude-code-integration.md && grep -c "^### " skills/project-architect/references/claude-code-integration.md`
Expected: ~470–560 lines; at least 20 H3 sections.

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/references/claude-code-integration.md
git commit -m "$(cat <<'EOF'
docs(integration): add stack→skills/hooks/agents/commands recipes

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase C — Templates

Each template file lives at `skills/project-architect/references/templates/<NAME>.md` and has the structure:

```markdown
---
template_name: <NAME>
generate_when: "<expression>"           # see document-catalog.md
required_decisions: [list of decision keys]
optional_decisions: [list of decision keys]
depends_on: [other template names]      # for topological order
revision_triggers: [decision keys]      # mirrors revision-playbook.md
---

# <Title>: {{project_name}}

## <Section 1>
<placeholder prose pattern>

...

## Revision Log
(none yet)
```

Each Phase-C task batches all templates in one category. Inside each task, every template file is fully spec'd (frontmatter + section list). Tasks C1–C6 are independent — can be dispatched in parallel by subagent-driven-development.

The body prose is intentionally minimal — the `document-author` agent expands it at bootstrap time using actual project decisions. The plan provides the structural skeleton (frontmatter + sections + one-line section purpose), not finished prose.

---

### Task C1: Core templates (6 files)

**Files:**
- Create: `skills/project-architect/references/templates/PROJECT_OVERVIEW.md`
- Create: `skills/project-architect/references/templates/PROJECT_REQUIREMENTS.md`
- Create: `skills/project-architect/references/templates/ADR_TEMPLATE.md`
- Create: `skills/project-architect/references/templates/REVISION_LOG_FRAGMENT.md`
- Create: `skills/project-architect/references/templates/CLAUDE_MD_ROOT.md`
- Create: `skills/project-architect/references/templates/CLAUDE_MD_SUBFOLDER.md`

- [ ] **Step 1: Remove old monolithic templates file (if present) and the templates/.gitkeep**

Run: `rm -f skills/project-architect/references/document-templates.md skills/project-architect/references/templates/.gitkeep`

- [ ] **Step 2: Create `PROJECT_OVERVIEW.md`**

```markdown
---
template_name: PROJECT_OVERVIEW
generate_when: "always"
required_decisions:
  - project.name
  - project.elevator_pitch
  - project.type
  - project.subtype
  - project.target_users
  - project.scale
optional_decisions:
  - project.constraints
  - project.preexisting
depends_on: []
revision_triggers:
  - project.name
  - project.type
  - project.subtype
  - project.scale
---

# {{project_name}}

## Vision
One paragraph: what it is, who it's for, why it matters. Pulled from `project.elevator_pitch` and expanded with target users.

## Project Type
{{project.type}} → {{project.subtype}}. {{project.stage}}.

## Tech Stack Summary
Table: layer | technology | one-line rationale. Pulled from all `language.*`, `frontend.*`, `backend.*`, `database.*`, `auth.*`, `hosting.*` decisions.

## Architecture Diagram
Mermaid or ASCII showing major components and data flow. Composed from tech stack + Phase 3 architecture decisions.

## Document Index
Table: document | description | status. Includes only docs actually generated for this project.

## Key Decisions Log
Brief table of major decisions with ADR ID, decision, rationale (one line each).

## Constraints & Non-Goals
Pulled from `project.constraints` plus any explicit out-of-scope items captured in Phase 1.

## Revision Log
(none yet)
```

- [ ] **Step 3: Create `PROJECT_REQUIREMENTS.md`**

```markdown
---
template_name: PROJECT_REQUIREMENTS
generate_when: "always"
required_decisions:
  - project.problem_statement
  - project.target_users
  - features
optional_decisions:
  - non_functional.performance
  - non_functional.scalability
  - non_functional.availability
  - non_functional.security
  - non_functional.accessibility
  - non_functional.i18n
  - project.constraints
  - success_metrics
depends_on: [PROJECT_OVERVIEW]
revision_triggers:
  - features
  - project.target_users
  - non_functional.*
---

# Project Requirements: {{project_name}}

## Problem Statement
What problem this solves, for whom, and why now.

## Target Users
User personas / categories with one-paragraph descriptions.

## Functional Requirements

### Core Features (MVP)
Numbered list of features with one-sentence description + sub-bullets for sub-requirements.

### Future Features (Post-MVP)
Same shape; pulled from features tagged `phase: post-mvp`.

## Non-Functional Requirements
Performance, scalability, availability, security (high-level — defer details to SECURITY_AND_COMPLIANCE.md), accessibility, i18n.

## Technical Constraints
Pre-existing decisions, required integrations, budget limits.

## Success Metrics
How to measure if the project achieves its goals.

## Revision Log
(none yet)
```

- [ ] **Step 4: Create `ADR_TEMPLATE.md`**

```markdown
---
template_name: ADR_TEMPLATE
generate_when: "n/a (used by agents, never selected as a standalone doc)"
required_decisions: []
optional_decisions: []
depends_on: []
revision_triggers: []
---

---
adr_id: {{NNNN}}                       # zero-padded sequential
title: {{title}}
date: {{YYYY-MM-DD}}
status: proposed | accepted | superseded | deprecated
supersedes: {{prior_adr_id or null}}
superseded_by: null                     # filled in if a future ADR supersedes this
affected_docs: [{{list of doc filenames}}]
decision_keys: [{{list of decision keys this records}}]
research_refs: [{{paths to research findings consulted}}]
---

# ADR {{NNNN}}: {{title}}

## Status
{{status}} {{(supersedes ADR {{prior_id}} if applicable)}}

## Context
What changed. What new information surfaced. Why we're (re)deciding.

## Prior decision (if superseding)
What was chosen before and why. Link to prior ADR.

## Decision
What is being chosen and why. Concrete and specific.

## Alternatives reconsidered
- {{alt}} — why not

## Consequences
- {{consequence}} — affected doc, mitigation

## Rollback plan
If this turns out wrong, how do we revert? What's the cost?

## References
- Prior ADR: {{prior_id}}
- Research: {{research_refs}}
- Related: {{external links}}
```

- [ ] **Step 5: Create `REVISION_LOG_FRAGMENT.md`**

```markdown
---
template_name: REVISION_LOG_FRAGMENT
generate_when: "n/a (used by decision-revisor when appending entries)"
required_decisions: []
optional_decisions: []
depends_on: []
revision_triggers: []
---

## Revision Log
- {{YYYY-MM-DD}} — {{decision_key}} changed {{old_value}} → {{new_value}} (ADR {{NNNN}})
```

When appended to a doc, the entry is added to the top of the existing list (newest first). If the doc has `## Revision Log\n(none yet)`, the agent replaces `(none yet)` with the first real entry.

- [ ] **Step 6: Create `CLAUDE_MD_ROOT.md`**

```markdown
---
template_name: CLAUDE_MD_ROOT
generate_when: "always"
required_decisions:
  - project.name
  - project.type
  - language.primary
optional_decisions:
  - frontend.framework
  - backend.framework
  - database.engine
  - auth.provider
  - hosting.frontend
  - hosting.backend
  - testing.unit_framework
  - package_manager
depends_on: [PROJECT_OVERVIEW, PROJECT_REQUIREMENTS]
revision_triggers:
  - language.primary
  - frontend.framework
  - backend.framework
  - database.engine
  - auth.provider
  - project.type
  - testing.unit_framework
  - package_manager
---

# {{project_name}}

## Project Overview
One sentence: what this project is. Link to `docs/PROJECT_OVERVIEW.md` for the full pitch.

## Tech Stack
Concise table — one row per major layer.

## Project Structure
Brief listing of key directories with one-line purpose each. Highlight which subdirs have their own CLAUDE.md.

## Development Commands
Install, dev, build, test, lint, typecheck. Stack-specific (pnpm / cargo / pip / go).

## Code Conventions
- Naming: {{convention}}
- Formatting: {{tool + config file}}
- Linting: {{tool + config file}}
- Test placement: {{co-located / __tests__ / tests/}}
- Commit style: {{conventional / freeform}}

## Architecture Notes
Key architectural decisions that affect coding patterns. One line per decision, link to ADR.

## Key Files
Path → purpose, one line each. Limit to ~10 most-important files.

## Where to look
- `docs/` — full architecture documentation
- `docs/decisions/` — ADRs
- `docs/research/` — research findings from bootstrap
- `<subdir>/CLAUDE.md` — area-specific conventions (if applicable)
```

Note: CLAUDE.md does NOT include a Revision Log section. CLAUDE.md is iterated freely via `claude-md-management:revise-claude-md`.

- [ ] **Step 7: Create `CLAUDE_MD_SUBFOLDER.md`**

```markdown
---
template_name: CLAUDE_MD_SUBFOLDER
generate_when: "subfolder meets gating triggers (see claude-md-author system prompt)"
required_decisions:
  - subfolder.path
  - subfolder.purpose
optional_decisions:
  - subfolder.language
  - subfolder.framework
  - subfolder.test_framework
  - subfolder.build_command
depends_on: [CLAUDE_MD_ROOT]
revision_triggers:
  - subfolder.language
  - subfolder.framework
  - subfolder.test_framework
---

# {{subfolder.path}}

## Purpose
What this area is responsible for. How it relates to the rest of the project.

## Local Tech Stack
Only list what differs from the root CLAUDE.md.

## Conventions Specific to This Area
- {{convention}} — why
- {{convention}} — why

## Local Development Commands
Only commands that are different from root (test, build, run).

## Key Files In This Area
Path → purpose.

## Cross-references
- Root: `../CLAUDE.md` for project-wide conventions
- Related docs: {{relevant docs/ links}}
```

- [ ] **Step 8: Verify all 6 files exist**

Run: `ls -1 skills/project-architect/references/templates/`
Expected: at least 6 files (PROJECT_OVERVIEW.md, PROJECT_REQUIREMENTS.md, ADR_TEMPLATE.md, REVISION_LOG_FRAGMENT.md, CLAUDE_MD_ROOT.md, CLAUDE_MD_SUBFOLDER.md).

Run: `for f in skills/project-architect/references/templates/*.md; do head -1 "$f" | grep -q '^---$' && echo "OK: $f" || echo "BAD: $f"; done`
Expected: every file prints "OK: ...".

- [ ] **Step 9: Commit**

```bash
git add skills/project-architect/references/templates/ skills/project-architect/references/document-templates.md
git commit -m "$(cat <<'EOF'
templates(core): add 6 core templates; remove monolithic document-templates.md

Templates: PROJECT_OVERVIEW, PROJECT_REQUIREMENTS, ADR_TEMPLATE,
REVISION_LOG_FRAGMENT, CLAUDE_MD_ROOT, CLAUDE_MD_SUBFOLDER.

The v1 monolithic document-templates.md is removed; its content is
now split across templates/ files generated by subsequent tasks.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task C2: Architecture templates (11 files)

**Files:**
- Create 11 files under `skills/project-architect/references/templates/`: AUTHENTICATION_SYSTEM, DATABASE_DESIGN, API_GATEWAY, UI_UX_DESIGN, PLATFORMS, SECURITY_AND_COMPLIANCE, DEPLOYMENT, CI_CD, TESTING_STRATEGY, THIRD_PARTY_INTEGRATIONS, MONITORING_AND_OBSERVABILITY.

For each: file path, full frontmatter, section list. Each template body should follow the same pattern: heading, one-line description per section, end with `## Revision Log\n(none yet)`.

- [ ] **Step 1: Create AUTHENTICATION_SYSTEM.md**

Frontmatter:
```yaml
---
template_name: AUTHENTICATION_SYSTEM
generate_when: "decisions.auth.enabled == true"
required_decisions: [auth.provider, auth.methods, auth.session_strategy]
optional_decisions: [auth.oauth_providers, auth.multi_tenancy, auth.mfa, auth.password_policy]
depends_on: []
revision_triggers: [auth.provider, auth.methods, auth.session_strategy, auth.multi_tenancy, auth.mfa]
---
```

Sections (each with a one-line purpose):
- Auth Provider — chosen provider + rationale
- Authentication Methods — list with descriptions
- Auth Flow Diagrams — sign-up, sign-in, password reset (mermaid or ASCII)
- Session Management — strategy, token storage, duration, refresh, concurrent sessions
- Authorization Model — RBAC/ABAC/simple; role list with permissions
- Multi-Tenancy — isolation model, tenant identification (omit if not multi-tenant)
- OAuth Providers — list with scopes
- MFA — TOTP/passkeys/SMS choice + enrollment flow
- Security Considerations — password hashing, rate limits, lockout, CSRF, token rotation
- Implementation Packages — specific SDKs/libraries
- Revision Log

- [ ] **Step 2: Create DATABASE_DESIGN.md**

Frontmatter:
```yaml
---
template_name: DATABASE_DESIGN
generate_when: "decisions.database.engine != null"
required_decisions: [database.engine, database.host, database.orm]
optional_decisions: [database.normalization, database.migration_strategy, database.soft_delete, database.audit_log, database.multi_tenancy_isolation, database.indexing_strategy, database.backup]
depends_on: []
revision_triggers: [database.engine, database.host, database.orm, database.migration_strategy, database.multi_tenancy_isolation]
---
```

Sections: Database Choice; ORM/Query Layer; Schema Overview (ERD + Core Entities table per entity); Relationships; Indexing Strategy; Migration Strategy; Data Policies (soft delete, audit, retention, backup); Multi-Tenancy Data Model (skip if N/A); Seeding & Test Data; Revision Log.

- [ ] **Step 3: Create API_GATEWAY.md**

Frontmatter:
```yaml
---
template_name: API_GATEWAY
generate_when: "decisions.api.enabled == true"
required_decisions: [backend.framework, backend.api_style]
optional_decisions: [backend.versioning, backend.rate_limiting, backend.realtime_protocol, backend.webhooks]
depends_on: [AUTHENTICATION_SYSTEM, DATABASE_DESIGN]
revision_triggers: [backend.framework, backend.api_style, backend.versioning, backend.realtime_protocol]
---
```

Sections: API Style; Base URL & Versioning; Authentication & Authorization (link to AUTHENTICATION_SYSTEM.md); Endpoints/Operations (one subsection per resource); Common Patterns (pagination, filtering, sorting, error format, rate limiting); Real-Time (skip if N/A); API Documentation; Webhooks (skip if N/A); Revision Log.

- [ ] **Step 4: Create UI_UX_DESIGN.md**

Frontmatter:
```yaml
---
template_name: UI_UX_DESIGN
generate_when: "decisions.frontend.framework != null"
required_decisions: [frontend.framework, frontend.styling]
optional_decisions: [frontend.component_library, frontend.state, frontend.data_fetching, frontend.routing, frontend.rendering, frontend.i18n, a11y.target]
depends_on: []
revision_triggers: [frontend.framework, frontend.styling, frontend.component_library, frontend.state, frontend.rendering]
---
```

Sections: Design System; Layout & Navigation; Key Pages/Screens (one subsection per page); Theme & Styling (palette, typography, dark mode, spacing); State Management; Rendering Strategy; Accessibility; Internationalization (skip if N/A); Performance Targets; Revision Log.

- [ ] **Step 5: Create PLATFORMS.md**

Frontmatter:
```yaml
---
template_name: PLATFORMS
generate_when: "decisions.platforms.length > 1"
required_decisions: [platforms]
optional_decisions: [code_sharing_strategy, platform_specific.*]
depends_on: []
revision_triggers: [platforms, code_sharing_strategy]
---
```

Sections: Supported Platforms (table: platform | tech | priority | min version); Code Sharing Strategy; Platform-Specific Considerations (subsection per platform with: distribution, native APIs, permissions, offline, storage, push, deep links); Sync Strategy; Release Strategy (versioning, cadence, update mechanism); Revision Log.

- [ ] **Step 6: Create SECURITY_AND_COMPLIANCE.md**

Frontmatter:
```yaml
---
template_name: SECURITY_AND_COMPLIANCE
generate_when: "decisions.auth.enabled == true OR decisions.constraints.includes('regulated')"
required_decisions: []
optional_decisions: [security.*, regulatory.*, project.constraints]
depends_on: [AUTHENTICATION_SYSTEM, DATABASE_DESIGN]
revision_triggers: [security.*, regulatory.*, auth.provider, database.engine]
---
```

Sections: Threat Model (high-level); Regulatory Requirements (specific obligations per regulation); Data Classification (table); Encryption (in-transit, at-rest, E2E if applicable, post-quantum if applicable); Secret Management; Input Validation & Sanitization; Dependency Security; Access Control (reference AUTHENTICATION_SYSTEM); Privacy (collection, deletion, export, cookies); Incident Response (high-level — link to RUNBOOK / INCIDENT_RESPONSE); Compliance Checklist; Revision Log.

- [ ] **Step 7: Create DEPLOYMENT.md**

Frontmatter:
```yaml
---
template_name: DEPLOYMENT
generate_when: "decisions.hosting.frontend != null OR decisions.hosting.backend != null"
required_decisions: [hosting.frontend, hosting.backend]
optional_decisions: [hosting.cdn, deployment.environments, deployment.iac, deployment.preview_deploys, deployment.rollback]
depends_on: []
revision_triggers: [hosting.frontend, hosting.backend, hosting.cdn, deployment.iac]
---
```

Sections: Environments (table); Infrastructure (subsection per service with: provider, config, scaling, region); Domain & DNS; Environment Variables (table — names + descriptions, NOT values); Deployment Process; Rollback Strategy; Preview Deployments; Revision Log.

- [ ] **Step 8: Create CI_CD.md**

Frontmatter:
```yaml
---
template_name: CI_CD
generate_when: "decisions.devops.cicd != null"
required_decisions: [cicd.platform]
optional_decisions: [cicd.branch_strategy, testing.coverage_target, security.dep_scanning]
depends_on: [TESTING_STRATEGY, DEPLOYMENT]
revision_triggers: [cicd.platform, cicd.branch_strategy, testing.unit_framework, testing.e2e_framework]
---
```

Sections: CI/CD Platform; Pipeline Stages (on PR / on merge to main / on release tag — each with numbered step list); Quality Gates (tests, lint, type-check, security scan, build); Branch Strategy; Secrets Management in CI (link to SECURITY_AND_COMPLIANCE); Artifact Management; Revision Log.

- [ ] **Step 9: Create TESTING_STRATEGY.md**

Frontmatter:
```yaml
---
template_name: TESTING_STRATEGY
generate_when: "decisions.scale != \"hobby\" OR decisions.project.type != \"library\""
required_decisions: [testing.unit_framework]
optional_decisions: [testing.integration_framework, testing.e2e_framework, testing.visual_framework, testing.coverage_target]
depends_on: []
revision_triggers: [testing.unit_framework, testing.integration_framework, testing.e2e_framework, testing.coverage_target]
---
```

Sections: Testing Philosophy; Testing Stack (table: type | tool | coverage target); Test Structure (directory convention, naming, fixtures/mocks); Key Testing Scenarios (critical paths); Test Data Strategy; CI Integration; Performance Testing (skip if N/A); Revision Log.

- [ ] **Step 10: Create THIRD_PARTY_INTEGRATIONS.md**

Frontmatter:
```yaml
---
template_name: THIRD_PARTY_INTEGRATIONS
generate_when: "decisions.integrations.length > 0"
required_decisions: [integrations]
optional_decisions: [webhooks.inbound, background_jobs.queue, scheduled_tasks]
depends_on: []
revision_triggers: [integrations, webhooks.inbound, background_jobs.queue]
---
```

Sections: Integration Overview (table: service | purpose | type | priority); Integration Details (subsection per integration: purpose, SDK, auth method, key endpoints, rate limits, fallback strategy, cost); Event/Webhook Processing (skip if N/A); Background Jobs & Queues (skip if N/A); Scheduled Tasks (skip if N/A); Revision Log.

- [ ] **Step 11: Create MONITORING_AND_OBSERVABILITY.md**

Frontmatter:
```yaml
---
template_name: MONITORING_AND_OBSERVABILITY
generate_when: "decisions.scale != \"hobby\" AND decisions.production_bound == true"
required_decisions: []
optional_decisions: [monitoring.*, analytics.product]
depends_on: []
revision_triggers: [monitoring.*, analytics.product]
---
```

Sections: Monitoring Stack (table: concern | tool | purpose); Logging Strategy (format, levels, PII handling, retention); Alerting Rules (table); Dashboards; Health Checks; Performance Budgets (link to PERFORMANCE_BUDGETS.md); Revision Log.

- [ ] **Step 12: Verify all 11 files exist with valid frontmatter**

Run:
```bash
ls -1 skills/project-architect/references/templates/ | grep -E '^(AUTHENTICATION_SYSTEM|DATABASE_DESIGN|API_GATEWAY|UI_UX_DESIGN|PLATFORMS|SECURITY_AND_COMPLIANCE|DEPLOYMENT|CI_CD|TESTING_STRATEGY|THIRD_PARTY_INTEGRATIONS|MONITORING_AND_OBSERVABILITY)\.md$' | wc -l
```
Expected: 11.

- [ ] **Step 13: Commit**

```bash
git add skills/project-architect/references/templates/
git commit -m "$(cat <<'EOF'
templates(architecture): add 11 architecture templates

AUTHENTICATION_SYSTEM, DATABASE_DESIGN, API_GATEWAY, UI_UX_DESIGN,
PLATFORMS, SECURITY_AND_COMPLIANCE, DEPLOYMENT, CI_CD,
TESTING_STRATEGY, THIRD_PARTY_INTEGRATIONS, MONITORING_AND_OBSERVABILITY.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task C3: Feature-area templates (11 files)

**Files:** Create 11 files under `skills/project-architect/references/templates/`: BILLING_AND_PAYMENTS, EMAIL_AND_NOTIFICATIONS, FILE_STORAGE, AI_AND_ML, REAL_TIME, SEARCH, CACHING_STRATEGY, INTERNATIONALIZATION, ACCESSIBILITY, DATA_PIPELINE, BACKGROUND_JOBS.

For each, follow the same template structure (frontmatter + section list + `## Revision Log` ending). Frontmatter must be exact (used by document-catalog parser).

- [ ] **Step 1: Create BILLING_AND_PAYMENTS.md**

```yaml
---
template_name: BILLING_AND_PAYMENTS
generate_when: "decisions.monetization.enabled == true"
required_decisions: [payments.provider, payments.model]
optional_decisions: [payments.pricing_tiers, payments.taxation, payments.fraud_prevention]
depends_on: []
revision_triggers: [payments.provider, payments.model, payments.pricing_tiers]
---
```
Sections: Provider & Rationale; Pricing Model (one-time / subscription / usage / tiered); Pricing Tiers Table; Checkout Flow; Webhook Handling (link to THIRD_PARTY_INTEGRATIONS); Refunds & Disputes; Taxation Strategy; Fraud Prevention; Reporting & Reconciliation; Revision Log.

- [ ] **Step 2: Create EMAIL_AND_NOTIFICATIONS.md**

```yaml
---
template_name: EMAIL_AND_NOTIFICATIONS
generate_when: "decisions.notifications.enabled == true"
required_decisions: [notifications.email_provider]
optional_decisions: [notifications.push_provider, notifications.sms_provider, notifications.multi_channel_provider, notifications.templates_location]
depends_on: []
revision_triggers: [notifications.email_provider, notifications.push_provider, notifications.multi_channel_provider]
---
```
Sections: Channels Overview; Transactional Email (provider + template strategy); Marketing Email (if applicable); Push Notifications (per platform); SMS (if applicable); Multi-Channel Orchestration (if applicable); Templates & Localization; User Preferences & Unsubscribe; Deliverability Strategy; Revision Log.

- [ ] **Step 3: Create FILE_STORAGE.md**

```yaml
---
template_name: FILE_STORAGE
generate_when: "decisions.file_handling.enabled == true"
required_decisions: [file_storage.provider]
optional_decisions: [file_storage.cdn, file_storage.processing, file_storage.access_control]
depends_on: []
revision_triggers: [file_storage.provider, file_storage.cdn]
---
```
Sections: Storage Provider; Bucket / Container Layout; Upload Flow (direct vs proxied); Access Control (signed URLs, public/private); Processing Pipeline (resizing, transcoding, OCR — if applicable); CDN & Caching; Lifecycle Policies (archive / delete); Costs (link to COST_MODEL); Revision Log.

- [ ] **Step 4: Create AI_AND_ML.md**

```yaml
---
template_name: AI_AND_ML
generate_when: "decisions.ai.enabled == true"
required_decisions: [ai.llm_provider]
optional_decisions: [ai.sdk, ai.vector_db, ai.embeddings_model, ai.streaming, ai.guardrails, ai.evaluation]
depends_on: []
revision_triggers: [ai.llm_provider, ai.sdk, ai.vector_db, ai.embeddings_model]
---
```
Sections: LLM Provider & Models; SDK / Integration Layer; Prompt Caching & Cost Optimization; Streaming Strategy; Tool Use / Function Calling; RAG Pipeline (chunking, embeddings, retrieval — if applicable); Vector Store; Guardrails & Safety; Evaluation & Quality Gates; Cost Controls; Revision Log.

- [ ] **Step 5: Create REAL_TIME.md**

```yaml
---
template_name: REAL_TIME
generate_when: "decisions.realtime.enabled == true"
required_decisions: [realtime.protocol]
optional_decisions: [realtime.broker, realtime.presence, realtime.scaling_strategy]
depends_on: []
revision_triggers: [realtime.protocol, realtime.broker]
---
```
Sections: Transport Protocol (WebSocket / SSE / WebRTC / WebTransport); Event Types & Schema; Connection Lifecycle (auth, reconnect, heartbeat); Presence Model (if applicable); Scaling Strategy (sharding, broker); Backpressure & Rate Limits; Revision Log.

- [ ] **Step 6: Create SEARCH.md**

```yaml
---
template_name: SEARCH
generate_when: "decisions.search.enabled == true"
required_decisions: [search.engine]
optional_decisions: [search.indexing_strategy, search.faceting, search.semantic, search.relevance_tuning]
depends_on: []
revision_triggers: [search.engine, search.indexing_strategy]
---
```
Sections: Search Engine Choice; Indexing Strategy (synchronous / async / batch); Index Schema; Query Patterns (full-text / faceted / semantic / hybrid); Relevance Tuning; Performance Targets; Reindexing Strategy; Revision Log.

- [ ] **Step 7: Create CACHING_STRATEGY.md**

```yaml
---
template_name: CACHING_STRATEGY
generate_when: "decisions.scale >= \"growth\" OR decisions.caching.enabled == true"
required_decisions: []
optional_decisions: [caching.edge, caching.app_cache, caching.db_cache, caching.invalidation_strategy]
depends_on: []
revision_triggers: [caching.edge, caching.app_cache, caching.db_cache]
---
```
Sections: Cache Layers (edge / app / DB); CDN Caching; Application Cache (Redis / Memcached / in-process); Database Query Cache; Invalidation Strategy (TTL / event-driven / versioning); Cache-Warming; Monitoring (hit rate); Revision Log.

- [ ] **Step 8: Create INTERNATIONALIZATION.md**

```yaml
---
template_name: INTERNATIONALIZATION
generate_when: "decisions.i18n.languages.length > 1"
required_decisions: [i18n.languages]
optional_decisions: [i18n.library, i18n.translation_workflow, i18n.rtl_support]
depends_on: [UI_UX_DESIGN]
revision_triggers: [i18n.languages, i18n.library, i18n.rtl_support]
---
```
Sections: Supported Locales; i18n Library; Translation Workflow (where source strings live, how translations come back); String Externalization Conventions; Date/Number/Currency Formatting; RTL Support; Pluralization & Gender; Revision Log.

- [ ] **Step 9: Create ACCESSIBILITY.md**

```yaml
---
template_name: ACCESSIBILITY
generate_when: "decisions.frontend.framework != null AND decisions.a11y.target != null"
required_decisions: [a11y.target]
optional_decisions: [a11y.audit_tooling, a11y.screen_reader_priorities]
depends_on: [UI_UX_DESIGN]
revision_triggers: [a11y.target]
---
```
Sections: WCAG Target Level; Keyboard Navigation; Screen Reader Support; Color & Contrast; Focus Management; ARIA Patterns Used; Audit Tooling (axe / Lighthouse / Pa11y); Revision Log.

- [ ] **Step 10: Create DATA_PIPELINE.md**

```yaml
---
template_name: DATA_PIPELINE
generate_when: "decisions.data_pipeline.enabled == true"
required_decisions: [data_pipeline.orchestrator]
optional_decisions: [data_pipeline.warehouse, data_pipeline.sources, data_pipeline.sinks, data_pipeline.sla]
depends_on: []
revision_triggers: [data_pipeline.orchestrator, data_pipeline.warehouse]
---
```
Sections: Sources & Sinks; Orchestrator Choice; DAG Overview (high-level); Schedule & SLAs; Data Quality & Validation; Schema Evolution; Observability (OpenLineage / lineage); Failure / Retry Policy; Revision Log.

- [ ] **Step 11: Create BACKGROUND_JOBS.md**

```yaml
---
template_name: BACKGROUND_JOBS
generate_when: "decisions.background_jobs.enabled == true"
required_decisions: [background_jobs.queue]
optional_decisions: [background_jobs.scheduling, background_jobs.idempotency, background_jobs.retry_policy]
depends_on: []
revision_triggers: [background_jobs.queue, background_jobs.scheduling]
---
```
Sections: Queue / Broker Choice; Job Types (table: job | trigger | frequency | priority); Idempotency Strategy; Retry Policy; Dead-Letter Queues; Scheduling (cron / event-driven); Concurrency Limits; Monitoring; Revision Log.

- [ ] **Step 12: Verify**

Run: `ls -1 skills/project-architect/references/templates/ | wc -l`
Expected: 17 (6 core + 11 architecture and we're adding 11 more = 28 after this task; but core was already created in C1 and architecture in C2 — so after C3 we expect 28).

- [ ] **Step 13: Commit**

```bash
git add skills/project-architect/references/templates/
git commit -m "$(cat <<'EOF'
templates(feature-area): add 11 feature-area templates

BILLING_AND_PAYMENTS, EMAIL_AND_NOTIFICATIONS, FILE_STORAGE, AI_AND_ML,
REAL_TIME, SEARCH, CACHING_STRATEGY, INTERNATIONALIZATION, ACCESSIBILITY,
DATA_PIPELINE, BACKGROUND_JOBS.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task C4: Project-type-specific templates (12 files)

**Files:** Create 12 files under `skills/project-architect/references/templates/`.

For each template below: write the file with the given frontmatter and the section list provided. Body sections each get a one-line description of what they capture. Every file ends with `## Revision Log\n(none yet)`.

- [ ] **Step 1: Create MOBILE_SPECIFIC.md**
```yaml
template_name: MOBILE_SPECIFIC
generate_when: "decisions.project.type == 'mobile' OR decisions.platforms.includes('mobile')"
required_decisions: [mobile.platforms, mobile.framework]
optional_decisions: [mobile.distribution, mobile.offline, mobile.push, mobile.deep_links, mobile.in_app_purchases]
depends_on: []
revision_triggers: [mobile.platforms, mobile.framework, mobile.distribution]
```
Sections: Platforms & Min OS; Framework; Distribution (App Store / Play / TestFlight / sideload); Offline & Sync; Push Notifications; Deep Links / Universal Links; In-App Purchases (if applicable); Native Integrations (camera, biometrics, location, etc.); Code-Push / OTA Update strategy; Revision Log.

- [ ] **Step 2: Create DESKTOP_SPECIFIC.md**
```yaml
template_name: DESKTOP_SPECIFIC
generate_when: "decisions.project.type == 'desktop'"
required_decisions: [desktop.platforms, desktop.framework]
optional_decisions: [desktop.distribution, desktop.auto_update, desktop.system_integration, desktop.sandboxing]
depends_on: []
revision_triggers: [desktop.platforms, desktop.framework, desktop.distribution]
```
Sections: Target Platforms; Framework (Tauri / Electron / native); Distribution; Auto-Update Mechanism; System Integration (menu bar, tray, file associations, deep links); Sandboxing / Entitlements; Code-Signing & Notarization; Revision Log.

- [ ] **Step 3: Create EMBEDDED_SPECIFIC.md**
```yaml
template_name: EMBEDDED_SPECIFIC
generate_when: "decisions.project.type == 'embedded'"
required_decisions: [embedded.mcu_class, embedded.language]
optional_decisions: [embedded.rtos, embedded.connectivity, embedded.ota, embedded.power_budget]
depends_on: []
revision_triggers: [embedded.mcu_class, embedded.language, embedded.rtos, embedded.connectivity]
```
Sections: MCU / SoC Choice; RTOS (or bare-metal); Programming Language; Power Budget; Connectivity (BLE / Wi-Fi / LoRa / cellular); OTA Update Mechanism; Tooling (PlatformIO / esp-idf / Zephyr); Bootloader & Recovery; Revision Log.

- [ ] **Step 4: Create ML_OPS.md**
```yaml
template_name: ML_OPS
generate_when: "decisions.project.type == 'ai_ml' AND decisions.ml.training == true"
required_decisions: [ml.training_framework]
optional_decisions: [ml.dataset_versioning, ml.experiment_tracking, ml.serving, ml.monitoring, ml.evaluation_benchmarks]
depends_on: [AI_AND_ML]
revision_triggers: [ml.training_framework, ml.serving, ml.experiment_tracking]
```
Sections: Training Framework; Dataset Versioning & Provenance; Experiment Tracking (Weights & Biases / MLflow / Trackio); Hyperparameter Sweep Strategy; Model Registry; Serving Stack (inference); Model Monitoring (drift, latency, cost); Evaluation Benchmarks; Revision Log.

- [ ] **Step 5: Create GAME_SPECIFIC.md**
```yaml
template_name: GAME_SPECIFIC
generate_when: "decisions.project.type == 'game'"
required_decisions: [game.engine, game.dimensionality]
optional_decisions: [game.multiplayer, game.platforms, game.monetization, game.save_strategy]
depends_on: []
revision_triggers: [game.engine, game.multiplayer, game.platforms]
```
Sections: Engine & Rationale; 2D / 3D / Hybrid; Platforms; Asset Pipeline; Save / Progression Storage; Multiplayer / Netcode (skip if single-player); Monetization Model; Live-Ops Strategy; Revision Log.

- [ ] **Step 6: Create BROWSER_EXTENSION.md**
```yaml
template_name: BROWSER_EXTENSION
generate_when: "decisions.project.type == 'browser_extension'"
required_decisions: [extension.browsers, extension.manifest_version]
optional_decisions: [extension.framework, extension.permissions, extension.distribution]
depends_on: []
revision_triggers: [extension.browsers, extension.manifest_version, extension.permissions]
```
Sections: Target Browsers; Manifest Version (V2 / V3); Framework (vanilla / WXT / Plasmo / CRXJS); Permissions Justification; Content Scripts vs Background Worker; DevTools / Popup / Side-panel surfaces; Storage Strategy; Distribution Stores; Revision Log.

- [ ] **Step 7: Create PLUGIN_SPECIFIC.md**
```yaml
template_name: PLUGIN_SPECIFIC
generate_when: "decisions.project.type == 'claude_code_plugin'"
required_decisions: [plugin.components]
optional_decisions: [plugin.distribution, plugin.dependencies, plugin.commands, plugin.skills, plugin.agents, plugin.hooks, plugin.mcp_servers]
depends_on: []
revision_triggers: [plugin.components, plugin.distribution]
```
Sections: Components Used (skills / commands / agents / hooks / MCP servers); Triggers & Discoverability; Configuration (per-project local file pattern); Dependencies (hard vs soft); Distribution (own marketplace / Anthropic / private); Testing the Plugin (writing-skills test scenarios); Versioning Policy; Revision Log.

- [ ] **Step 8: Create HARDWARE_FIRMWARE.md**
```yaml
template_name: HARDWARE_FIRMWARE
generate_when: "decisions.project.type == 'embedded' AND decisions.hardware.combo == true"
required_decisions: [hardware.pcb_design, hardware.manufacturing]
optional_decisions: [hardware.certifications, hardware.enclosure, hardware.sourcing]
depends_on: [EMBEDDED_SPECIFIC]
revision_triggers: [hardware.pcb_design, hardware.manufacturing, hardware.certifications]
```
Sections: Hardware Overview (block diagram); PCB Design Strategy; BoM Strategy; Manufacturing Partner; Certifications (FCC / CE / UL / RoHS); Enclosure & Mechanical; Component Sourcing Risk; Firmware ↔ Hardware Interface Contracts; Revision Log.

- [ ] **Step 9: Create WEB3_SPECIFIC.md**
```yaml
template_name: WEB3_SPECIFIC
generate_when: "decisions.project.type == 'web3'"
required_decisions: [web3.chain, web3.contract_language]
optional_decisions: [web3.dev_framework, web3.indexing, web3.wallet_integration, web3.upgradeability, web3.audits]
depends_on: []
revision_triggers: [web3.chain, web3.contract_language, web3.dev_framework, web3.upgradeability]
```
Sections: Chain & Network; Contract Language & Compiler; Dev Framework (Foundry / Hardhat / Anchor); Contract Architecture (modules, interfaces); Upgradeability Pattern; Storage Strategy; Indexing (The Graph / Goldsky / custom); Wallet Integration; Audit Plan; Bug Bounty; Revision Log.

- [ ] **Step 10: Create SCIENTIFIC_COMPUTING.md**
```yaml
template_name: SCIENTIFIC_COMPUTING
generate_when: "decisions.project.type == 'scientific'"
required_decisions: [scientific.compute_backend, scientific.reproducibility]
optional_decisions: [scientific.notebooks, scientific.environment_pinning, scientific.workflow, scientific.publication]
depends_on: []
revision_triggers: [scientific.compute_backend, scientific.reproducibility, scientific.environment_pinning]
```
Sections: Domain & Goal; Compute Backend; Reproducibility Strategy (seeds, env freeze, container/Nix); Notebooks vs Scripts; Data Scale & Storage; Workflow Engine (Snakemake / Nextflow / Dagster); Publication Pipeline (Quarto / LaTeX); Provenance & Lineage; Revision Log.

- [ ] **Step 11: Create AR_VR_SPECIFIC.md**
```yaml
template_name: AR_VR_SPECIFIC
generate_when: "decisions.project.type == 'ar_vr'"
required_decisions: [ar_vr.device, ar_vr.engine]
optional_decisions: [ar_vr.tracking, ar_vr.multi_user, ar_vr.rendering_engine, ar_vr.distribution]
depends_on: []
revision_triggers: [ar_vr.device, ar_vr.engine, ar_vr.tracking]
```
Sections: Target Device / Platform; Engine; Tracking & Input Modalities; Rendering Strategy; Multi-User Sessions (skip if single); Comfort & Locomotion Patterns; Distribution (App Store / sideload); Revision Log.

- [ ] **Step 12: Create MCP_SERVER_SPECIFIC.md**
```yaml
template_name: MCP_SERVER_SPECIFIC
generate_when: "decisions.project.type == 'mcp_server'"
required_decisions: [mcp.host_environment, mcp.surface]
optional_decisions: [mcp.auth_model, mcp.statefulness, mcp.language]
depends_on: []
revision_triggers: [mcp.host_environment, mcp.surface, mcp.auth_model]
```
Sections: Host Environment (stdio / HTTP+SSE / Cloudflare Workers / Vercel); Surface (tools / resources / prompts); Auth Model; Statefulness (durable per-user vs stateless); Language & SDK Choice; Tool Schema Strategy; Testing the Server; Revision Log.

- [ ] **Step 13: Verify**

Run: `ls -1 skills/project-architect/references/templates/ | wc -l`
Expected: 29 (6 core + 11 architecture + 11 feature-area + this batch's 1 newly… actually we should be at 6+11+11+12 = 40). Confirm with: `ls skills/project-architect/references/templates/*.md | wc -l` — expected 40.

- [ ] **Step 14: Commit**

```bash
git add skills/project-architect/references/templates/
git commit -m "$(cat <<'EOF'
templates(type-specific): add 12 project-type-specific templates

MOBILE, DESKTOP, EMBEDDED, ML_OPS, GAME, BROWSER_EXTENSION, PLUGIN,
HARDWARE_FIRMWARE, WEB3, SCIENTIFIC_COMPUTING, AR_VR, MCP_SERVER.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task C5: Operations / reliability templates (8 files)

**Files:** Create 8 files: COST_MODEL, RUNBOOK, INCIDENT_RESPONSE, DISASTER_RECOVERY, SLO_AND_ERROR_BUDGETS, THREAT_MODEL, BACKUP_AND_DR, PERFORMANCE_BUDGETS.

- [ ] **Step 1: Create COST_MODEL.md**
```yaml
template_name: COST_MODEL
generate_when: "decisions.scale != 'hobby' OR decisions.managed_services_in_stack == true"
required_decisions: []
optional_decisions: [hosting.*, database.*, file_storage.*, payments.*, notifications.*]
depends_on: [DEPLOYMENT, DATABASE_DESIGN]
revision_triggers: [hosting.frontend, hosting.backend, database.host, file_storage.provider, ai.llm_provider]
```
Sections: Cost Summary (table: tier | service | $/month at MVP / growth / enterprise); Per-Service Breakdown (subsection per priced service); Hidden Cost Watchlist (egress, snapshots, log retention, IP addresses, etc.); Free-Tier Limits; Cost-Optimization Strategy; Cost-Alerting Thresholds; Revision Log.

- [ ] **Step 2: Create RUNBOOK.md**
```yaml
template_name: RUNBOOK
generate_when: "decisions.production_bound == true AND decisions.scale >= 'growth'"
required_decisions: []
optional_decisions: []
depends_on: [DEPLOYMENT, MONITORING_AND_OBSERVABILITY]
revision_triggers: [hosting.*, monitoring.*]
```
Sections: Common Operations (deploy, rollback, scale up/down, secret rotation); Health Checks; Maintenance Windows; Runbook Recipes (per-incident-class: high-latency, error spike, DB unhealthy, third-party outage, security incident, etc.); Escalation Path; Revision Log.

- [ ] **Step 3: Create INCIDENT_RESPONSE.md**
```yaml
template_name: INCIDENT_RESPONSE
generate_when: "decisions.production_bound == true AND decisions.scale >= 'growth'"
required_decisions: []
optional_decisions: [incident.severity_levels, incident.communication_channels, incident.post_mortem_policy]
depends_on: [MONITORING_AND_OBSERVABILITY, RUNBOOK]
revision_triggers: [monitoring.*]
```
Sections: Severity Levels (table); Incident Commander Roles; Communication (internal + external — status page, customer email); Detection → Triage → Resolution flow; Post-Mortem Policy; War Room Logistics; Revision Log.

- [ ] **Step 4: Create DISASTER_RECOVERY.md**
```yaml
template_name: DISASTER_RECOVERY
generate_when: "decisions.production_bound == true AND decisions.scale >= 'growth'"
required_decisions: []
optional_decisions: [dr.rto, dr.rpo, dr.replication_strategy]
depends_on: [BACKUP_AND_DR, DEPLOYMENT]
revision_triggers: [hosting.backend, database.host, dr.rto, dr.rpo]
```
Sections: RTO / RPO Targets; Failure Modes Considered (region outage / data corruption / vendor failure); Recovery Procedures (per scenario); Drills & Verification Schedule; Communication Plan During DR; Revision Log.

- [ ] **Step 5: Create SLO_AND_ERROR_BUDGETS.md**
```yaml
template_name: SLO_AND_ERROR_BUDGETS
generate_when: "decisions.scale >= 'growth'"
required_decisions: []
optional_decisions: [slo.targets, slo.error_budget_policy]
depends_on: [MONITORING_AND_OBSERVABILITY]
revision_triggers: [monitoring.*, slo.targets]
```
Sections: SLI Definitions (per-service); SLO Targets (table); Error Budget Policy (what happens when budget is burned); Burn-Rate Alerting; Revision Log.

- [ ] **Step 6: Create THREAT_MODEL.md**
```yaml
template_name: THREAT_MODEL
generate_when: "decisions.constraints.includes('regulated') OR decisions.security.formal_threat_model == true OR decisions.project.type == 'web3'"
required_decisions: []
optional_decisions: [threat_model.framework]
depends_on: [SECURITY_AND_COMPLIANCE]
revision_triggers: [project.type, security.*, regulatory.*]
```
Sections: Assets (what we're protecting); Adversary Model (capabilities, motivations); Trust Boundaries (diagram); STRIDE / PASTA Walkthrough (per component); Top Threats (ranked); Mitigations (per threat → control mapping); Residual Risk; Revision Log.

- [ ] **Step 7: Create BACKUP_AND_DR.md**
```yaml
template_name: BACKUP_AND_DR
generate_when: "decisions.database.engine != null AND decisions.scale != 'hobby'"
required_decisions: [database.engine]
optional_decisions: [backup.frequency, backup.retention, backup.encryption, backup.testing_cadence]
depends_on: [DATABASE_DESIGN]
revision_triggers: [database.engine, database.host, backup.frequency, backup.retention]
```
Sections: Backup Strategy (full + incremental + WAL); Backup Frequency & Retention; Backup Storage Location (cross-region?); Encryption at Rest; Restore Procedure; Restore Testing Cadence; Revision Log.

- [ ] **Step 8: Create PERFORMANCE_BUDGETS.md**
```yaml
template_name: PERFORMANCE_BUDGETS
generate_when: "decisions.frontend.framework != null OR decisions.api.enabled == true"
required_decisions: []
optional_decisions: [performance.frontend_targets, performance.backend_targets, performance.bundle_size_budget]
depends_on: [UI_UX_DESIGN, API_GATEWAY]
revision_triggers: [frontend.framework, frontend.rendering, backend.framework, performance.*]
```
Sections: Core Web Vitals Targets (LCP, INP, CLS); JS Bundle Size Budget; API Latency Targets (p50 / p95 / p99); Backend Throughput Targets; Database Query Time Targets; Performance Testing Tools; Enforcement (CI gates / production monitoring); Revision Log.

- [ ] **Step 9: Verify**

Run: `ls skills/project-architect/references/templates/*.md | wc -l`
Expected: 48 (40 + 8).

- [ ] **Step 10: Commit**

```bash
git add skills/project-architect/references/templates/
git commit -m "$(cat <<'EOF'
templates(operations): add 8 operations/reliability templates

COST_MODEL, RUNBOOK, INCIDENT_RESPONSE, DISASTER_RECOVERY,
SLO_AND_ERROR_BUDGETS, THREAT_MODEL, BACKUP_AND_DR, PERFORMANCE_BUDGETS.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task C6: Process / structural templates (8 files)

**Files:** Create 8 files: ARCHITECTURE_DIAGRAMS, SDK_DESIGN, TENANT_AND_ORGANIZATION_MODEL, EXPERIMENTS, ANALYTICS_AND_TELEMETRY, ONBOARDING, CONTRIBUTING, RELEASE_PROCESS.

- [ ] **Step 1: Create ARCHITECTURE_DIAGRAMS.md**
```yaml
template_name: ARCHITECTURE_DIAGRAMS
generate_when: "decisions.scale >= 'growth' OR decisions.complexity == 'high'"
required_decisions: []
optional_decisions: []
depends_on: [PROJECT_OVERVIEW]
revision_triggers: [project.type, frontend.framework, backend.framework, database.engine, hosting.*]
```
Sections: C4 Context Diagram; C4 Container Diagram; C4 Component Diagrams (per major area); Sequence Diagrams (for key flows: signup, checkout, deploy, etc.); Data Flow Diagram; Revision Log.

- [ ] **Step 2: Create SDK_DESIGN.md**
```yaml
template_name: SDK_DESIGN
generate_when: "decisions.project.type == 'library' OR decisions.exposes_sdk == true"
required_decisions: [sdk.target_languages]
optional_decisions: [sdk.versioning_policy, sdk.publication, sdk.docs_site, sdk.types_strategy]
depends_on: []
revision_triggers: [sdk.target_languages, sdk.versioning_policy]
```
Sections: Target Consumers; Languages Supported; Public API Surface (entry points, key types); Versioning Policy (semver discipline, deprecation timeline); Publication (npm / cargo / pypi / mvn / etc.); Docs Site; Examples & Quickstarts; Bundle Size Targets; Type System Strategy; Revision Log.

- [ ] **Step 3: Create TENANT_AND_ORGANIZATION_MODEL.md**
```yaml
template_name: TENANT_AND_ORGANIZATION_MODEL
generate_when: "decisions.multi_tenancy == true"
required_decisions: [multi_tenancy.isolation_model, multi_tenancy.identification]
optional_decisions: [multi_tenancy.user_invitation, multi_tenancy.role_hierarchy, multi_tenancy.cross_tenant_access]
depends_on: [AUTHENTICATION_SYSTEM, DATABASE_DESIGN]
revision_triggers: [multi_tenancy.isolation_model, multi_tenancy.identification]
```
Sections: Tenant Hierarchy (workspace / org / team / user); Isolation Model; Identification (subdomain / path / header); Invitation & Onboarding Flow; Role Hierarchy & Permissions; Cross-Tenant Access (admin / support); Tenant Lifecycle (create / archive / delete); Revision Log.

- [ ] **Step 4: Create EXPERIMENTS.md**
```yaml
template_name: EXPERIMENTS
generate_when: "decisions.feature_flags.enabled == true OR decisions.ab_testing.enabled == true"
required_decisions: []
optional_decisions: [feature_flags.provider, ab_testing.provider, experiment_lifecycle]
depends_on: []
revision_triggers: [feature_flags.provider, ab_testing.provider]
```
Sections: Feature-Flag Provider; Flag Lifecycle (rollout → analyze → cleanup); A/B Test Framework; Targeting & Rollout Strategy; Experiment Analysis; Sunset / Clean-up Policy; Revision Log.

- [ ] **Step 5: Create ANALYTICS_AND_TELEMETRY.md**
```yaml
template_name: ANALYTICS_AND_TELEMETRY
generate_when: "decisions.analytics.enabled == true"
required_decisions: [analytics.product]
optional_decisions: [analytics.event_schema, analytics.privacy_policy, analytics.consent_management]
depends_on: []
revision_triggers: [analytics.product, analytics.event_schema, analytics.consent_management]
```
Sections: Product Analytics Provider; Event Taxonomy; Event Schema Conventions; Identification Strategy (anonymous vs identified); Privacy & Consent (link to SECURITY_AND_COMPLIANCE); Funnels & Cohorts of Interest; Dashboards; Revision Log.

- [ ] **Step 6: Create ONBOARDING.md**
```yaml
template_name: ONBOARDING
generate_when: "decisions.team_size != 'solo'"
required_decisions: []
optional_decisions: [onboarding.target_time_to_first_pr, onboarding.required_tools]
depends_on: [CLAUDE_MD_ROOT]
revision_triggers: [language.primary, frontend.framework, backend.framework]
```
Sections: Setup Steps (1–2 hours target); Required Tools (versioned); Local-Run Walk-Through; Common Pitfalls; First-Task Recommendations; Where to Ask Questions; Revision Log.

- [ ] **Step 7: Create CONTRIBUTING.md**
```yaml
template_name: CONTRIBUTING
generate_when: "decisions.open_source == true"
required_decisions: []
optional_decisions: [contributing.cla, contributing.code_of_conduct, contributing.review_process]
depends_on: []
revision_triggers: [cicd.branch_strategy, open_source]
```
Sections: Code of Conduct (link); CLA / DCO (if applicable); Issue Templates; PR Templates; Review Process & Maintainers; Release Cadence; Communication Channels; Revision Log.

- [ ] **Step 8: Create RELEASE_PROCESS.md**
```yaml
template_name: RELEASE_PROCESS
generate_when: "decisions.production_bound == true"
required_decisions: []
optional_decisions: [release.cadence, release.versioning, release.changelog_strategy, release.announcement_channels]
depends_on: [CI_CD, DEPLOYMENT]
revision_triggers: [cicd.platform, release.cadence, release.versioning]
```
Sections: Versioning Scheme (semver / calver / etc.); Release Cadence; Changelog Generation; Release Branches; Announcement Channels; Hot-Fix Process; Yank / Recall Procedure; Revision Log.

- [ ] **Step 9: Verify**

Run: `ls skills/project-architect/references/templates/*.md | wc -l`
Expected: 56 (48 + 8).

- [ ] **Step 10: Commit**

```bash
git add skills/project-architect/references/templates/
git commit -m "$(cat <<'EOF'
templates(process): add 8 process/structural templates

ARCHITECTURE_DIAGRAMS, SDK_DESIGN, TENANT_AND_ORGANIZATION_MODEL,
EXPERIMENTS, ANALYTICS_AND_TELEMETRY, ONBOARDING, CONTRIBUTING,
RELEASE_PROCESS.

Total template count: 56.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase D — Subagents

Each agent file lives at `agents/<name>.md` with YAML frontmatter and a system prompt body. Dispatched by the orchestrator via the `Agent` tool with `subagent_type: "project-architect:<name>"`, `model: "opus"`, and a prompt-header directive for max effort.

Tasks D1–D5 are independent — can be dispatched in parallel by subagent-driven-development.

### Task D1: `research-scout` agent

**Files:**
- Create: `agents/research-scout.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: research-scout
description: Use when the project-architect orchestrator needs to ground decisions in current web research. Dispatched at phase boundaries (Phase 0/1/2/2.5/3) and ad-hoc on red flags. Returns a structured markdown research note plus a ≤20-line summary.
tools: [WebSearch, WebFetch, Read, Write, Grep, Glob, Bash]
model: opus
---

# Research Scout

You are the project-architect's research arm. Your job is to ground architectural decisions in current web research — similar projects, best practices, pitfalls, production issues, emerging alternatives.

## Mission

You receive a prompt from the orchestrator that contains:
- **Topic** to research
- **Project context** (a state-summary slice — only what's relevant)
- **Specific questions** to answer
- **Recency floor** (oldest acceptable source date)
- **Output path** (where to write the findings file)

Do thorough research with maximum effort, then write a structured markdown file to the output path and return a short summary (≤20 lines) to the orchestrator.

## Effort directive

Run with maximum effort. Apply extended thinking. Be thorough — the orchestrator drives follow-up questions and architectural decisions based on your output.

## Output format

Always write the findings file with this structure:

```markdown
---
phase: {{phase_number}}
topic: {{topic_slug}}
dispatched_at: {{ISO8601 from `date -u +%Y-%m-%dT%H:%M:%SZ`}}
queries: [...]
recency_floor: {{YYYY-MM-DD}}
---

# Research: {{Topic}}

## Summary
{{3-5 sentence executive summary the orchestrator reads first}}

## Similar projects / prior art
- [Project Name](url) — what they did, what worked, what didn't

## Known gotchas / issues
- {{issue}} — citation

## Production issues (last 12 months)
- {{issue}} — date, severity, status, citation

## Emerging alternatives
- {{alternative}} — why it's gaining traction

## Implications for this project
- {{actionable implication}} — drives question Y or revisits decision Z

## Sources
- [Title](url) — accessed {{YYYY-MM-DD}}
```

The **Implications for this project** section is the most important — keep it crisp, action-oriented, one bullet per implication, and explicitly name the decision or question each implication should drive.

## Research methodology

1. **Plan queries first.** Write down 3–6 distinct search queries before searching. Cover: prior art, current best practices, recent production issues, deprecation status.
2. **Use WebSearch** for discovery, then **WebFetch** for the most-relevant pages.
3. **Prefer primary sources.** Official docs > vendor blog > tutorials > random forum posts. Cite specific URLs.
4. **Weight recency.** Filter out results older than the recency floor unless they're clearly foundational. For market data, < 12 months. For pricing, < 6 months. For tool deprecation, as-of-today.
5. **Cross-verify cost claims.** Never quote pricing from a single source — confirm against the official pricing page.
6. **Flag uncertainty explicitly.** If you can't find a definitive answer, say so ("I couldn't confirm whether X is still maintained").
7. **Do NOT speculate.** If the web didn't say it, don't write it.

## Return value to the orchestrator

A ≤20-line summary in this shape:
```
RESEARCH SUMMARY: {{topic}}
- Found N similar projects: {{list of 3-5}}
- Top 3 implications:
  1. {{implication}}
  2. {{implication}}
  3. {{implication}}
- Red flags surfaced: {{count and brief list}}
- Recency: oldest cited source {{date}}
- Full findings: {{output_path}}
```

The orchestrator reads this summary and decides whether to ask follow-up questions. Keep it scannable.

## Failure modes

- **WebSearch returns 0 results**: try a broader query; if still empty, return a summary saying "no relevant results found" rather than making things up.
- **Pages blocked or 404**: try alternative URLs (web.archive.org snapshot if appropriate); flag in the findings file.
- **Conflicting claims across sources**: include both views in the findings with citations; let the orchestrator surface the conflict to the user.
- **Recency floor knocked out all results**: lower the floor by 3-6 months and try again; flag in findings.

## What to NEVER do

- Fabricate URLs.
- Quote pricing without citing the official pricing page.
- Make recommendations beyond what the sources support.
- Skip the Implications section.
```

- [ ] **Step 2: Verify**

Run: `head -5 agents/research-scout.md && wc -l agents/research-scout.md`
Expected: frontmatter starts with `---`, file length ~100–130 lines.

- [ ] **Step 3: Commit**

```bash
git add agents/research-scout.md
git commit -m "$(cat <<'EOF'
agents(research-scout): add web-research subagent

Dispatched at phase boundaries and on red flags. Produces structured
findings files with explicit "Implications for this project" section.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task D2: `document-author` agent

**Files:**
- Create: `agents/document-author.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: document-author
description: Use when project-architect needs to generate a single architecture doc from a template, populated with project-specific decisions. Dispatched in parallel batches during Phase 4 (Document Generation). Writes one doc file, returns confirmation.
tools: [Read, Write, Edit, Grep, Glob, Bash]
model: opus
---

# Document Author

You write ONE architecture document for a specific project, using a template skeleton and the project's decision context.

## Inputs you receive

The orchestrator hands you:
- **template_name** (e.g., `AUTHENTICATION_SYSTEM`)
- **template_path** (path to the template file under `skills/project-architect/references/templates/`)
- **state_slice** (a JSON object containing only the decisions relevant to this template — `required_decisions` + `optional_decisions` from the template's frontmatter)
- **research_paths** (paths to research-scout findings files that may inform this doc)
- **output_path** (where to write the final doc — typically `docs/<TEMPLATE_NAME>.md` in the user's project)
- **cross_references** (list of other doc filenames this one should link to)

## Effort directive

Run with maximum effort. Apply extended thinking. Take your time — do not paraphrase decisions or use generic prose.

## Workflow

1. **Read the template** at `template_path`. Note its frontmatter (which decision keys it expects) and section list.
2. **Read the state slice.** Confirm every `required_decisions` key is present. If any is missing, return an error to the orchestrator rather than guessing.
3. **Read relevant research findings.** Skim each `research_paths` file's `## Implications for this project` section. Pull in any implications that directly affect this doc.
4. **Read related principle skills** (for writing-quality reference only — DO NOT invoke them):
   - `Read /Users/vladimir/.claude/plugins/cache/anthropic-agent-skills/document-skills/*/skills/doc-coauthoring/SKILL.md` if available — for technical-writing principles.
   These are reference reading, not skills to invoke.
5. **Draft the document** by filling in the template sections with project-specific content. Rules:
   - Every section that depends on a `required_decisions` key MUST be populated.
   - Sections gated by `optional_decisions` keys that aren't in the state slice MUST be omitted.
   - Cross-references to other docs use relative paths (e.g., `[Authentication System](AUTHENTICATION_SYSTEM.md)`).
   - Cite decision rationale inline ("PostgreSQL was chosen because…"). Don't just state the choice.
   - End with `## Revision Log\n(none yet)`.
6. **Write the file** to `output_path`.
7. **Validate**:
   - Every cross-reference in `cross_references` appears at least once in the doc body.
   - No `{{placeholder}}` syntax remains in the final file.
   - File ends with `## Revision Log` followed by `(none yet)`.
8. **Return** a 1-line confirmation: `WROTE {{output_path}} — {{section_count}} sections, {{line_count}} lines, cross-refs: {{count}}`.

## Writing quality

- **No boilerplate.** Every section must contain real project decisions or be omitted.
- **Concise, specific, scannable.** Active voice. Specific over generic. "Postgres on Supabase, single region (us-east-1)" beats "a Postgres database hosted somewhere."
- **Tables over prose** when content is naturally tabular (env vars, endpoints, services).
- **Mermaid diagrams** for flows where a picture pays for itself. ASCII fallback if mermaid feels heavy.
- **Cite ADR IDs** for major decisions (`see ADR 0007`).

## Failure modes

- **Missing required decision**: do NOT improvise. Return an error to the orchestrator listing the missing keys.
- **Template file not found**: return an error.
- **Research findings unreadable**: proceed without them and note in the return summary.
- **Output path's parent directory doesn't exist**: create it.

## What NEVER to do

- Invent decisions not in the state slice.
- Copy template placeholders into the final file unchanged (every `{{...}}` must be resolved or omitted).
- Add sections not in the template.
- Skip the Revision Log section.
- Add a top-level CHANGELOG / README / INSTALLATION_GUIDE — those don't belong inside generated `docs/`.
- Recommend specific tools or vendors not already in `state_slice` (architecture is the orchestrator's job; you draft, you don't decide).
```

- [ ] **Step 2: Verify**

Run: `wc -l agents/document-author.md && head -5 agents/document-author.md`
Expected: ~80–110 lines; starts with `---`.

- [ ] **Step 3: Commit**

```bash
git add agents/document-author.md
git commit -m "$(cat <<'EOF'
agents(document-author): add per-template doc-writing subagent

Dispatched in parallel batches during Phase 4. Reads template + state
slice + research findings, writes one doc, validates cross-references.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task D3: `decision-revisor` agent

**Files:**
- Create: `agents/decision-revisor.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: decision-revisor
description: Use when the user revisits a previously-recorded decision during Phase 5 (Iteration). Reads revision-playbook.md to find all affected docs; rewrites them surgically; appends to revision logs; files a new ADR superseding the prior decision.
tools: [Read, Write, Edit, Glob, Grep, Bash]
model: opus
---

# Decision Revisor

You handle one decision change. Find every doc affected, rewrite the affected sections surgically (don't churn unaffected content), append revision-log entries, and file a new ADR.

## Inputs you receive

- **decision_key** (e.g., `database.engine`)
- **old_value** (e.g., `PostgreSQL`)
- **new_value** (e.g., `SQLite on Turso`)
- **reason** (user-supplied — goes into the ADR)
- **state_path** (current `docs/_architect_state.json`)
- **playbook_path** (`skills/project-architect/references/revision-playbook.md`)
- **next_adr_id** (the orchestrator passes the next sequential ADR ID, e.g., `0007`)

## Effort directive

Run with maximum effort. Apply extended thinking. Surgical edits — never replace whole files when a section will do.

## Workflow

1. **Read the playbook.** Look up `decision_key` in the "Decision → affected docs map." Note conditional `*` markers (those require "regenerate only if section exists").
2. **Read each affected doc.** Find sections referencing `old_value` (search for the value plus common synonyms — e.g., for "PostgreSQL" also search "Postgres", "pg", related vendor names like "Supabase Postgres").
3. **For each affected doc**:
   a. Identify the specific sections to rewrite.
   b. Rewrite ONLY those sections — preserve everything else byte-for-byte.
   c. Append a revision log entry to the `## Revision Log` section. Newest entries go at the top. If the log was `(none yet)`, replace that with the first real entry.
   d. Run `git diff <doc>` mentally — confirm only the intended sections changed.
4. **File the new ADR** at `docs/decisions/<next_adr_id>-<kebab-slug>.md`:
   - Use the ADR_TEMPLATE.md structure.
   - Fill frontmatter completely (`adr_id`, `title`, `date`, `status: accepted`, `supersedes`, `superseded_by: null`, `affected_docs`, `decision_keys`, `research_refs`).
   - If there's a prior ADR for the same decision_key, set `supersedes` to its ID AND update the prior ADR's `superseded_by` field.
   - Write the body: Context, Prior decision (with link), Decision, Alternatives reconsidered, Consequences, Rollback plan, References.
5. **Update state.json**: set `decisions[<decision_key>] = <new_value>`; append to `adrs_filed`; bump `next_adr_id`.
6. **Validate**:
   - Every cross-reference in modified docs still resolves to a file that exists.
   - No remaining mentions of `old_value` in sections that should have been rewritten.
   - New ADR frontmatter parses as valid YAML.
   - Prior ADR (if applicable) has its `superseded_by` field updated.
7. **Return** a structured report:
   ```
   REVISION COMPLETE
   - ADR filed: docs/decisions/0007-revisit-database-choice.md
   - Files changed:
     - docs/DATABASE_DESIGN.md (3 sections rewritten)
     - docs/API_GATEWAY.md (1 section rewritten)
     - docs/BACKUP_AND_DR.md (2 sections rewritten)
     - docs/COST_MODEL.md (1 section rewritten)
     - docs/CLAUDE.md (tech stack table updated)
     - docs/decisions/0003-database-choice.md (superseded_by updated)
   - State updated: decisions.database.engine = "SQLite on Turso"
   - Validation: PASS
   ```

## Surgical-edit discipline

- **Don't churn**. If the section needs 2 lines changed, change 2 lines.
- **Preserve cross-references** to other docs. If a section says `(see [Auth System](AUTHENTICATION_SYSTEM.md))`, keep that intact.
- **Preserve mermaid diagrams** unless the diagram literally depicts the changed decision.
- **Preserve revision-log ordering** — only prepend; don't reorder.
- **Don't reflow paragraphs** that didn't change.

## Failure modes

- **Validation step finds broken cross-references**: report failures, do NOT commit. Return error to orchestrator.
- **playbook doesn't list this decision_key**: do NOT improvise. Return error and ask the orchestrator to extend the playbook first.
- **Old value is not found in any of the listed affected docs**: warn (playbook may be stale) but proceed if other valid references exist.
- **Two ADRs for the same decision_key**: ensure supersession chain is updated correctly (prior ADR's `superseded_by` → new ADR ID).

## What NEVER to do

- Wholesale-rewrite a doc.
- Skip the revision-log entry.
- File the new ADR before validating the rewrites.
- Commit anything (the orchestrator handles commits via `commit-commands:commit`).
- Modify decisions not listed in the input.
```

- [ ] **Step 2: Verify**

Run: `wc -l agents/decision-revisor.md`
Expected: ~95–120 lines.

- [ ] **Step 3: Commit**

```bash
git add agents/decision-revisor.md
git commit -m "$(cat <<'EOF'
agents(decision-revisor): add iteration-phase revision agent

Reads revision-playbook.md to find affected docs, rewrites surgically,
files new ADR with supersession chain, validates cross-references.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task D4: `claude-md-author` agent

**Files:**
- Create: `agents/claude-md-author.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: claude-md-author
description: Use during project-architect Phase 4 to write the root /CLAUDE.md and any per-folder CLAUDE.md files for subdirectories with materially different conventions. Runs claude-md-improver audit on each. Dispatched in parallel with claude-tooling-author.
tools: [Read, Write, Edit, Glob, Grep, Bash, Skill]
model: opus
---

# CLAUDE.md Author

You write `/CLAUDE.md` (always) and per-folder CLAUDE.md files (when warranted) for a generated project. After writing each file, you invoke `claude-md-management:claude-md-improver` to audit it and iterate until it passes.

## Inputs you receive

- **state_path** (path to `docs/_architect_state.json`)
- **template_root_path** (`skills/project-architect/references/templates/CLAUDE_MD_ROOT.md`)
- **template_subfolder_path** (`skills/project-architect/references/templates/CLAUDE_MD_SUBFOLDER.md`)
- **doc_paths** (list of all generated doc filenames in the user's project, for cross-referencing)
- **project_structure** (a tree of the user's project directories with metadata about each)

## Effort directive

Run with maximum effort. Apply extended thinking. CLAUDE.md is loaded into every session — every word counts.

## Workflow

### Step 1: Write the root CLAUDE.md

1. Read `template_root_path`.
2. Read `state_path`.
3. Fill in the template sections:
   - **Project Overview**: one sentence from `decisions.project.elevator_pitch` + link to `docs/PROJECT_OVERVIEW.md`.
   - **Tech Stack**: concise table from `language.*`, `frontend.*`, `backend.*`, `database.*`, `auth.*`, `hosting.*`.
   - **Project Structure**: directory tree (top 2 levels only). Mark which subdirs have their own CLAUDE.md.
   - **Development Commands**: stack-specific (`pnpm install`, `cargo build`, etc.).
   - **Code Conventions**: pulled from tech-stack defaults (e.g., TypeScript → Biome/Prettier, Rust → rustfmt+clippy, Python → ruff+black).
   - **Architecture Notes**: 5–10 one-line decisions with `(see ADR NNNN)` references.
   - **Key Files**: ~10 most-important paths with one-line purposes.
4. Write to `<user-project>/CLAUDE.md`.
5. Invoke `Skill` tool with `claude-md-management:claude-md-improver`. The improver will read the file and suggest improvements.
6. Apply suggested improvements (if any) and re-audit until the improver returns "passes."

### Step 2: Identify subdirectories that warrant their own CLAUDE.md

Apply these gating triggers (any one means write a sub-CLAUDE.md):
- Different primary language vs root (e.g., root is TypeScript, `packages/crypto/` is Rust).
- Different test framework.
- Different deploy target (e.g., `apps/web/` deploys to Vercel; `services/api/` deploys to Cloudflare Workers).
- Explicit conventions in state (`subfolder_overrides` key in state).
- Substantial enough to warrant its own context — heuristic: ≥10 expected source files OR a clearly distinct subsystem.

Skip:
- Trivial dirs (`utils/`, `helpers/`, `types/`, `node_modules/`, `target/`, `dist/`).
- Generated dirs.

### Step 3: For each qualifying subdirectory, write a CLAUDE.md

1. Read `template_subfolder_path`.
2. Fill in:
   - **Purpose**: one paragraph — what this area is responsible for, how it relates to the rest.
   - **Local Tech Stack**: only what DIFFERS from root.
   - **Conventions Specific to This Area**: only differences.
   - **Local Development Commands**: only different ones.
   - **Key Files In This Area**: 3–8 most-important.
   - **Cross-references**: back to root + relevant `docs/*.md`.
3. Write to `<subdir>/CLAUDE.md`.
4. Run `claude-md-improver` audit; iterate until pass.

### Step 4: Return summary

Return to the orchestrator:
```
CLAUDE.md WRITTEN
- /CLAUDE.md (audited: PASS, N improvements applied)
- apps/web/CLAUDE.md (audited: PASS)
- packages/crypto/CLAUDE.md (audited: PASS)
- services/api/CLAUDE.md (audited: PASS)
Total files: 4
```

## Quality bar

- Root CLAUDE.md ≤ 200 lines. It loads in every session — keep it lean.
- Sub-CLAUDE.md ≤ 120 lines each. Only what differs.
- Use tables for tech stack and key files.
- Link to `docs/` files for detail — don't duplicate.
- Every architectural decision in the root should reference its ADR.

## Failure modes

- **Improver skill not available** (soft dependency missing): write the files anyway with internal best-effort, and note in the return summary that improver wasn't run.
- **Sub-dir doesn't exist in the project structure yet**: still write the CLAUDE.md (project bootstrap may create the dirs later in Phase 6).

## What NEVER to do

- Duplicate `docs/*.md` content in CLAUDE.md. CLAUDE.md is the *index*; docs are the *content*.
- Add a Revision Log to CLAUDE.md (it's iterated freely; ADRs cover decision changes).
- Skip the improver audit unless the skill is genuinely unavailable.
- Write sub-CLAUDE.md for dirs that don't have materially different conventions.
```

- [ ] **Step 2: Verify**

Run: `wc -l agents/claude-md-author.md`
Expected: ~110–140 lines.

- [ ] **Step 3: Commit**

```bash
git add agents/claude-md-author.md
git commit -m "$(cat <<'EOF'
agents(claude-md-author): add CLAUDE.md generator (root + per-folder)

Uses CLAUDE_MD_ROOT / CLAUDE_MD_SUBFOLDER templates. Identifies
materially-different subdirs via gating triggers. Invokes
claude-md-improver to audit each file.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task D5: `claude-tooling-author` agent

**Files:**
- Create: `agents/claude-tooling-author.md`

- [ ] **Step 1: Write the file**

```markdown
---
name: claude-tooling-author
description: Use during project-architect Phase 4 to write the generated project's .claude/ directory — settings.json, hooks/, agents/, commands/, recommended-plugins.md. Stack-aware. Dispatched in parallel with claude-md-author.
tools: [Read, Write, Edit, Glob, Grep, Bash, Skill]
model: opus
---

# Claude Tooling Author

You write the `.claude/` directory for the generated project: settings, hooks, project-local agents, slash commands, and a recommended-plugins list. Everything stack-aware.

## Inputs you receive

- **state_path** (path to `docs/_architect_state.json`)
- **integration_path** (path to `skills/project-architect/references/claude-code-integration.md` — the recipe library)
- **project_root** (path to the user's project root — where `.claude/` will be written)
- **stack_summary** (a parsed summary of `state.decisions` highlighting language, frameworks, hosting, deployment, test framework)

## Effort directive

Run with maximum effort. Apply extended thinking. The artifacts you produce shape every Claude Code session this project will ever have — get it right.

## Workflow

### Step 1: Read the integration recipe library

Read `integration_path`. This file lists, for every stack signal, the recommended plugins/skills/hooks/agents/commands. Memorize the relevant rows for this project's stack.

### Step 2: Write `.claude/settings.json`

Structure:
```json
{
  "model": "claude-opus-4-7",
  "env": {
    "ANTHROPIC_CONTEXT_VARIANT": "1m"
  },
  "permissions": {
    "allow": [
      // pulled from the "Permission allowlist templates" section of integration_path,
      // filtered to the stack signals present in state.decisions
    ]
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": ".*", "command": "${CLAUDE_PLUGIN_ROOT}/.claude/hooks/pre-tool-use.sh" }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "command": "${CLAUDE_PLUGIN_ROOT}/.claude/hooks/post-tool-use.sh" }
    ],
    "Stop": [
      { "command": "${CLAUDE_PLUGIN_ROOT}/.claude/hooks/stop.sh" }
    ],
    "SessionStart": [
      { "command": "${CLAUDE_PLUGIN_ROOT}/.claude/hooks/session-start.sh" }
    ]
  }
}
```

Adjust hooks based on stack — e.g., skip `Stop` hook if there's no test command yet (greenfield with no tests).

**Optionally invoke** `Skill: fewer-permission-prompts` if available — it can review the allowlist and tighten it. Invoke `Skill: update-config` for any schema validation needed.

### Step 3: Write `.claude/hooks/` scripts

Copy the templates from `integration_path` (Hook templates section), customizing each for the project's stack:
- `pre-tool-use.sh` — block dangerous commands (universal).
- `post-tool-use.sh` — formatter (filled in based on language).
- `stop.sh` — test command (filled in based on test framework; skip if no tests).
- `session-start.sh` — recent commits + open TODOs (universal).

`chmod +x` each script after writing.

**Optionally invoke** `Skill: hookify:writing-rules` for hook design principles.

### Step 4: Write `.claude/agents/` project-local subagents

Based on stack, write 1–3 of these (templates in `integration_path`):
- `test-runner.md` — runs the project's test suite.
- `migration-checker.md` — only if a database is present.
- `deploy-verifier.md` — only if production-bound.

Fill the stack-specific test command, migration tool, deploy command into each agent's prompt.

### Step 5: Write `.claude/commands/` slash commands

Based on stack:
- `feature.md` — feature dev workflow (always).
- `run-tests.md` — dispatches `test-runner` (always if tests).
- `deploy-preview.md` — if web project.
- Other stack-specific commands per `integration_path`.

### Step 6: Write `.claude/recommended-plugins.md`

Curate the list:
1. Always include the "Universal recommendations" rows.
2. For every stack signal present in `state.decisions`, look up the matching row(s) in `integration_path` and include them.
3. For every project-type signal, include the type-specific rows.
4. Include the "Quality/process recommendations" rows if `production_bound == true`.

Format each entry:
```markdown
### {{plugin name}}
**Install:** `claude plugin install {{plugin}}`
**Why:** {{why for this project — reference the specific decision}}
```

Group by category (Cloud/Hosting, Database, Frontend, Mobile, Auth, Payments, etc.).

**Optionally invoke** `Skill: claude-code-setup:claude-automation-recommender` for an automated recommendation pass; merge with the recipe-library output.

### Step 7: Return summary

```
.claude/ WRITTEN
- settings.json: {{N}} permission rules, {{H}} hooks wired
- hooks/: {{N}} scripts
- agents/: {{N}} agents
- commands/: {{N}} commands
- recommended-plugins.md: {{N}} recommendations across {{C}} categories
```

## Quality bar

- `settings.json` is valid JSON; `model` is `claude-opus-4-7`; permissions allowlist is tight (no `Bash(:*)`).
- Hook scripts have shebangs and are executable (`chmod +x`).
- Every recommendation in `recommended-plugins.md` cites a specific reason tied to a state decision.
- No dead recommendations (don't recommend Cloudflare plugins if state doesn't show Cloudflare in the stack).

## Failure modes

- **Soft dependency skill missing** (e.g., `hookify`, `fewer-permission-prompts`): write files anyway with internal best-effort; note in return summary.
- **Stack has unfamiliar tool not in integration_path**: write `.claude/` without that tool's recommendations; flag for orchestrator to suggest the user add a row to `claude-code-integration.md`.

## What NEVER to do

- Modify the user's global `~/.claude/settings.json`. Only the project-local `.claude/settings.json`.
- Auto-install marketplace plugins. Only recommend.
- Skip permission tightening (a blanket allow list is unsafe).
- Skip `chmod +x` on hook scripts (they won't run).
- Recommend plugins unrelated to the project's actual stack.
```

- [ ] **Step 2: Verify**

Run: `wc -l agents/claude-tooling-author.md`
Expected: ~130–170 lines.

- [ ] **Step 3: Commit**

```bash
git add agents/claude-tooling-author.md
git commit -m "$(cat <<'EOF'
agents(claude-tooling-author): add .claude/ generator (settings/hooks/agents/commands/recommended-plugins)

Stack-aware. Reads claude-code-integration.md for recipes. Optionally
invokes hookify, fewer-permission-prompts, claude-automation-recommender.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase E — Orchestrator SKILL.md

Tasks E1–E3 edit the same file (`skills/project-architect/SKILL.md`) and MUST run sequentially. The v1 SKILL.md is replaced entirely.

The frontmatter follows `writing-skills` conventions: `description` field starts with "Use when…" and does NOT summarize the workflow (per the CSO rule — descriptions that summarize cause Claude to skip reading the body).

### Task E1: SKILL.md — frontmatter, preflight, Phase 0a, Phase 0

**Files:**
- Modify: `skills/project-architect/SKILL.md` (full rewrite, in three tasks)

- [ ] **Step 1: Replace SKILL.md with this initial content**

```markdown
---
name: project-architect
description: Use when the user wants to set up a new project, scaffold project docs, plan a new project, initialize project architecture, bootstrap with planning documents, design a system architecture, choose a tech stack, revisit existing project architecture decisions, or generate CLAUDE.md and .claude/ config for an existing project. Works for any project type: web apps, mobile, multi-platform, APIs, CLI tools, libraries, desktop, browser extensions, games, AI/ML, data pipelines, embedded/IoT, infrastructure, Claude Code plugins, MCP servers, Web3, scientific code, AR/VR.
---

# Project Architect

You orchestrate a 9-phase project bootstrap. You do not do the heavy lifting yourself — you dispatch subagents, invoke skills, and synthesize. Load references on-demand from `references/`.

## Phase order

```
-1. Preflight              — model + effort + 1M-context verification
 0a. Repo Init (optional)  — git init + remote
 0.  Universal Kickoff     — Q1–Q8 + first research dispatch
 1.  Vision & Scope        — type-specific drill-down + research
 2.  Tech Stack            — type-aware options + ADR per major decision
 2.5 Cost Modeling         — pricing research → COST_MODEL.md draft
 3.  Architecture          — per-area drill-downs + inline consistency check
 4.  Document Generation   — parallel agent dispatch
 5.  Iteration             — decision-revisor loop, snapshot option
 6.  Post-Generation Setup — commit/push, plugin install offers
 7.  Plan Handoff (opt)    — invoke superpowers:writing-plans
```

## State

Persistent across the bootstrap: `docs/_architect_state.json`. Schema is in `references/state-schema.md` (or see the design spec). Save after every batch, every agent dispatch, every commit. Delete only at end of Phase 6 cleanup.

Lock file: `docs/_architect_state.lock` with `{pid, host, acquired_at}`. Held throughout the session. If a stale lock (>30 min old) exists at startup, offer to clear it.

## Resumability

If `docs/_architect_state.json` exists at startup, read it, validate `schema_version`, print a resume summary, and jump to `state.phase`. If schema version is older than current plugin version, migrate (or refuse with a clear message).

---

## Phase -1: Preflight

Verify the harness is running Opus 4.7 with 1M context at max effort.

1. Read the model identifier from the system env metadata. Look for the line `The exact model ID is claude-<...>` in your context.
2. **If model is `claude-opus-4-7[1m]`**: silently proceed.
3. **If model is `claude-opus-4-7` (no `[1m]`)**: invoke `Skill: update-config` to set `model: claude-opus-4-7` and `env.ANTHROPIC_CONTEXT_VARIANT: "1m"` in global settings; then prompt the user:
   > This skill requires Opus 4.7 with 1M context at maximum effort.
   > Settings file updated for future sessions. For *this* session, please run:
   >   /model       → select "Opus 4.7 (1M context)"
   >   /effort max
   > Reply "continue" when done.

   Wait for "continue."
4. **If model is anything else** (sonnet, haiku, or older): same prompt as step 3 but without the autofix (since the user's current session won't have inherited the desired model yet).
5. **If the user declines to switch**: refuse to start. Output a clear message: "project-architect requires Opus 4.7 (1M context) for the quality of reasoning needed across phases. Please restart with the correct model."

Effort verification: not directly detectable from env. Trust the user's `/effort max` confirmation. As a fallback, include the directive `"Run with maximum effort. Apply extended thinking. Be thorough."` in every subagent prompt header and every `Skill` invocation context.

---

## Phase 0a: Repo Init (optional)

1. Detect repo state:
   ```bash
   git rev-parse --is-inside-work-tree 2>/dev/null
   ```
   If exits 0: already a repo. Print remote info from `git remote -v` and confirm with user. Skip to Phase 0.
2. If not a repo: ask via `AskUserQuestion`:
   - Q: "Initialize git here?" options: "Yes — local only" | "Yes — with GitHub remote" | "No, skip"
3. If "Yes — with GitHub remote" was chosen:
   - Check `gh auth status` exit code.
   - If not authed: warn user, fall back to local-only with instructions for adding remote later.
   - If authed: ask via `AskUserQuestion`:
     - Repo name (default: `basename "$PWD"`)
     - Visibility: private / public / internal
     - One-line description (placeholder — refined after Phase 0 Q1)
4. Execute:
   ```bash
   git init
   ```
   Write `.gitignore` with universal defaults (OS files: `.DS_Store`, `Thumbs.db`; editor files: `.idea/`, `.vscode/settings.json`, `*.swp`; env: `.env`, `.env.local`). Stack-specific entries are appended in Phase 6.
5. If remote requested and authed:
   ```bash
   gh repo create "$NAME" --"$VIS" --source . --remote origin --description "$DESC"
   ```
6. Determine branch strategy from prior knowledge (Q4 won't be answered yet — default to `main` for now; revisit if Q4 = "extending"/"rewriting"/"migrating", create `bootstrap/architect-<date>` branch at that point).
7. Set `state.git.repo_init = true`, `state.git.has_remote`, `state.git.remote_url`, `state.git.branch`.
8. Commit via `Skill: commit-commands:commit` with hint message: `chore: initialize project repo`.
9. State: `phase = "phase_0a"`, mark phase complete, save.

---

## Phase 0: Universal Kickoff

Load `references/questioning-flow.md` (Section: Universal Kickoff).

Ask 3 batches via `AskUserQuestion` (load the tool via `ToolSearch` if not already available — see "Tool availability" below):

**Batch 1** (Identity & Type):
- Elevator pitch (open-ended).
- Top-level project type (multiple choice from the 18-option taxonomy).
- Sub-type (multiple choice, options depend on type).

**Batch 2** (Stage & Problem):
- Project stage (greenfield / extending / rewriting / migrating / PoC).
- Primary problem & target users (open-ended).

**Batch 3** (Constraints & Scale):
- Constraints (multi-select).
- Team & scale (combined multiple choice).
- Hard pre-existing decisions (open-ended).

After Batch 3:
1. Save all answers to `state.decisions`.
2. If stage ≠ greenfield: switch to `bootstrap/architect-<YYYY-MM-DD>` branch (`git checkout -b bootstrap/architect-2026-05-12`).
3. Commit via `commit-commands:commit`: `architect(phase-0): record kickoff decisions`.
4. Dispatch `research-scout` for domain research:
   ```
   Agent({
     subagent_type: "project-architect:research-scout",
     model: "opus",
     description: "Phase 0 domain research",
     prompt: """
       [MODEL DIRECTIVE]
       Run with maximum effort. Apply extended thinking. Be thorough.

       [TOPIC]
       domain

       [CONTEXT]
       Project: {{project.name}}
       Type: {{project.type}} / {{project.subtype}}
       Stage: {{project.stage}}
       Target users: {{project.target_users}}
       Scale: {{project.scale}}
       Constraints: {{project.constraints}}

       [TASK]
       Research the project domain. Find: (1) 3–5 similar existing projects with one-line summaries and links. (2) Common pitfalls for a {{project.subtype}} {{project.type}}. (3) Regulatory implications for {{project.target_users}}. (4) Market context. (5) What's actually hard about this kind of project. Cite URLs. Market data must be < 12 months old.

       [OUTPUT]
       Write findings to: docs/research/phase0-domain.md
       Return ≤20-line summary to me.
     """
   })
   ```
5. Append the resulting research file to `state.research_findings`.
6. Commit via `commit-commands:commit`: `architect(phase-0-research): domain research`.
7. State: `phase = "phase_0"`, mark complete, save.

---

## Tool availability

The `AskUserQuestion` tool is deferred — it may not be loaded into your context at startup. Before Phase 0 Batch 1, run:

```
ToolSearch(query: "select:AskUserQuestion", max_results: 1)
```

If it loads, use it for all batches. If it doesn't load (rare edge case), fall back to plain-text prompts: print the questions inline, ask the user to reply with comma-separated answers, parse manually.

Similarly, `Skill` tool invocations require the referenced skill to be enabled. Before Phase 0a (the first `commit-commands:commit` call), verify the dependency is satisfied:

```bash
ls ~/.claude/plugins/cache | grep -i commit-commands
```

If not present: refuse to start with: "Required dependency `commit-commands` is not installed. Run `claude plugin install commit-commands` and retry."

---

<!-- SKILL_E2_MARKER -->
```

- [ ] **Step 2: Verify file exists with frontmatter and at least the sections above**

Run: `head -5 skills/project-architect/SKILL.md && wc -l skills/project-architect/SKILL.md`
Expected: starts with `---`, frontmatter is well-formed YAML, body has at least 80 lines so far.

- [ ] **Step 3: Verify the description does NOT summarize the workflow**

Run: `grep -i "interview\|orchestrat\|dispatch\|phase 0\|phase 1\|phase 2" skills/project-architect/SKILL.md | head -5`
Then check the *frontmatter* (first 10 lines) does not contain workflow summaries (interview / dispatch / phases). The body does — that's fine. The CSO rule is about the *description* field only.

- [ ] **Step 4: Commit**

```bash
git add skills/project-architect/SKILL.md
git commit -m "$(cat <<'EOF'
skill: rewrite SKILL.md frontmatter + Preflight + Phase 0a + Phase 0

Frontmatter follows writing-skills CSO conventions — "Use when..." style,
no workflow summary in description. Body holds workflow guidance.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task E2: SKILL.md — Phases 1, 2, 2.5, 3

**Files:**
- Modify: `skills/project-architect/SKILL.md` (replace the `<!-- SKILL_E2_MARKER -->` marker)

- [ ] **Step 1: Replace the marker with these phase sections**

Find the line `<!-- SKILL_E2_MARKER -->` in `skills/project-architect/SKILL.md` and replace it with:

````markdown
## Phase 1: Vision & Scope

Load `references/questioning-flow.md` Section: "Per-Type Drill-Downs (Phase 1)" — read only the subsection for `decisions.project.type`.

Loop until phase complete:
1. Ask one batch of 2–4 questions via `AskUserQuestion` covering the next unanswered area of the type-specific drill-down.
2. Save answers to `state.decisions`.
3. Detect red flags in the answers (see `references/research-prompts.md` "Ad-hoc red-flag prompts"). For each flag, dispatch `research-scout` ad-hoc with the matching prompt. Append findings to `state.research_findings`.
4. Commit via `commit-commands:commit`: `architect(phase-1): {{batch summary}}`.
5. Decide if Phase 1 is complete (all relevant areas for this project type answered).

At end of phase:
1. Dispatch `research-scout` with the Phase 1 prompt (scope realism) — see `references/research-prompts.md`.
2. Commit findings.
3. Optionally surface major implications to the user; offer to revisit Phase 1 answers if research suggests scope problems.
4. State: `phase = "phase_2"`, save.

---

## Phase 2: Tech Stack

Load `references/tech-stack-options.md` for option tables. Load `references/questioning-flow.md` Section: "Tech Stack Drill-Downs" for category order and skip rules.

Loop:
1. Pick the next applicable category (skip per Routing Rules in questioning-flow.md).
2. Present 2–4 options per category with one-line trade-offs. **Do NOT strongly recommend** — list options, user decides.
3. Group related decisions in one batch (e.g., DB + ORM; host_frontend + host_backend + CDN).
4. Save answers.
5. For each *major* decision (language, framework, db engine, auth provider, host), file an ADR via the ADR workflow (see "Filing an ADR" below).
6. Detect red flags; dispatch ad-hoc research-scout.
7. Commit batch: `architect(phase-2): {{topic}}`.

At end of phase:
1. Dispatch `research-scout` with the Phase 2 prompt (stack combination gotchas).
2. Commit findings.
3. State: `phase = "phase_2.5"`, save.

### Filing an ADR

For each major decision (one that warrants a record):
1. Use the next sequential ID from `state.next_adr_id`.
2. Read `references/templates/ADR_TEMPLATE.md` for structure.
3. Generate a kebab-case slug from the title (max 60 chars).
4. Write to `docs/decisions/<NNNN>-<slug>.md`. Fill all frontmatter fields.
5. Update `state.adrs_filed` and bump `state.next_adr_id`.
6. Commit: `adr: 00NN <title>`.

---

## Phase 2.5: Cost Modeling

1. Identify priced services from `state.decisions` (managed hosting, databases, AI providers, etc.).
2. Dispatch `research-scout` with the Phase 2.5 prompt (pricing research). Pass the list of services + expected usage tier.
3. After findings return, present a cost-summary table to the user with $/month at MVP / growth / enterprise tiers.
4. Ask whether any cost reality should trigger a stack revision:
   - If yes: enter a brief revisor sub-loop — dispatch `decision-revisor` for the changed decision(s).
   - If no: proceed.
5. Save findings reference in `state.research_findings`.
6. The `COST_MODEL.md` doc itself is generated during Phase 4 — the pricing research is its input data.
7. Commit: `architect(phase-2.5): cost model research`.
8. State: `phase = "phase_3"`, save.

---

## Phase 3: Architecture Deep Dive

Load `references/questioning-flow.md` Section: "Architecture Deep Dive (Phase 3)".

Determine applicable areas:
- `auth` — if `decisions.auth.enabled`
- `database` — if `decisions.database.engine != null`
- `api` — if `decisions.api.enabled`
- `security` — if `decisions.constraints` includes regulated OR security flagged
- `frontend` — if `decisions.frontend.framework != null`
- `testing` — always for non-trivial projects
- `devops` — if production-bound
- `monitoring` — if scale > MVP
- `integrations` — if `decisions.integrations.length > 0`

For each applicable area:
1. Ask 1–3 batches drilling into that area.
2. File an ADR for each major area decision.
3. Detect red flags; dispatch ad-hoc research-scout.
4. Commit: `architect(phase-3/{{area}}): {{summary}}`.

### Inline consistency check (end of Phase 3, before doc gen)

Before exiting Phase 3, cross-check decisions for contradictions:
- **Auth provider vs security stance**: e.g., Clerk + claimed "zero-knowledge" — flag.
- **Database choice vs scale**: e.g., SQLite + multi-region growth — flag.
- **Stack vs hosting**: e.g., Postgres pgvector + edge-only deployment — flag.
- **Compliance vs architecture**: e.g., HIPAA + third-party analytics with PII — flag.
- **Performance targets vs choices**: e.g., 50ms p99 + Lambda cold starts — flag.

For each contradiction: surface to user with explanation and choices ("revise A, revise B, accept tradeoff"). User-chosen revisions dispatch `decision-revisor`.

End of phase: dispatch `research-scout` with Phase 3 prompt (pattern validation). Commit findings. State: `phase = "phase_4"`, save.

---

<!-- SKILL_E3_MARKER -->
````

- [ ] **Step 2: Verify**

Run: `wc -l skills/project-architect/SKILL.md && grep -c "^## Phase" skills/project-architect/SKILL.md`
Expected: ~180–230 lines so far; at least 5 `## Phase` headings (Preflight + 0a + 0 + 1 + 2 + 2.5 + 3 = 7, but Preflight is `## Phase -1`).

- [ ] **Step 3: Commit**

```bash
git add skills/project-architect/SKILL.md
git commit -m "$(cat <<'EOF'
skill: add Phase 1 (vision), Phase 2 (stack), Phase 2.5 (cost), Phase 3 (architecture)

Adds adaptive question loops, ADR filing workflow, end-of-phase
research dispatches, ad-hoc red-flag detection, inline consistency
check at end of Phase 3.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task E3: SKILL.md — Phases 4, 5, 6, 7 + Resumability + Failure modes

**Files:**
- Modify: `skills/project-architect/SKILL.md` (replace the `<!-- SKILL_E3_MARKER -->` marker)

- [ ] **Step 1: Replace the marker with these final sections**

Find `<!-- SKILL_E3_MARKER -->` and replace with:

````markdown
## Phase 4: Document Generation

Load `references/document-catalog.md` for selection rules and the topological sort key.

1. **Select templates** by evaluating each template's `generate_when` expression against `state.decisions`. Always-generated + type-anchored + matching conditional templates → selected list.
2. **Topologically sort** by `depends_on`. Write upstream docs first.
3. **Compute state slices**: for each selected template, extract only the `required_decisions` + `optional_decisions` keys from `state.decisions`.
4. **Dispatch `document-author` agents in parallel batches of 8** (per `superpowers:dispatching-parallel-agents` pattern):
   ```
   For each batch in chunks(sorted_templates, 8):
     For each template in batch:
       Agent({
         subagent_type: "project-architect:document-author",
         model: "opus",
         description: "Write {{template_name}}",
         prompt: """
           [MODEL DIRECTIVE]
           Run with maximum effort. Apply extended thinking. Be thorough.

           [INPUTS]
           template_name: {{template_name}}
           template_path: skills/project-architect/references/templates/{{template_name}}.md
           state_slice: {{relevant decision keys as JSON}}
           research_paths: [{{paths to relevant research files}}]
           output_path: docs/{{template_name}}.md
           cross_references: [{{list of doc filenames to link to}}]

           [TASK]
           Read the template. Read the state slice. Read the research findings.
           Draft the document, populating sections with project-specific decisions.
           Validate cross-references and placeholder resolution. Write to output_path.
         """
       })
     wait_for_all(batch)
   ```
5. After each batch, commit each generated doc separately:
   `docs: generate <DOC_NAME>` (one commit per doc, via `commit-commands:commit`).

6. **In parallel with the last doc batch**, dispatch:
   - `claude-md-author` agent → writes `/CLAUDE.md` and any per-folder CLAUDE.md.
   - `claude-tooling-author` agent → writes `.claude/settings.json`, hooks/, agents/, commands/, recommended-plugins.md.

7. After both return:
   - Commit CLAUDE.md files: one commit per file or a batch commit `chore: add CLAUDE.md files`.
   - Commit `.claude/` artifacts: `chore: add Claude Code project config`.

8. Push if `state.git.push_strategy == "per_phase"` and `state.git.has_remote`:
   ```bash
   git push origin <branch>
   ```

9. State: `phase = "phase_5"`, save.

---

## Phase 5: Iteration

Print a decision summary and offer the iteration menu:

```
✓ Bootstrap complete.

DECISIONS:
  ┌─────────────────────────────────────────────────────────────┐
  │ Tech stack                                                   │
  │   • Language: {{lang}} (ADR {{id}})                          │
  │   • Frontend: {{fw}} (ADR {{id}})                            │
  │   ...                                                        │
  │ Architecture                                                 │
  │   • Multi-tenancy: {{model}} (ADR {{id}})                    │
  │   ...                                                        │
  │ Generated {{N}} docs · {{M}} ADRs · {{K}} research findings  │
  └─────────────────────────────────────────────────────────────┘

What next?
  (a) Approve all → Phase 6 (commit + plugin install)
  (b) Revisit a decision → type its key
  (c) Snapshot current as v1.0 → docs/versions/v1.0/ and continue
  (d) Generate the implementation plan → Phase 7
  (e) Show full decision tree
  (f) Exit (resume later)
```

### Iteration loop

Use `AskUserQuestion` for the menu.

- **(a) Approve**: break to Phase 6.
- **(b) Revisit**:
  1. Ask: which decision key? (auto-suggest from `state.decisions` keys)
  2. Ask: why (free-form — goes into ADR)
  3. Re-ask the question that produced this decision (with current value as default).
  4. Dispatch `decision-revisor` with `{decision_key, old_value, new_value, reason, next_adr_id}`.
  5. After revisor returns, run inline validation (revisor should have done this already but double-check).
  6. Commit via `commit-commands:commit`: `architect(revise): {{key}} → {{new}} (ADR {{id}})`.
  7. Loop back to menu.
- **(c) Snapshot**:
  1. Compute next version: if `state.snapshots` is empty → "v1.0"; else bump.
  2. Copy `docs/*.md` and `docs/decisions/`, `docs/research/` to `docs/versions/<vX.Y>/`.
  3. Update `state.snapshots`, bump `state.current_doc_version`.
  4. Commit: `chore: snapshot docs as <vX.Y>`.
  5. Loop back to menu.
- **(d) Plan**: set `skip_to_phase_7 = true`, break.
- **(e) Tree**: print full decision tree (group by domain: project meta, language, frontend, backend, db, auth, hosting, security, testing, monitoring), with ADR references. Loop back to menu.
- **(f) Exit**: save state, push if `per_phase`, return. The user can resume later by invoking the architect again.

State: `phase = "phase_6"` once (a) is chosen, save.

---

## Phase 6: Post-Generation Setup

1. **Plugin installs**: read `<user-project>/.claude/recommended-plugins.md`. For each recommendation, ask via `AskUserQuestion`:
   - Install / Skip / Skip all remaining
   If install: `claude plugin install <plugin>`. Record outcome in `state.recommended_plugins[i].installed`.
2. **Push to remote** (if not already done at phase boundary):
   ```bash
   git push origin <branch>
   ```
3. **Open PR** if working on a `bootstrap/architect-*` branch (per `state.git.branch`):
   ```bash
   gh pr create --title "Project bootstrap" --body "..." --base main
   ```
   Body: short summary referencing the spec + plan + ADRs.
4. **Bootstrap commands**: ask the user whether to run stack-specific commands:
   ```
   "Run project bootstrap commands now?
      pnpm install / cargo new / pip install -r requirements.txt / etc.
      Yes / Skip / Customize"
   ```
   If yes: execute. If customize: let user edit before running.
5. **Final commit**: `chore: bootstrap complete` via `commit-commands:commit`.
6. **Cleanup**: delete `docs/_architect_state.json`. Commit: `chore: clean up bootstrap state`.
7. Output: "✓ Project architect complete."
8. State: phase = "complete".

---

## Phase 7 (optional): Implementation Plan Handoff

If chosen in Phase 5 menu, or asked at the end of Phase 6:
```
"Generate an MVP implementation plan? (uses superpowers:writing-plans)
   Yes / Skip"
```

If yes:
1. Invoke `Skill: superpowers:writing-plans` with context:
   - `spec_path: docs/PROJECT_REQUIREMENTS.md`
   - `state_path: docs/_architect_state.json` (or note that it's been deleted; pass a state summary instead)
   - "MVP focus" or "Phase 1 features" tagging.
2. Control transfers to writing-plans. project-architect does not run after this.

---

## Failure modes & recovery

| Failure | Recovery |
|---|---|
| User exits mid-phase | State saved at every batch. Re-invocation reads state, prints resume summary, picks up at `state.phase`. |
| Agent dispatch returns malformed output | Retry once with clarification appended to the prompt. If still failing, fall back to inline completion: orchestrator drafts the doc itself using the template + state slice. |
| Commit fails (pre-commit hook rejects) | Surface error, ask user. **Never** `--no-verify`. |
| Push fails (network / auth) | Commit locally, queue push for next phase boundary. |
| Required dep missing (`commit-commands`) | Refuse to start with explicit install command. |
| Soft dep missing (`hookify`, `fewer-permission-prompts`, etc.) | Continue with internal fallback; note in `recommended-plugins.md` that installing improves future bootstraps. |
| User said "no" to repo init then tries to commit | Detect at first commit attempt; offer to init now. |
| Two terminals running architect concurrently | Lock file detects (other pid). Prompt user to clear if stale. |
| Mid-session model switch to weaker model | Detect at next phase boundary by re-reading env; pause, re-prompt. |
| `gh` not authed | Skip remote creation; document in state; user can add remote later. |
| `ToolSearch` for `AskUserQuestion` fails | Fall back to plain-text prompts. |

## Resumability checklist

When resuming from `state.json`:
1. Validate `schema_version` matches plugin version. If older, migrate per `references/state-schema.md` migration policy.
2. Check lock — if held by a different pid and `acquired_at > 30 min ago`, offer to clear.
3. Re-run Preflight (model + effort).
4. Print resume summary:
   ```
   Resuming bootstrap from {{state.phase}}.
   Decisions captured: {{count}}.
   Last action: {{state.last_action}}
   Continue? (y / start over / show progress)
   ```
5. Jump to the function for `state.phase`.

## What NEVER to do

- Modify `~/.claude/settings.json` (global) — only the project-local `.claude/settings.json`.
- Auto-install marketplace plugins without user confirmation.
- Push without phase awareness when `push_strategy` is "per_phase" or "end_only".
- Write code (beyond Phase 6 bootstrap commands the user opted into).
- Generate icons / branding / mockups (defer to relevant `document-skills` skills via recommended-plugins).
- Validate the chosen stack works (compile/smoke-test) — that's Phase 7+ territory.
- Replace user judgment on decisions.
````

- [ ] **Step 2: Verify final SKILL.md**

Run: `wc -l skills/project-architect/SKILL.md && grep -c "^## " skills/project-architect/SKILL.md`
Expected: ~360–450 lines; at least 12 `## ` H2 sections.

- [ ] **Step 3: Verify frontmatter description doesn't summarize workflow**

Run: `awk '/^---$/{c++} c==1 && /description:/{getline; print}' skills/project-architect/SKILL.md | head -3`
Expected: description starts with "Use when…", does NOT contain phase numbers or workflow steps.

- [ ] **Step 4: Verify no `{{...}}` template placeholders leaked into SKILL.md body that should be replaced at runtime**

Run: `grep -n '{{[A-Z_]\+}}' skills/project-architect/SKILL.md | head -10`
Expected: matches are inside prompt-template fenced code blocks (which is correct — those ARE template placeholders for runtime resolution by the orchestrator). No bare `{{...}}` outside code blocks.

- [ ] **Step 5: Commit**

```bash
git add skills/project-architect/SKILL.md
git commit -m "$(cat <<'EOF'
skill: add Phase 4 (doc gen), 5 (iteration), 6 (post-gen), 7 (plan handoff)

Adds parallel document-author dispatch, claude-md-author + claude-tooling-author
in parallel with last doc batch, decision-revisor iteration loop with snapshot
option, post-generation plugin install offers, optional writing-plans handoff,
full failure-mode and resumability handling.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Phase F — Verification

Verification is end-to-end smoke testing: invoke the architect on a small toy project and confirm it works.

### Task F1: Smoke test — CLI project bootstrap

**Files:**
- Create (temporarily): `/tmp/test-project-architect-cli/`
- No persistent files written into the plugin

The goal: prove that an end-to-end bootstrap works for a CLI tool — one of the simplest project types, fewer templates, fewer phases.

- [ ] **Step 1: Create a scratch test directory**

```bash
TEST_DIR=/tmp/test-project-architect-cli-$$
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "Test dir: $TEST_DIR"
```

Note the directory path for cleanup later.

- [ ] **Step 2: Reload plugins to pick up v2.0**

In the active Claude Code session, run:
```
/reload-plugins
```
Confirm `project-architect@local` is enabled and at version 2.0.0.

- [ ] **Step 3: Invoke the architect in the test directory**

In a new Claude Code session opened with `cd $TEST_DIR && claude`, run:
```
/project-architect
```

Or describe: "Set up a new CLI tool project here."

- [ ] **Step 4: Walk the bootstrap with a minimal CLI answers**

Use these answers when prompted (representative of a tiny CLI tool):
- Elevator pitch: "A CLI to convert markdown files to PDF."
- Project type: "CLI tool" → "Developer tool"
- Stage: "Greenfield"
- Problem & users: "Devs who want quick markdown→PDF from the command line."
- Constraints: "Open-source"
- Team & scale: "Solo, hobby/personal"
- Hard pre-existing decisions: "Rust + cargo"

Continue answering through Phase 0 → Phase 1 → Phase 2 (decline most categories — for a CLI tool, no DB, no auth, no frontend, no hosting beyond `cargo install`) → Phase 2.5 (likely skipped for free OSS) → Phase 3 (testing strategy: cargo test) → Phase 4 (doc gen).

- [ ] **Step 5: Verify generated artifacts**

After the architect completes Phase 6 (or you exit at Phase 5):
```bash
cd "$TEST_DIR"
ls -la
ls docs/
ls docs/decisions/ 2>/dev/null
ls docs/research/ 2>/dev/null
ls .claude/ 2>/dev/null
cat CLAUDE.md | head -30
```

Expected:
- `CLAUDE.md` exists at root.
- `docs/PROJECT_OVERVIEW.md` exists.
- `docs/PROJECT_REQUIREMENTS.md` exists.
- `docs/TESTING_STRATEGY.md` exists (cargo test).
- At least 2 ADR files in `docs/decisions/` (language=Rust, package_manager=cargo).
- `docs/research/phase0-domain.md` exists with research findings.
- `.claude/settings.json` exists with `"model": "claude-opus-4-7"`.
- `.claude/hooks/post-tool-use.sh` exists and is executable.
- `.claude/recommended-plugins.md` mentions Rust-related skills (none specifically for Rust today, but at least the universal recommendations).
- `git log --oneline` shows the auto-commits per phase.

- [ ] **Step 6: Document any issues**

If anything is missing or broken, file an issue in `docs/superpowers/plans/2026-05-12-project-architect-v2-implementation-issues.md` with reproduction steps. Do NOT block Phase G; defer minor issues to a v2.1 follow-up plan.

- [ ] **Step 7: Cleanup**

```bash
cd /Users/vladimir/projects/project-architect
rm -rf "$TEST_DIR"
```

- [ ] **Step 8: No commit needed** (no plugin files changed; this task is verification only). If issues file was created, commit it.

```bash
if [ -f docs/superpowers/plans/2026-05-12-project-architect-v2-implementation-issues.md ]; then
  git add docs/superpowers/plans/2026-05-12-project-architect-v2-implementation-issues.md
  git commit -m "$(cat <<'EOF'
docs(plan-issues): record F1 smoke-test findings

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
fi
```

---

### Task F2: Smoke test — Claude Code plugin bootstrap (meta)

A higher-fidelity test: invoke the architect to bootstrap a *new Claude Code plugin*. This exercises the `Claude Code plugin` type taxonomy, PLUGIN_SPECIFIC template, and the recommended-plugins curation for plugin-dev skills.

- [ ] **Step 1: Scratch dir**

```bash
TEST_DIR=/tmp/test-project-architect-plugin-$$
mkdir -p "$TEST_DIR"
echo "Test dir: $TEST_DIR"
```

- [ ] **Step 2: Open a new Claude Code session in the test dir, invoke the architect**

Answers:
- Elevator pitch: "A Claude Code plugin that helps me write Notion pages from terminal."
- Project type: "Claude Code plugin" → "command-focused"
- Stage: "Greenfield"
- Problem & users: "Me, when I want to draft a Notion page from terminal."
- Constraints: "Open-source"
- Team & scale: "Solo, hobby"
- Hard pre-existing decisions: "Bash for command scripts"

Walk Phase 0 → 1 → 2 → 3 → 4.

- [ ] **Step 3: Verify plugin-specific outputs**

```bash
cd "$TEST_DIR"
ls docs/
cat docs/PLUGIN_SPECIFIC.md | head -50
cat .claude/recommended-plugins.md | grep -A2 "plugin-dev"
```

Expected:
- `docs/PLUGIN_SPECIFIC.md` exists and references plugin components decisions.
- `.claude/recommended-plugins.md` includes `plugin-dev:create-plugin`, `plugin-dev:command-development`, `plugin-dev:plugin-structure`.
- ADRs reference the plugin type/subtype choice.

- [ ] **Step 4: Verify the architect ran in Opus 1M context**

Read the latest hook script or settings.json:
```bash
cat .claude/settings.json | jq .model
```
Expected: `"claude-opus-4-7"`.

- [ ] **Step 5: Cleanup**

```bash
cd /Users/vladimir/projects/project-architect
rm -rf "$TEST_DIR"
```

- [ ] **Step 6: No commit unless issues file was updated** (same as F1).

---

## Phase G — Wrap-up

### Task G1: Final review, push, and tag v2.0.0

**Files:**
- Modify: `CHANGELOG.md` (move `[2.0.0]` from "Unreleased" if applicable; refine release notes based on smoke tests)

- [ ] **Step 1: Final review of plugin contents**

```bash
cd /Users/vladimir/projects/project-architect

# Plugin manifests
cat .claude-plugin/plugin.json | jq .
cat .claude-plugin/marketplace.json | jq .

# File counts
echo "Agents: $(ls agents/*.md 2>/dev/null | wc -l)"
echo "References: $(ls skills/project-architect/references/*.md 2>/dev/null | wc -l)"
echo "Templates: $(ls skills/project-architect/references/templates/*.md 2>/dev/null | wc -l)"

# SKILL.md sanity
wc -l skills/project-architect/SKILL.md
head -10 skills/project-architect/SKILL.md
```

Expected:
- Plugin v2.0.0.
- 5 agents.
- 6 references at top level.
- 56 templates.
- SKILL.md 360–450 lines, frontmatter intact.

- [ ] **Step 2: Confirm no leftover v1 artifacts**

```bash
[ -f skills/project-architect/references/document-templates.md ] && echo "v1 doc-templates still present (should be deleted)" || echo "v1 doc-templates cleaned up: OK"
```

If the v1 monolithic file is still there: delete it and commit.

- [ ] **Step 3: Run a final git status**

```bash
git status
git log --oneline -25
```

Confirm: working tree clean, 20+ commits since initial v1, last commit is meaningful.

- [ ] **Step 4: Push to remote**

```bash
git push origin main
```

- [ ] **Step 5: Tag v2.0.0 release**

```bash
git tag -a v2.0.0 -m "$(cat <<'EOF'
project-architect v2.0.0

Complete redesign as a 9-phase orchestrator:
- 5 subagents (research-scout, document-author, decision-revisor, claude-md-author, claude-tooling-author)
- ~56 doc templates with frontmatter-driven selection
- Research-augmented questioning (per-phase + ad-hoc)
- ADR-tracked decisions, never reused, supersession chain
- Iteration phase with consequence propagation
- Hybrid versioning: in-place + snapshots + ADRs
- Per-folder CLAUDE.md generation
- Generated .claude/ project config (settings, hooks, agents, commands, recommended-plugins)
- Auto-commit cadence via commit-commands:commit
- Opus 4.7 1M context at max effort enforced

See docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md
EOF
)"
git push origin v2.0.0
```

- [ ] **Step 6: Final smoke check — plugin still loads in Claude Code**

In a fresh Claude Code session, run `/plugin` and confirm `project-architect@local` shows version 2.0.0 and loads without errors.

- [ ] **Step 7: Save a memory entry (optional)**

If user agrees, write a project memory entry to `/Users/vladimir/.claude/projects/-Users-vladimir-projects/memory/` noting that project-architect is now at v2.0 with the 5-agent / ~56-template orchestrator design.

---

## Self-Review

After writing the plan, I ran the self-review checklist from writing-skills:

**Spec coverage check.** Each spec section maps to one or more tasks:
- Spec §1 Motivation → covered by overall plan rationale.
- Spec §2 Scope & non-goals → embedded into SKILL.md "What NEVER to do" (Task E3) and plan header.
- Spec §3 Plugin layout → Phase A (scaffolding) + Phase C (templates) + Phase D (agents) + Phase E (SKILL.md).
- Spec §4 Phase model → SKILL.md Phases (Tasks E1–E3).
- Spec §5 Auto-commit cadence → Every task ends with a `commit-commands:commit` invocation; SKILL.md describes the per-trigger pattern (Task E1/E2/E3).
- Spec §6 Model/effort/1M-context → Task E1 (Preflight) + dispatch-envelope notes in Phase D agents.
- Spec §7 Subagent contracts → Phase D Tasks D1–D5.
- Spec §8 Template library + doc selection → Phase C Tasks C1–C6 + reference document-catalog.md (Task B3).
- Spec §9 Research integration + ADR loop → Task B4 (research-prompts.md) + B5 (revision-playbook.md) + SKILL.md "Filing an ADR" (Task E2) + Phase 5 iteration in Task E3.
- Spec §10 Skill composition → SKILL.md skill invocations woven into Tasks E1–E3.
- Spec §11 State management → SKILL.md state section + Resumability (Task E1, E3).
- Spec §12 Failure modes → SKILL.md "Failure modes & recovery" (Task E3).
- Spec §13 Open issues → addressed in plan via concrete decisions (e.g., AskUserQuestion fallback in Task E1; lock file in SKILL.md state section).
- Spec §14 Implementation handoff → this plan IS that handoff.

**Placeholder scan.** Searched for "TBD", "TODO", "fill in", "similar to", "implement later" — none found in task bodies. The `{{...}}` placeholders that appear inside prompt-template fenced code blocks are intentional — they're runtime template substitutions the orchestrator resolves, NOT plan placeholders for the engineer.

**Type consistency.** Subagent names match across tasks: `research-scout`, `document-author`, `decision-revisor`, `claude-md-author`, `claude-tooling-author`. Template names match between document-catalog (B3), revision-playbook (B5), Phase C template tasks, and the agent system prompts (D2, D3). State schema field names (`decisions`, `adrs_filed`, `next_adr_id`, `research_findings`, `snapshots`, `git`, `model_state`, `phase_progress`, `lock`) are consistent across SKILL.md, state-schema references, and agent prompts.

**One known minor inconsistency** (acceptable): the spec references `docs/superpowers/specs/...` and `docs/superpowers/plans/...` inside the project-architect repo (where the plugin lives), while the architect-generated `docs/` lives inside *user projects*. This is intentional dual use — the plugin's own design docs vs. the plugin's output for user projects. Both are correctly placed.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — Dispatch a fresh subagent per task, two-stage review between tasks, fast iteration. Phase B's tasks B4–B6 and Phase C's tasks C1–C6 and Phase D's tasks D1–D5 can run as parallel batches (subagent-driven-development handles dispatching). Phases A, E, F, G run sequentially.

**Required sub-skill:** Use `superpowers:subagent-driven-development` to execute.

**2. Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints for review.

**Required sub-skill:** Use `superpowers:executing-plans` to execute.

Which approach?
