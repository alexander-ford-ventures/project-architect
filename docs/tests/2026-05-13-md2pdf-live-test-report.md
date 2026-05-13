<!-- Author: Vladimir Dukelic <vladimir@dukelic.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/siliconyouth/project-architect) -->

# project-architect v2.1.4 — Live Test Report

> **A comprehensive end-to-end validation against `md2pdf`, May 12–13 2026.**
> Status: COMPLETE. 14 bugs surfaced. Full v2.2 spec produced.
>
> **Update 2026-05-13**: 6 of 14 bugs fixed in v2.1.5 (tag pushed). Remaining 8 ratchet via v2.2 (in flight). See per-bug status updates in [Bug Surface](#bug-surface) below.

| | |
|---|---|
| **Test target** | `/private/tmp/pa-test-cli/` (`md2pdf` — Rust CLI, markdown → PDF via Typst) |
| **Plugin under test** | `project-architect@siliconyouth` v2.1.4 |
| **Test duration** | ~2h45 architect runtime + ~50m plan generation |
| **Phases exercised** | All 8 (preflight + 0a + 1 + 2 + 2.5 + 3 + 4 + 5 + 6 + 7) |
| **Final state** | 34 commits · 93 files tracked · v1.0 snapshot preserved |
| **Bug count** | 14 across 5 categories |
| **Outcome** | ✅ Bootstrap pattern validated · Ready for v2.1.5 patches + v2.2 redesign |

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [The Test](#the-test)
   - 2.1 [Methodology](#methodology)
   - 2.2 [Final Artifact](#final-artifact)
   - 2.3 [Phase-by-Phase Narrative](#phase-by-phase-narrative)
3. [Bug Surface](#bug-surface)
4. [Validation Moments](#validation-moments) — what worked
5. [Unified v2.2 Plan](#unified-v22-plan) — four sketches + CLI-UX expansion
6. [v2.1.5 Micro-Bundle](#v215-micro-bundle) — ships first
7. [Implementation Plan](#implementation-plan) — three-week schedule
8. [Appendices](#appendices)
   - A. [All 15 ADRs](#appendix-a--all-15-adrs)
   - B. [Final Tech Stack](#appendix-b--final-tech-stack)
   - C. [BACKLOG (13 items)](#appendix-c--backlog-13-items)
   - D. [Full Commit History](#appendix-d--full-commit-history-34-commits)
   - E. [.claude/ Tooling Generated](#appendix-e--claude-tooling-generated)

---

## Executive Summary

`project-architect` was driven end-to-end against a non-trivial real project: a Rust CLI for converting Markdown files to PDF via the Typst engine. The plugin successfully produced a complete design bundle (15 docs, 15 ADRs, 4 research findings, full project tooling, and a 2,701-line implementation plan via handoff to `superpowers:writing-plans`).

The test surfaced **14 distinct bugs** across **5 categories** (state/schema, orchestration, agent quality, consistency, research surfacing) and demonstrated **5 strong validation moments** — patterns that worked beautifully and should be preserved.

**Three release tracks emerge from the test:**

1. **v2.1.5** — micro-bundle of 6 tactical fixes (~2-3 days). Ships first.
2. **v2.2** — full design redesign with 4 unified sketches (~3 weeks). Ships next.
3. **v2.3+** — long-tail improvements deferred from this report.

The report below documents everything in detail, including a unified ready-to-implement plan for v2.2.

---

## The Test

### Methodology

A user-driven walkthrough of the architect's complete questioning flow, executed in a fresh terminal against an empty directory. The parent Claude Code session (separate from the architect run) acted as observer and advisor, recording bugs, validation moments, and design opportunities in real time.

**Setup:**
- Working directory: `/private/tmp/pa-test-cli/`
- Empty `git init` at start, no remote
- All recommended Preflight plugins installed
- `project-architect@siliconyouth` v2.1.4 invoked via `/project-architect:project-architect`
- Test target chosen for breadth: a CLI hits Phase 1/2/3/4/5/6 paths that wouldn't trigger for a web-app or library

**Observation discipline:**
- Every architect output captured to chat
- Every state change verified via `jq` against `docs/_architect_state.json`
- Every commit verified via `git log`
- Bug discoveries recorded immediately with severity, category, and v2.x patch target

### Final Artifact

```
/private/tmp/pa-test-cli/
├── .claude/                        13 files (settings, 5 hooks, 3 commands, 1 agent, 2 READMEs, recommended-plugins.md)
├── .gitignore                      Rust + insta + per-machine state lock
├── CLAUDE.md                       Project context for future sessions
├── Cargo.toml                      ADR-grounded deps, dist profile, lib+bin layout
├── LICENSE-MIT                     Standard MIT
├── LICENSE-APACHE                  Standard Apache 2.0
├── NOTICE                          Stub with TODO marker for typst NOTICE injection
├── rust-toolchain.toml             stable + rustfmt + clippy
├── docs/
│   ├── ARCHITECTURE.md             Pipeline + module structure + boundaries
│   ├── BACKLOG.md                  13 deferred items with rationale + triggers
│   ├── BUILD_AND_RUN.md            Local dev workflow
│   ├── CI_CD.md                    dist + release-plz workflow design
│   ├── CLI_REFERENCE.md            Flags, exit codes, help text style
│   ├── CONTRIBUTING.md             Conventional Commits + PR process
│   ├── LICENSE_NOTICE.md           Source/binary license disambiguation per ADR 0010
│   ├── PERFORMANCE_BUDGETS.md      Soft targets + stretch + baseline framing
│   ├── PLATFORMS.md                3 OS targets + Tier-1 matrix
│   ├── PROJECT_OVERVIEW.md         Hub doc with cross-links
│   ├── PROJECT_REQUIREMENTS.md     F-1..F-12 functional + non-functional
│   ├── RELEASE_PROCESS.md          Conventional Commits → release-plz → dist → tag
│   ├── SECURITY_AND_COMPLIANCE.md  Threat model, allowlist, path safety, network policy
│   ├── TECH_STACK.md               Crate-by-crate justification
│   ├── TESTING_STRATEGY.md         insta + assert_cmd + assert_fs strategy
│   ├── decisions/                  15 ADRs (0001-0015), one supersession (0015 ⊃ 0012 partial)
│   ├── plans/
│   │   └── MVP_IMPLEMENTATION_PLAN.md   2,701 lines, 28 tasks (20 v0.1 + 8 v0.2)
│   ├── research/                   4 phase-boundary research findings
│   └── versions/v1.0/              Snapshot of all docs + archived state.json
└── src/
    ├── error.rs                    Md2pdfError stub (thiserror-derived)
    ├── lib.rs                      Public API stub with module TODOs
    └── main.rs                     Thin clap-wrapper stub
```

**By the numbers:**

| Metric | Value |
|---|---|
| Git commits on `main` | 34 |
| Files tracked | 93 |
| Design docs generated | 15 |
| ADRs filed | 15 (one partial supersession: 0015 supersedes 0012's allowlist subsection) |
| Research findings | 4 (Phases 0, 1, 2, 3) |
| BACKLOG items deferred | 13 (each with rationale + trigger conditions) |
| MVP plan lines | 2,701 |
| MVP plan tasks | 28 (20 v0.1 + 8 v0.2 candidates) |
| `.claude/` files | 13 (1 settings, 5 hooks, 3 slash commands, 1 agent, 2 READMEs, 1 recommended-plugins.md) |
| `src/` scaffold files | 3 |
| v1.0 snapshot files | 18 (markdown + state) |

### Phase-by-Phase Narrative

```mermaid
graph LR
    A[Phase 0<br/>Kickoff] --> B[Phase 0a<br/>Domain Research]
    B --> C[Phase 1<br/>Vision/Scope]
    C --> D[Phase 2<br/>Tech Stack + ADRs 0001-0009]
    D --> E[Phase 2.5<br/>Cost Modeling]
    E --> F[Phase 3<br/>Architecture + ADRs 0010-0013]
    F --> G[Phase 4 W1<br/>8 Doc-Authors Parallel]
    G --> H[Phase 4 W2<br/>CLAUDE.md + .claude]
    H --> I[Phase 5 Iteration<br/>+7 docs, ADR 0014, 0015]
    I --> J[Phase 6<br/>Lock + Bootstrap]
    J --> K[Phase 7<br/>writing-plans Handoff]
```

| Phase | Time | Output |
|---|---|---|
| **0 — Preflight** | ~2 min | Soft-dep check, version freshness, cache hygiene |
| **0a — Domain Research** | ~5 min | `phase0-domain.md` (~19k) covering Rust CLI MD→PDF landscape |
| **1 — Vision/Scope** | ~10 min | 3 batches: vision, scope, MD features. ~20k research file. |
| **2 — Tech Stack + ADRs** | ~15 min | ADRs 0001-0004 (core libs), then revise for ADR 0005 (theming) + 0006 (scope addendum). Then ADRs 0007-0009 (testing/release/errors). |
| **2.5 — Cost Modeling** | ~3 min | Verdict: $0/month all free tier |
| **3 — Architecture** | ~20 min | ADRs 0010-0013 from phase-2 research findings (license correction, Typst-native highlighting supersedes syntect, security architecture, single-crate module structure). Phase-3 pattern-validation research dispatched in background. |
| **4 wave 1 — Doc Generation** | ~15 min | 8 doc-authors dispatched in parallel: PROJECT_OVERVIEW, PROJECT_REQUIREMENTS, PLATFORMS, CI_CD, TESTING_STRATEGY, CONTRIBUTING, RELEASE_PROCESS, SECURITY_AND_COMPLIANCE |
| **4 wave 2 — Tooling** | ~7 min | claude-md-author + claude-tooling-author in parallel: CLAUDE.md + .claude/* |
| **5 — Iteration** | ~30 min | Wave 1: filled 7 ADR-promised gaps (BACKLOG, ARCHITECTURE, LICENSE_NOTICE, TECH_STACK, CLI_REFERENCE, BUILD_AND_RUN, PERFORMANCE_BUDGETS) + ADR 0014 (i18n). Wave 2: ADR 0015 (HTML allowlist refinement) via decision-revisor. |
| **6 — Lock + Bootstrap** | ~10 min | v1.0 snapshot, BACKLOG addition (pipeline reconsider with triggers), `cargo init` + Cargo.toml grounding + license + NOTICE + rust-toolchain.toml |
| **7 — Plan Handoff** | ~50 min | Outline preview, then full handoff to `superpowers:writing-plans`. Result: 2,701-line MVP plan. |

---

## Bug Surface

**14 bugs across 5 categories.** Each row lists severity, fix priority, and the v2.x track that resolves it.

### 🗄 STATE/SCHEMA bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 1 | `state.schema_version` carries plugin version (`"2.1.4"`), not state-schema version | high | v2.1.5 | Use state-schema `"2.0"`, separate from `state.plugin_version` | ✅ **FIXED** in commit `f0b6290` |
| 2 | `state.started_at` is a date (`"2026-05-12"`), not ISO8601 datetime | medium | v2.1.5 | Always emit `YYYY-MM-DDTHH:MM:SSZ` | ✅ **FIXED** in commit `875e432` |
| 3 | `state.json` drift: `last_action` and `phase` stale after wave-2 commits | high | v2.2 (auditor check 13) | Auditor detects drift via state vs git log timestamp | ⏳ pending v2.2 |

### 🔀 ORCHESTRATION bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 4 | Pattern-validation research dispatched in parallel with Phase 4; landed AFTER doc-author agents started — no phase-boundary gate | high | v2.2 (B check 16) | Phase-boundary gate primitive — Phase N can't dispatch downstream agents until upstream signals satisfied | ⏳ pending v2.2 |
| 5 | 7 ADR-promised `affected_docs` not force-included in Phase 4 selection (BACKLOG, ARCHITECTURE, LICENSE_NOTICE, TECH_STACK, CLI_REFERENCE, BUILD_AND_RUN, PERFORMANCE_BUDGETS) | **CRITICAL** | v2.1.5 + v2.2 (B check 2 ratchets) | Force-include `∪{adr.affected_docs} ∩ catalog` in selection | ✅ **FIXED** in commit `e68d12d` |
| 6 | Phase 5 iteration menu auto-surfaced only 2 of 10 known issues — no "promised vs delivered" reconciliation | high | v2.2 (B) | Auditor output schema seeds menu via `phase_5_seed_items` | ⏳ pending v2.2 |

### 🤖 AGENT QUALITY bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 7 | `claude-md-author` + `claude-tooling-author` commit subjects use `chore:` not `architect(phase-N):` | low | v2.1.5 | Convention check; agent prompt update | ✅ **FIXED** in commit `bdcf968` |
| 8 | `claude-md-author` produced root-only `CLAUDE.md` (no subfolder hierarchy) — possibly intentional for current state, but design intent unclear | medium | v2.2 (B + D) | Auditor check #6 + plan-doc review in Phase 5 | ⏳ pending v2.2 |
| 9 | `decision-revisor` cost overrun: 31 min vs 5-min estimate, ~200k tokens for surgical 5-tag allowlist patch | medium | v2.1.5 (scope discipline) + v2.2 (C runtime budget) | Per-agent runtime budget + scope discipline in agent prompt | ✅ **PARTIALLY FIXED** in commit `984401f` (scope discipline added; runtime budget enforcement is v2.2) |

### 🔄 CONSISTENCY bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 10 | Perf target `≤2s/50pp` inconsistent with Typst's 3-5s baseline | medium | v2.2 (B check 15) | Numerical-consistency check (target ≤ baseline OR explicit "stretch" disclaimer) | ⏳ pending v2.2 |
| 11 | Latin-only i18n recorded as "ADR-ish" in state — decision was missing its formal ADR | medium | v2.2 (B check 14) | ADR-coverage check on multi-alternative decisions | ⏳ pending v2.2 |

### 🔬 RESEARCH SURFACING bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 12 | HTML allowlist additions surfaced by pattern-research but not auto-applied (required user iteration) | low | v2.2 (B) | Auditor `auto_run` field on findings | ⏳ pending v2.2 |
| 13 | 3-stage pipeline reconsider surfaced; user deferred to BACKLOG | low | acceptable | Same `auto_run` mechanism | ✓ acceptable; pipeline is in BACKLOG with trigger conditions |

### 🧹 LIFECYCLE bugs

| # | Bug | Severity | Track | Fix | Status |
|---|---|---|---|---|---|
| 14 | State file deletion at Phase 6 incompatible with `/iterate-design` (would prevent re-opening locked design) | high | v2.1.5 + v2.2 (D state.locked ratchets) | Lifecycle redesign: state.json always preserved; `state.locked` field replaces deletion | ✅ **FIXED** in commit `f70ed65` |

### v2.1.5 fix summary

**6 of 14 bugs fully fixed** in v2.1.5 (#1, #2, #5, #7, #14) plus #9 partially (scope discipline; runtime budget enforcement is v2.2). Plus the universal CLI-UX gate question added in v2.1.5 (sketch E micro-portion).

**Remaining 7 bugs ratchet via v2.2** (in flight per [`docs/superpowers/plans/2026-05-13-v2.2-implementation.md`](../superpowers/plans/2026-05-13-v2.2-implementation.md)).

---

## Validation Moments

Five moments where the architect performed beautifully and these patterns must be preserved in v2.2.

### ✨ 1. Performance reframing (Phase 5)

When the user pointed out the perf target (`≤2s/50pp`) was inconsistent with Typst's observed baseline (`3-5s`), the architect didn't silently overwrite or stubbornly defend. It produced this state structure:

```json
"performance_targets": {
  "policy": "soft documented targets with stretch + baseline framing",
  "baseline_observed": {
    "typst_compile_50page_readme_seconds_typical": "3-5",
    "source": "phase-0 research; Typst 0.14 line"
  },
  "v1_targets": { "warm_conversion_50page_readme_seconds_max": 5 },
  "stretch_goals": {
    "cold_conversion_50page_readme_seconds_max": 2,
    "stretch_disclaimer": "The 2s/50pp cold target is aspirational and below
     the observed Typst-compile baseline of 3-5s; track as a stretch goal
     pending a Typst startup optimization (e.g., precompiled font index,
     krilla migration). Honest v1 baseline is the 5s/50pp warm target."
  }
}
```

It named the target, the baseline, the gap, AND what would close the gap. This is engineering disclosure done right.

### ✨ 2. Partial supersession pattern (ADR 0015 ⊃ ADR 0012)

When extending the HTML allowlist by 5 tags, the architect filed ADR 0015 with the precise supersession:

```yaml
supersedes: "0012 (partial — html_allowlist only)"
```

And reciprocally updated ADR 0012:

```yaml
superseded_by: "0015 (partial — html_allowlist only)"
```

Plus the commit message explicitly noted scope:

> "ADR 0012's path-safety, network-policy, process-isolation, threat-model
> sections remain authoritative — only the allowlist subsection is superseded."

This is **sophisticated ADR hygiene**: not "supersede entire ADR" (would lose value), not "amend in place" (would lose traceability) — explicit partial supersession with reciprocal cross-references.

### ✨ 3. Phase 7 handoff to superpowers

When the user picked option 1 in Phase 7 (generate full impl plan), the architect explicitly transferred control:

```
⏺ Marking Phase 6 done and invoking superpowers:writing-plans. Control transfers there.
```

This is the **first time** the architect explicitly handed off to another skill rather than doing the work itself. It validates the architectural intuition behind the v2.2 multi-session lifecycle (Sketch D): project-architect knows where its responsibility ends.

### ✨ 4. Per-doc/ADR/revision atomic commits

Every artifact got its own commit with Conventional Commits + provenance:

```
docs: generate BACKLOG (phase-5 wave 2)
docs: generate ARCHITECTURE (phase-5 wave 2)
architect(revise): html_allowlist → +5 tags (ADR 0015)
architect(phase-5): ADR 0014 + state hygiene
chore: bootstrap complete (cargo init + license/NOTICE + state archive)
```

The result: 34 atomic, bisect-able commits. A future reader can `git log` to see exactly when each decision was made and which ADR drove it.

### ✨ 5. claude-tooling-author domain awareness

Rather than producing boilerplate `.claude/*`, the agent generated **domain-specific** project tooling:

```
.claude/agents/release-prep.md       ← project-specific release agent
.claude/commands/bump-typst.md       ← matches ADR 0010's Typst-NOTICE bump workflow
.claude/commands/new-theme.md        ← matches ADR 0005's bundled-themes pattern
.claude/commands/release-check.md    ← matches ADR 0008's dist+release-plz pipeline
.claude/hooks/post-bash-commit-lint.sh    ← enforces Conventional Commits per ADR 0008
.claude/hooks/pre-tool-use.sh             ← defence-in-depth from ADR 0012 security policy
```

Every file traces to a specific ADR. **Not boilerplate — derived tooling.**

---

## Unified v2.2 Plan

Four sketches plus a CLI-UX expansion, unified into a single ~3-week plan.

### 🛡 Sketch A — Inline validation in `claude-tooling-author`

**Goal:** Catch malformed shell/JSON before the agent declares done.

**Where it lives:** New "Validation" section appended to `agents/claude-tooling-author.md` prompt.

**Per-file-type validators:**

| Filetype | Validator |
|---|---|
| `*.sh` | `shellcheck -s bash -S warning $f` then `bash -n $f` |
| `*.sh` (executable hooks) | Above + smoke run: `timeout 2 bash $f </dev/null` |
| `settings.json` | `jq empty $f` then `jq -e '.permissions.allow' $f` |
| `*.json` | `jq empty $f` |
| Slash commands (`.claude/commands/*.md`) | YAML frontmatter parse |

**Loop:** Write → validate → on fail re-write with error fed back (max 2 retries) → record `unsafe_to_use` → continue.

**Cost:** ~3-5 Bash calls per file. ~5-30s overhead per agent run. No extra dispatches.

**Live-test verdict:** 0 of 13 known bugs (all `claude-tooling-author` output was clean), but provides regression-prevention. Ship anyway.

### 🔍 Sketch B — Post-Phase-4 `quality-gate-auditor` agent (16 checks)

**Goal:** Cross-cutting audit of the entire generated bundle, catching bugs no single author can see.

**File:** New `agents/quality-gate-auditor.md` with `model: opus`, read-only tools.

**Trigger:** Orchestrator dispatches it once after Phase 4 closes (now generates plans, not execution artifacts), before Phase 5 menu opens. Re-dispatched after each Phase 5 revision wave AND after Phase 7 execution.

**16 audit checks:**

| # | Check | Severity | Catches |
|---|---|---|---|
| 1 | Every link in every `docs/*.md` points to existing file | BLOCKER | latent |
| 2 | Every ADR's `affected_docs` either generated OR explicitly deferred | BLOCKER | **bugs 5, 6** |
| 3 | Every `state.decisions.*` value mentioned in ≥1 doc | WARNING | latent |
| 4 | Every `*.sh` passes `shellcheck` | BLOCKER | latent |
| 5 | Every `*.json` passes `jq empty` | BLOCKER | latent |
| 6 | CLAUDE.md hierarchy: root + ≥N subfolder per project type | WARNING | **bug 8** |
| 7 | Every doc ends with attribution footer | INFO | latent |
| 8 | No unfilled `{{...}}` placeholders | BLOCKER | latent |
| 9 | No `TODO`/`FIXME` outside BACKLOG.md | WARNING | latent |
| 10 | Every doc with frontmatter parses as YAML | BLOCKER | latent |
| 11 | `state.schema_version` is state-schema, NOT plugin version | WARNING | **bug 1** |
| 12 | `state.started_at` parses as ISO8601 datetime | WARNING | **bug 2** |
| 13 | state.json drift: `last_action` references current `state.phase` | WARNING | **bug 3** |
| 14 | Multi-alternative decisions MUST have an ADR | WARNING | **bug 11** |
| 15 | Numerical consistency: target ≤ baseline OR "stretch" disclaimer | WARNING | **bug 10** |
| 16 | Phase-boundary gate signals satisfied before downstream dispatch | BLOCKER | **bug 4** |

**Output:** Structured JSON with `summary`, `findings[]`, and `phase_5_seed_items[]` (auto-populates the iteration menu).

**Cost:** 1 dispatch, ~3-5 min, ~50-100k input tokens.

**Live-test verdict:** 9 hard hits + 4 partial = **13/13 surfaced**.

### ⏱ Sketch C — Agent runtime-budget enforcement

**Goal:** Make agent costs predictable. Bug 9 (`decision-revisor` 6× over estimate) doesn't fit validation — agent did correct work, just took 31 min.

**Per-agent budget table:**

| Agent | Typical | Max |
|---|---|---|
| `research-scout` | 3-5 min | 15 min |
| `document-author` | 2-3 min | 10 min |
| `decision-revisor` | 3-5 min | 12 min |
| `claude-md-author` | 2-3 min | 8 min |
| `claude-tooling-author` | 5-10 min | 20 min |
| `quality-gate-auditor` | 3-5 min | 12 min |

**Per-agent prompt additions:**
- Surface progress message after each significant step
- Stop and report at max budget
- Scope discipline: do ONLY what dispatch envelope asks; treat out-of-scope findings as Phase 5 menu items

**Orchestrator wrapper:** observation only, never blocks. Surfaces "agent X cost N× typical" in Phase 5 menu.

**Cost:** ~80 LOC total.

**Live-test verdict:** 1 hard hit + 2 partial = 3/13.

### 🔄 Sketch D — Multi-session lifecycle with design-first + superpowers handoff

**Goal:** Resolve scope-creep tension by making EVERY executable artifact design-first. Project-architect produces design + plan docs; execution lives in a new Phase 7 (for tooling) or hands off to `superpowers` (for product code).

**The new phase structure:**

```
SESSION 1 — project-architect
├── Phase 1-3: Discovery + decisions + ADRs (unchanged)
├── Phase 4: Generate design docs + plan docs
│   ├── docs/*.md (existing design docs)
│   ├── docs/CLAUDE_MD_PLAN.md           ← NEW
│   ├── docs/CLAUDE_TOOLING_PLAN.md      ← NEW
│   ├── docs/SCAFFOLD_PLAN.md            ← NEW
│   └── docs/NEXT_STEP_PLAN.md           ← NEW
├── Phase 5: Iteration menu — edit plans before execution
├── Phase 6: LOCK + FINALIZE
│   ├── Snapshot docs → docs/versions/{version}/
│   ├── Set state.locked = true; state.version = "v1.0"; state.locked_at = ISO8601
│   ├── KEEP docs/_architect_state.json (canonical for /iterate-design)
│   ├── ALSO archive state.json → docs/versions/{version}/_architect_state.json
│   └── Optional: push to remote (offer; require user opt-in)
├── Phase 7: TOOLING EXECUTION (NEW)
│   ├── Menu: which plans to execute?
│   │   ├── (a) Execute CLAUDE_MD_PLAN  → CLAUDE.md
│   │   ├── (b) Execute CLAUDE_TOOLING_PLAN → .claude/*
│   │   ├── (c) Hand off SCAFFOLD_PLAN to superpowers (writing-plans → SDD)
│   │   ├── (d) Skip all execution
│   │   └── (e) (a) + (b) + offer (c) — default productive path
└── Phase 8: HANDOFF (NEW)
    ├── Print restart instructions
    └── Architect run ends

[USER MANUALLY RESTARTS Claude Code in this directory]

SESSION 2 — fresh session, CLAUDE.md auto-loaded as router:
  CLAUDE.md presents next-step menu via slash commands
  /scaffold       → invokes superpowers:writing-plans + SDD against SCAFFOLD_PLAN.md
  /implement <X>  → uses PROJECT_REQUIREMENTS.md as spec
  /iterate-design → re-launches project-architect (state.locked unlock prompt)
```

#### State file lifecycle (CRITICAL — replaces buggy "delete state" behavior)

The state file at `docs/_architect_state.json` is **always preserved**:

| Location | Purpose | Lifecycle |
|---|---|---|
| `docs/_architect_state.json` | **Canonical "current" state** | Created Phase 0; persists indefinitely; consumed by `/iterate-design` |
| `docs/versions/v1.0/_architect_state.json` | Versioned snapshot at lock | Created in Phase 6; never modified after |

**Three new state fields** (added in Phase 6 LOCK):

```json
{
  "locked": true,
  "version": "v1.0",
  "locked_at": "2026-05-13T01:23:45Z"
}
```

The original Phase 6 substep "delete state file" option is **REMOVED**. It was incompatible with `/iterate-design` and made the multi-session story impossible.

#### Per-phase memory persistence (sub-section)

Make project-architect runs visible to fresh Claude Code sessions opened in *any* directory.

**Cadence:** Write/update memory at every phase boundary. After-each-batch is too noisy; after-only-at-lock loses crash recovery.

| Phase | Memory action |
|---|---|
| 0a | **Create** initial entry — project exists, type, elevator pitch |
| 1 | Update — vision summary, scope decisions |
| 2 | Update — stack summary, ADR count |
| 2.5 | Update — cost verdict |
| 3 | Update — architecture decisions, ADR count |
| 4 | Update — doc count, doc list |
| 5 | Update on each revision wave — what changed |
| 6 | **Major update** — mark `LOCKED at v1.0`, link to snapshot |
| 7 | Update — plan path, "ready to execute via /scaffold" |
| 8 | Final update — restart instructions, slash command list |

**State.json gets a new field:** `state.memory_pointer: { name, path, last_synced }`. After the first memory write in Phase 0a, every subsequent phase update reads this pointer to find/edit the same entry.

**Memory entry shape:**

```markdown
---
name: project-architect — {project_name}
description: {one-line current status}
type: project
---

**Status ({date}): {phase} — {locked|in-progress|draft}**
- **Project**: {name} ({elevator_pitch})
- **Path**: {project_dir}
- **Tech stack**: {one-line summary}
- **Decisions**: {N} ADRs filed (latest: {title})
- **Docs**: {M} generated in docs/
- **Plan**: {plan path or "not yet"}

**To resume in a fresh session**:
- `cd {project_dir}` then `/project-architect` — offers resume/iterate based on state
- Or `/scaffold` (post-lock) to invoke superpowers:writing-plans + SDD
```

**Cost:** ~30 LOC orchestrator logic + ~200-400 char Edit per phase.

**Failure modes:** Memory write fails → log + continue. State.json remains authoritative.

#### Cost (Sketch D total)

| Artifact | LOC | Time |
|---|---|---|
| 4 new plan templates | ~600 | 1.5 days |
| Phase 7 execution menu | ~120 | 0.5 day |
| Phase 8 handoff + state.locked field | ~50 | 0.25 day |
| 3 slash command templates | ~150 | 0.5 day |
| CLAUDE.md template — refactor to "router" | ~80 | 0.25 day |
| Resume-from-locked-state logic | ~80 | 0.5 day |
| Per-phase memory persistence | ~30 | 0.25 day |
| Test the multi-session loop end-to-end | — | 0.5 day |
| **Total: ~4.25 days** | | |

### 🌐 Sketch E — Cross-language CLI-UX questioning + template

**Goal:** Phase 1 currently asks about CLI parser (clap, click, commander) but never about CLI-as-product-experience (interactive vs one-shot vs full TUI). Add the question.

**Phase 1 expansion (universal — language-agnostic):**

> Which best describes your tool's interaction style?
> 1. **One-shot** (input → output → exit) — md2pdf, jq, ripgrep, fd
> 2. **Interactive prompts** — `npm init`, `cargo init`, `gh repo create`
> 3. **Full TUI** — atuin, gitui, lazygit, zellij
> 4. **Hybrid** — git (`git rebase -i`)

Plus universal sub-questions: visual style, output format, color policy, accessibility commitments.

**Phase 2 routing (per language):**

| Need | Rust | Go | Python | Node/TS | Ruby | C#/.NET |
|---|---|---|---|---|---|---|
| **TUI** | `ratatui` | `bubbletea` | `textual` | `ink` | (TTY components) | `Terminal.Gui` |
| **Prompts** | `inquire`/`dialoguer` | `huh`/`survey` | `prompt_toolkit` | `@clack/prompts` | `tty-prompt` | Spectre.Console |
| **Progress** | `indicatif` | `mpb` | `rich.progress` | `cli-progress`/`ora` | `tty-progressbar` | Spectre.Console |
| **Color** | `owo-colors` | `lipgloss` | `rich` | `chalk` | `pastel` | Spectre.Console markup |
| **Banners** | `tui-banner`/`figrs` | `figure` | `pyfiglet` | `figlet` | `artii` | (custom) |

**New template:** `CLI_UX_DESIGN.md` (8 sections: interaction model, key bindings, visual design, output formats, error conventions, accessibility, help text, library inventory).

**Cost:** ~1.5 days. Universal Phase 1 question alone is ~1 hour and ships in v2.1.5.

### Coverage matrix (all sketches × all bugs)

| Bug | A | B | C | D | E | Caught by |
|---|---|---|---|---|---|---|
| 1 schema_version | ❌ | ✅ check 11 | ❌ | ❌ | ❌ | B |
| 2 started_at | ❌ | ✅ check 12 | ❌ | ❌ | ❌ | B |
| 3 state drift | ❌ | ✅ check 13 | ❌ | ❌ | ❌ | B |
| 4 research late dispatch | ❌ | ✅ check 16 | ⚠ | ❌ | ❌ | B |
| 5 missing 7 docs | ❌ | ✅ check 2 | ❌ | ⚠ Phase 5 plan-edit | ❌ | B + D |
| 6 menu under-surfacing | ❌ | ✅ output schema | ❌ | ❌ | ❌ | B |
| 7 commit subjects | ❌ | ⚠ partial | ❌ | ✅ Phase 7 naming | ❌ | D |
| 8 root-only CLAUDE.md | ❌ | ✅ check 6 | ❌ | ⚠ Phase 5 plan-edit | ❌ | B + D |
| 9 cost overrun | ❌ | ❌ | ✅ | ❌ | ❌ | C |
| 10 perf inconsistency | ❌ | ✅ check 15 | ❌ | ❌ | ❌ | B |
| 11 i18n no ADR | ❌ | ✅ check 14 | ❌ | ❌ | ❌ | B |
| 12 allowlist not auto-applied | ❌ | ⚠ partial | ❌ | ⚠ Phase 5 plan-edit | ❌ | partial |
| 13 pipeline reconsider | ❌ | ⚠ partial | ❌ | ⚠ Phase 5 plan-edit | ❌ | partial |
| 14 state deletion | ❌ | ❌ | ❌ | ✅ state.locked | ❌ | D |

**Summary:**
- A: 0 hard hits (regression-prevention only)
- **B: 9 hard + 4 partial = 13/14 surfaced**
- C: 1 hard + 2 partial = 3/14
- **D: 1 hard + 4 partial = 5/14 (architectural class)**
- E: 0 (different domain — adds new capability, doesn't fix bugs)

---

## v2.1.5 Micro-Bundle

**Ships first. Estimated effort: ~2-3 days.**

Tactical fixes for the most painful bugs, plus the universal CLI-UX question — small subset of v2.2 work that's safe to ship independently.

| Item | Source | LOC |
|---|---|---|
| Fix `state.schema_version` separate from plugin version | bug 1 | ~20 |
| Fix `state.started_at` to ISO8601 | bug 2 | ~15 |
| Force-include `affected_docs` in Phase 4 selection | bug 5 (subset of B check 2) | ~40 |
| Tighten `decision-revisor` scope in agent prompt (subset of C) | bug 9 | ~30 |
| Fix claude-md/tooling-author commit-subject convention | bug 7 | ~20 |
| Universal CLI-UX gate question in Phase 1 (universal-only — defer per-language picker to v2.2) | sketch E partial | ~80 |
| Remove "delete state file" Phase 6 option (replace with archive-only) | bug 14 partial | ~25 |

Total ~230 LOC. Roughly 2-3 days of focused work including tests.

---

## Implementation Plan

**Total scope: ~3 weeks of focused work.**

### Week 1 — Auditing infrastructure (Sketches B + C)

```
Day 1-4: Sketch B baseline auditor
   • Build `quality-gate-auditor` agent (model: opus, read-only tools)
   • Implement 10 original cross-cutting checks (link integrity, ADR ⇄ doc, hooks, JSON, hierarchy, footer, placeholders, TODOs, frontmatter)
   • Wire into Phase 4 → 5 transition
   • Refactor Phase 5 menu to consume `phase_5_seed_items`

Day 5: Sketch B expansion (checks 11-16) + Sketch C
   • Add state-schema, ISO8601, drift, ADR-coverage, numerical-consistency, phase-boundary checks
   • Add state-schema field: `phase_progress[N].prerequisites_satisfied`
   • Per-agent runtime-budget frontmatter on all 5 existing agents
   • Orchestrator wrapper (observation only, never blocks)
```

### Week 2 — Multi-session lifecycle (Sketch D)

```
Day 1-2: 4 new plan templates
   • CLAUDE_MD_PLAN.md template + frontmatter (generate_when, depends_on)
   • CLAUDE_TOOLING_PLAN.md template
   • SCAFFOLD_PLAN.md template
   • NEXT_STEP_PLAN.md template

Day 3: Phase 7 execution menu
   • Refactor claude-md-author to consume CLAUDE_MD_PLAN.md as input
   • Refactor claude-tooling-author to consume CLAUDE_TOOLING_PLAN.md as input
   • Add Phase 7 dispatch logic with menu options (a-e)

Day 4: Phase 8 handoff + state.locked + slash commands
   • Phase 8 handoff message template
   • state.locked / state.version / state.locked_at fields
   • 3 slash command templates (/scaffold, /implement, /iterate-design)
   • Drop "delete state file" option from Phase 6

Day 5: CLAUDE.md refactor + per-phase memory + resume logic
   • Refactor CLAUDE.md template to "router" content
   • Implement per-phase memory persistence (~30 LOC)
   • state.memory_pointer field + memory write/update logic
   • Resume-from-locked-state in /iterate-design
```

### Week 3 — Polish + integration

```
Day 1-2: Sketch A inline validators
   • Add Validation section to claude-tooling-author prompt
   • Per-filetype validator wrappers (shellcheck, jq, yaml)
   • Retry loop with error feedback

Day 3-4: End-to-end tests against fixtures
   • md2pdf-style fixture (Rust CLI)
   • textual-app-style fixture (Python TUI)
   • gh-style fixture (Go CLI with subcommands)
   • Verify multi-session loop (Session 1 → restart → Session 2 → /scaffold)

Day 5: Docs, release notes, ship v2.2
   • CHANGELOG entry
   • Migration guide for v2.1 → v2.2 users
   • README updates for new phase structure
   • Tag v2.2.0; release-plz handles the rest
```

### Cross-language CLI-UX (Sketch E)

Ship in parallel with Week 1-2:
- Phase 1 universal question: ships in v2.1.5
- Phase 2 per-language picker + CLI_UX_DESIGN.md template: ships in v2.2

### Risks

| Risk | Mitigation |
|---|---|
| Sketch B auditor adds 3-5 min latency to every Phase 4 → 5 transition | `--skip-auditor` escape hatch |
| Sketch C runtime-budget enforcement is observational only | Don't auto-kill — too risky; surface only |
| Phase boundary gates (B check 16) need new state-schema field | Coordinate with Sketch B implementation |
| Sketch D restart-required friction | Phase 8 handoff message is explicit + memorable |
| CLAUDE.md as router depends on Claude Code auto-load behavior | Test thoroughly before ship |
| Slash commands depend on `.claude/commands/*.md` schema | Verify current schema |
| State.locked field is new | Test resume-from-locked behavior end-to-end |

---

## Appendices

### Appendix A — All 15 ADRs

Filed during the live test, in order. Three were corrections of earlier inline state choices, one was a partial supersession.

| # | Title | Type |
|---|---|---|
| 0001 | Rust as implementation language | mandate |
| 0002 | comrak as markdown parser | tech_stack |
| 0003 | Typst-as-library as PDF rendering backend | tech_stack |
| 0004 | clap (derive) as CLI argument parser | tech_stack |
| 0005 | Theming approach — themes + typography flags | architecture |
| 0006 | v1 scope addendum — emoji, relative image paths, HTML pass-through | scope |
| 0007 | Testing stack — cargo test + insta + assert_cmd + assert_fs | tech_stack |
| 0008 | Release automation — `dist` + `release-plz` | tech_stack |
| 0009 | Error handling — anyhow (binary) + thiserror (lib) | tech_stack |
| 0010 | Licensing — source dual MIT-OR-Apache, binary Apache-2.0 with typst NOTICE | tech_stack (correction) |
| 0011 | Syntax highlighting — Typst-native at v1 | tech_stack (supersedes inline syntect choice) |
| 0012 | Security architecture & input trust model | architecture |
| 0013 | Module structure — single crate (`lib.rs` + `main.rs`) | architecture |
| 0014 | i18n scope at v1 — Latin scripts only | scope (formalized "ADR-ish" inline state) |
| 0015 | HTML allowlist refinement — add span/dl/dt/dd/samp | architecture (partial supersession of 0012) |

### Appendix B — Final Tech Stack

```yaml
language: Rust 2024 stable
build_tool: cargo
markdown_parser: comrak >= 0.52
pdf_backend: typst-as-library, pin =0.14.2
cli_parser: clap 4 with derive feature, clap_complete for shell completions
syntax_highlighting: Typst-native (Typst's bundled syntect grammars; ~30 langs)
logging: log + env_logger
license:
  source: dual MIT OR Apache-2.0
  binary: Apache-2.0 (with typst NOTICE bundled per Apache §4(d))
  cargo_toml_spdx: Apache-2.0
testing:
  unit: cargo test
  snapshot: insta
  cli: assert_cmd
  fs_fixtures: assert_fs
release:
  binary_builder: dist (>=0.31)
  versioning: release-plz
  commit_style: Conventional Commits
error_handling:
  binary_boundary: anyhow
  library_types: thiserror
  exit_codes:
    0: success
    1: user error
    2: content error (Typst rejected)
    3: internal error
additional_deps:
  - emojis (GFM shortcodes per ADR 0006)
  - dunce (Windows UNC path canonicalization per ADR 0012)
removed:
  - syntect (superseded by ADR 0011 — Typst-native at v1)
```

### Appendix C — BACKLOG (13 items)

All explicitly deferred with rationale and (where applicable) trigger conditions for re-evaluation.

| # | Item | Trigger / Roadmap |
|---|---|---|
| 1 | Math support (LaTeX-style `$..$` / `$$..$$`) | v2 if user demand |
| 2 | Mermaid diagram rendering | v2 — heavy (JS sidecar) |
| 3 | Non-Latin script support (CJK, Arabic, Devanagari) | v1.x — font-fallback strategy decision needed |
| 4 | User CSS theme override | v2 — would require parallel HTML/CSS rendering path |
| 5 | Custom syntect bridge or syntastica-typst integration | v1.x — only if users complain about ~30-lang coverage |
| 6 | Workspace split (md2pdf-core + md2pdf) | v2 — only when external lib consumer materializes |
| 7 | Pipeline shape: 3-stage → 2-stage (drop intermediate AST) | v1.x condition-gated: implementer friction OR bench >20% AST cost |
| 8 | CI-enforced performance bench job | v1.x+ — overkill until v1 ships |
| 9 | Cover page generation | v0.2 |
| 10 | Code-signing certificates (macOS Developer ID, Windows EV) | v2 — $100-300/yr |
| 11 | Custom domain + GH Pages docs site | v2 — $10-15/yr |
| 12 | Concatenate multiple MDs into one PDF (`--concat`) | v0.2 |
| 13 | TOML config file (`.md2pdf.toml`) + frontmatter overrides | v0.2 — when >10 knobs to manage |

### Appendix D — Full Commit History (34 commits)

Chronological order from initial repo init to architect run end.

```
e0840d9  chore: initialize project repo
a090c79  architect(phase-0): record kickoff decisions
b807c78  architect(phase-0-research): domain research
ef92611  architect(phase-1): vision & scope locked
0c90fe8  architect(phase-2): core libs + ADRs 0001-0004; phase-1 scope research
b74cf43  architect(revise): scope addendum + theming refinement (ADRs 0005-0006)
fa05087  architect(phase-2): testing/release/errors ADRs 0007-0009
acb157f  architect(phase-2.5): cost model = all free tier
42a38f7  architect(phase-3): ADRs 0010-0013 + project name + backlog + phase-2 research
9ccf18d  docs: generate PROJECT_OVERVIEW
4aa97d1  docs: generate PROJECT_REQUIREMENTS
35c2c96  docs: generate PLATFORMS
eb8d915  docs: generate CI_CD
4cabdd8  docs: generate TESTING_STRATEGY
03f2d43  docs: generate CONTRIBUTING
bb32fce  docs: generate RELEASE_PROCESS
58e12ae  docs: generate SECURITY_AND_COMPLIANCE
0bfb98d  architect(phase-3-research): pattern validation findings
5a93f0a  chore: add CLAUDE.md
66784a0  chore: add Claude Code project config
01905f0  docs: generate BACKLOG (phase-5 wave 2)
af700e8  docs: generate ARCHITECTURE (phase-5 wave 2)
8b2604e  docs: generate LICENSE_NOTICE (phase-5 wave 2)
12b04a1  docs: generate TECH_STACK (phase-5 wave 2)
64a6837  docs: generate CLI_REFERENCE (phase-5 wave 2)
cb95e1d  docs: generate BUILD_AND_RUN (phase-5 wave 2)
870be82  docs: generate PERFORMANCE_BUDGETS (phase-5 wave 2)
6fd6be0  architect(phase-5): ADR 0014 + state hygiene
672d3ce  architect(revise): html_allowlist → +5 tags (ADR 0015)
f45a2df  chore: snapshot docs as v1.0
7c25ef8  docs(backlog): add pipeline-shape reconsider (condition-gated)
5592b5a  chore: bootstrap complete (cargo init + license/NOTICE + state archive)
57bffdf  chore: clean up bootstrap state                   ← bug 14: should not have happened
f64d4f3  docs(plan): MVP implementation plan for v0.1 + v0.2 outline
```

### Appendix E — `.claude/` Tooling Generated

Domain-aware project tooling produced by `claude-tooling-author`. Every file traces to a specific ADR.

```
.claude/
├── settings.json                         197 allow / 41 deny per ADR-0012 security policy
├── recommended-plugins.md                Curated plugin list with per-skill rationale
├── agents/
│   ├── README.md
│   └── release-prep.md                   Verifies NOTICE freshness + Typst pin + Conv. Commits + cargo audit
├── commands/
│   ├── README.md
│   ├── bump-typst.md                     Matches ADR 0010 NOTICE-bump workflow
│   ├── new-theme.md                      Matches ADR 0005 bundled-themes pattern
│   └── release-check.md                  Matches ADR 0008 dist+release-plz pipeline
└── hooks/
    ├── pre-tool-use.sh                   Defence-in-depth from ADR 0012
    ├── post-tool-use.sh                  rustfmt advisory
    ├── post-bash-commit-lint.sh          Conventional Commits warning per ADR 0008
    ├── stop.sh                           Pre-finish checklist
    └── session-start.sh                  Orientation on project resume
```

---

## Closing Notes

This live test was the highest-fidelity validation `project-architect` has received to date. The 14 bugs surfaced are not failures — they are the precise output we wanted: real, prioritized, evidence-backed targets for v2.1.5 + v2.2.

The three release tracks (v2.1.5 micro-bundle, v2.2 full bundle, v2.3+ long-tail) give a clear engineering plan for the next ~3 weeks of work. The unified Sketches A/B/C/D + CLI-UX expansion turn what could have been a stack of disconnected fixes into a coherent architectural improvement.

The project-architect concept — "what to build + why" as design docs, with execution handed off to specialized skills — is validated. Phase 7's explicit handoff to `superpowers:writing-plans` was the proof: the architect knows where its responsibility ends.

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
