<!--
Author: Alexander Ford <alex@alexfordlabs.com>
Repository: https://github.com/alexfordlabs/project-architect
License: MIT
-->

# State Schema Reference

Canonical runtime reference for `state.json`. The orchestrator reads this file to know what to write, validate, and migrate. Self-contained: no need to consult the design spec.

---

## File locations

| Path | Purpose |
|---|---|
| `docs/_architect_state.json` | State file. Lives in the generated project, committed at every phase boundary. |
| `docs/_architect_state.lock` | Lockfile. Single-writer guard. Not committed. |

Both paths are relative to the **generated project's** root, not the plugin.

---

## Lifecycle

| Event | Action |
|---|---|
| Preflight (Phase -1) completes | `state.json` created with `schema_version`, `plugin_version`, `started_at`, empty `decisions`, `phase = "preflight"`. |
| Any batch / agent dispatch / commit | Orchestrator persists updated `state.json`. |
| Resume invocation | Read `state.json`, validate schema, re-run preflight, jump to `state.phase`. |
| Phase 6 cleanup (v2.1.5 fix) | **Preserve** `state.json` (canonical cross-session entry point); release `_architect_state.lock` only. Commit `chore: release bootstrap lock`. The state.json is required for `/iterate-design` (v2.2) and for resume from another session. |
| Clean exit (any phase) | Release lock (delete `_architect_state.lock`); leave `state.json` for next resume. |

To re-bootstrap: delete `state.json` and re-invoke. Existing generated docs become reference material — the orchestrator diffs and asks rather than overwriting.

---

## Schema

```jsonc
{
  // Versioning
  "schema_version": "2.0",                  // String. State-schema version, separate from plugin_version. Bumps only when this schema changes (currently "2.0" is the only released version). DO NOT set this to the plugin's version — that's a different concept.
  "plugin_version": "2.0.0",                // String. semver of the plugin that wrote this state.
  "started_at": "2026-05-12T14:00:00Z",     // ISO8601 UTC. Set at file creation.
  "last_updated_at": "2026-05-12T16:30:00Z",// ISO8601 UTC. Rewritten on every save.

  // Lock (added v2.2 — sketch D). See "`locked`, `version`, `locked_at`" section below.
  "locked": false,                          // Boolean. False during run; true after Phase 6 LOCK.
  "version": null,                          // String|null. e.g., "v1.0" after Phase 6; "v1.1-draft" during /iterate-design.
  "locked_at": null,                        // String|null. ISO8601 UTC timestamp of last lock; null when unlocked.

  // Phase pointer
  "phase": "preflight",                     // Enum (see below).
  "current_doc_version": "1.0",             // String. Bumped on snapshot.
  "snapshots": ["v1.0"],                    // String[]. Versions written under docs/versions/.

  // Repo state
  "git": {
    "repo_init": true,                      // Boolean. Was Phase 0a executed?
    "has_remote": true,                     // Boolean.
    "remote_url": "git@github.com:owner/repo.git",  // String|null.
    "branch": "main",                       // String. Active branch.
    "push_strategy": "per_phase"            // "per_phase" | "end_only" | "manual".
  },

  // Model verification
  "model_state": {
    "verified_at_startup": true,            // Boolean. Preflight passed?
    "model_id": "claude-opus-4-7[1m]",      // String.
    "effort": "max",                        // String. Trusted from user confirmation.
    "warnings": []                          // String[]. Non-fatal preflight warnings.
  },

  // User answers / chosen options. Full key catalog: references/revision-playbook.md.
  "decisions": {
    "project.name": "...",
    "project.type": "...",
    "language.primary": "...",
    "database.engine": "...",
    "auth.provider": "..."
    // ...
  },

  // Per-phase progress (see Phase-progress fields below)
  "phase_progress": { "preflight": { "complete": true, "completed_at": "..." } /* ... */ },

  // Doc tracking
  "documents_pending": ["..."],             // String[]. Template names not yet authored.
  "documents_generated": [                  // Object[]. Append-only.
    { "name": "PROJECT_OVERVIEW", "path": "docs/PROJECT_OVERVIEW.md",
      "version": "1.0", "generated_at": "..." }
  ],

  // ADR ledger
  "adrs_filed": [
    { "id": "0001", "title": "Use Postgres", "date": "...",
      "status": "accepted", "supersedes": null }
  ],
  "next_adr_id": "0007",                    // Zero-padded 4-digit string.

  // Research artifacts
  "research_findings": [
    { "phase": "phase_0", "topic": "domain",
      "file": "docs/research/phase0-domain.md", "dispatched_at": "..." }
  ],

  // Plugin recommendations. Two write points:
  //   • Phase -1 "Soft-dependency check": probes the 6 baseline recommended plugins
  //     and writes one entry per plugin with `missing: true|false` and `installed`
  //     (true if installed during Preflight, false if user chose to continue without).
  //   • Phase 6: per-project recommendations from claude-tooling-author may be
  //     appended; their install outcome is recorded back into `installed`.
  "recommended_plugins": [
    { "name": "superpowers", "reason": "Phase 4 / Phase 7", "missing": false, "installed": true },
    { "name": "hookify", "reason": "claude-tooling-author hooks", "missing": true, "installed": false }
  ],

  // Concurrency guard. Mirror of _architect_state.lock; the file is canonical.
  "lock": { "pid": 42, "host": "macbook-air", "acquired_at": "..." }
}
```

### `schema_version` vs `plugin_version` — DO NOT CONFUSE

These are **independent versions**:

- `schema_version` describes the layout of `state.json` itself (what fields exist, what types they are, what enums are valid). Currently `"2.0"`. Only bumps when migration is required.
- `plugin_version` describes which version of `project-architect` wrote this state. Currently follows semver of `.claude-plugin/plugin.json`. Bumps with every release.

A v2.1.4 plugin can write a state with `schema_version: "2.0"`. A future v3.0 plugin could ALSO write `schema_version: "2.0"` if no schema migration was needed.

The Preflight phase MUST initialize `schema_version` to the constant `"2.0"`, NOT to whatever value `plugin.json` reports. This was a bug in v2.1.4 and earlier — see `docs/tests/2026-05-13-md2pdf-live-test-report.md` bug #1.

### `locked`, `version`, `locked_at` (added v2.2 — sketch D)

After Phase 6 completes, the architect run is "locked" — the design is frozen at a named version, and `/iterate-design` is the canonical way to re-open it.

- `locked` (bool): false during the architect run; true after Phase 6 LOCK.
- `version` (string): semver-style label, e.g., `"v1.0"`. After `/iterate-design`, becomes `"v1.1-draft"`. Re-locks to `"v1.1"`.
- `locked_at` (ISO8601 datetime, nullable): timestamp of last lock. Null when unlocked.

These fields live at the top of state.json alongside `schema_version` and `plugin_version`. The Preflight phase initializes them as `locked: false`, `version: null`, `locked_at: null`. Phase 6 LOCK sets `locked: true`, `version: "v1.0"`, and `locked_at` to the current ISO8601 UTC timestamp. The `/iterate-design` command (v2.2) flips `locked` back to false, sets `version` to `"<prev>-draft"` (e.g., `"v1.1-draft"`), and clears `locked_at`; the post-iterate re-lock writes the bumped version (`"v1.1"`) and a fresh `locked_at`.

### `memory_pointer` (added v2.2 — sketch D, per-phase memory persistence)

After the first memory write in Phase 0a, the orchestrator records where it wrote to:

```json
"memory_pointer": {
  "name": "project_architect_md2pdf.md",
  "path": "/Users/<user>/.claude/projects/.../memory/project_architect_md2pdf.md",
  "last_synced": "2026-05-13T01:23:45Z"
}
```

Fields:

- `name` (string): the basename of the memory file (e.g., `project_architect_md2pdf.md`)
- `path` (string): absolute path to the memory file
- `last_synced` (ISO8601 datetime): timestamp of the last successful write/update

Subsequent phase updates Edit this same file. If memory is missing or moved, regenerate from state and update pointer. See `references/memory-persistence.md` for cadence and entry template.

Initialized as `null` at Preflight; set on first write at Phase 0a; updated on every subsequent phase write.

### Timestamps — always ISO8601 UTC, never date-only

Every timestamp field in `state.json` and the lockfile uses **ISO8601 UTC datetime** format: `YYYY-MM-DDTHH:MM:SSZ` (e.g., `"2026-05-12T22:45:00Z"`).

**Never date-only** (`"2026-05-12"`) — that strips the time component and is a bug. The fields affected:

- `started_at` (state.json)
- `last_updated_at` (state.json)
- `phase_progress[<phase>].completed_at` (state.json)
- `documents_generated[].generated_at` (state.json)
- `research_findings[].dispatched_at` (state.json)
- `recommended_plugins[].detected_at` (state.json)
- `adrs_filed[].date` — by ADR convention this is date-only (matches the ADR document's `date:` frontmatter), but state.locked_at and state.locked_by_until-style fields are full ISO8601.
- `lock.acquired_at` (lockfile)
- `state.locked_at` (added in v2.2 Sketch D)

The canonical Bash incantation to produce a correct timestamp is:

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

The `-u` ensures UTC (no tz issue across machines); the `Z` suffix is ISO8601's UTC marker.

**Validation:** at startup, the orchestrator (or quality-gate-auditor in v2.2) checks that `state.started_at` parses cleanly via Python's `datetime.fromisoformat()`. Date-only values fail this check.

**Phase enum:** `"preflight" | "phase_0a" | "phase_0" | "phase_1" | "phase_2" | "phase_2.5" | "phase_3" | "phase_4" | "phase_5" | "phase_6" | "phase_7" | "phase_8" | "complete"`

`phase_7` and `phase_8` were added in v2.2 (sketch D) — they correspond to the new Tooling Execution and Handoff phases that run after Phase 6 LOCK. See SKILL.md Phase 7 and Phase 8.

---

## Phase-progress fields

Each `phase_progress[<phase>]` entry tracks completion and work-in-flight state for resume.

| Phase | Fields | Resume signal |
|---|---|---|
| `preflight` | `complete`, `completed_at` | Re-run unconditionally on resume (model may have changed). |
| `phase_0a` | `complete`, `completed_at` | Skip if `git.repo_init == true`. |
| `phase_0` | `complete`, `completed_at` | Skip if complete. |
| `phase_1` | `complete`, `batches_completed` (int) | Resume at next unanswered batch. |
| `phase_2` | `complete`, `batches_completed` (int), `categories_remaining` (string[]) | Resume at first category in `categories_remaining`. |
| `phase_2.5` | `complete` | All-or-nothing. Re-dispatch pricing research if incomplete. |
| `phase_3` | `complete`, `areas_remaining` (string[]) | Resume at first area in `areas_remaining`. |
| `phase_4` | `complete`, `docs_remaining` (string[]) | Resume at next pending batch of 8. |
| `phase_5` | `complete`, `revisions_made` (int) | Re-enter menu loop. |
| `phase_6` | `complete`, `plugins_installed` (string[]) | Resume at next unresolved plugin offer. |
| `phase_7` | `complete`, `tooling_executed` (bool) | Tooling Execution phase (v2.2 — sketch D). Skip if already executed. |
| `phase_8` | `complete`, `handoff_invoked` (bool) | Handoff phase (v2.2 — sketch D). If handoff invoked, do not re-invoke. |

`completed_at` is ISO8601 UTC. `*_remaining` arrays shrink as work completes; all other arrays are append-only.

### `prerequisites_satisfied` (added v2.2)

Each `phase_progress[<phase>]` entry gains a `prerequisites_satisfied: bool` field. The orchestrator MUST verify the upstream phase's `prerequisites_satisfied == true` before dispatching any agent for the downstream phase. This is the **phase-boundary gate** that prevents the bug surfaced during the md2pdf live test (pattern-validation research dispatched in parallel with Phase 4 instead of finishing before).

| Phase | Prerequisites satisfied when |
|---|---|
| `preflight` | Always true once Preflight passes (no upstream). |
| `phase_0a` | Preflight complete. |
| `phase_0` | Phase 0a complete (or skipped). |
| `phase_1` | Phase 0 complete AND domain-research findings file exists. |
| `phase_2` | Phase 1 complete AND scope-research findings file exists. |
| `phase_2.5` | Phase 2 complete AND stack-gotchas research findings file exists. |
| `phase_3` | Phase 2.5 complete (cost model captured). |
| `phase_4` | Phase 3 complete AND pattern-validation research findings file exists. **This is the bug-#4 fix.** |
| `phase_5` | Phase 4 complete AND quality-gate-auditor returned (no BLOCKER findings, or user explicitly approved with BLOCKERs). |
| `phase_6` | Phase 5 approved (user picked option a or equivalent). |
| `phase_7` | Phase 6 complete AND user opted into tooling execution. |
| `phase_8` | Phase 7 complete (or skipped via menu). |

The orchestrator sets `prerequisites_satisfied = true` ONLY when all listed conditions are met. Auditor check 16 (B16, `phase_gates`) verifies this for the `state.phase` value at audit time.

---

## `recommended_plugins[]` fields

One entry per recommended plugin probed at Phase -1 (six baseline entries) plus any per-project additions appended in Phase 6. Append-only across both write points; updates flip the `installed` flag on existing entries when an install completes.

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Qualified plugin/skill name (e.g., `superpowers`, `hookify`, `claude-md-management`). Use the marketplace install name; namespaced skills like `hookify:writing-rules` go in `reason` not `name`. |
| `reason` | string | yes | One-line "used by which agent/phase for what" justification. Example: `"claude-tooling-author hooks"` or `"Phase 4 / Phase 7"`. |
| `installed` | bool | yes | True if the plugin was installed (either already present at Preflight or installed during Preflight / Phase 6). False if probed-missing-and-skipped or not yet acted on. |
| `missing` | bool | yes | True if the Phase -1 probe found the plugin absent before the user decision. Stays true even after `installed` flips, so the orchestrator can distinguish "had to install" from "was already there." |
| `install_command` | string | no | The exact command the orchestrator offered, e.g., `claude plugin install hookify`. Useful for the generated `recommended-plugins.md` so the user can re-run it later. |
| `detected_at` | string (ISO8601 UTC) | no | When the Phase -1 probe ran. Helps debug stale state on resume. |

Write points:
- **Phase -1** (Preflight "Soft-dependency check") writes one entry per baseline plugin with `missing` and `installed` set from probe + user decision.
- **Phase 6** (Post-Generation Setup, plugin-install offers) may flip `installed: false → true` on existing entries; `claude-tooling-author` may append additional per-project entries during Phase 4 doc-gen.

---

## `decisions` namespace

Dotted keys (`auth.provider`, `database.engine`, `project.name`, …). The full canonical catalog — with the docs each key affects — lives in **[`revision-playbook.md`](./revision-playbook.md)**. Do not duplicate it here.

Orchestrator may write new keys freely; the `decision-revisor` only acts on keys listed in the playbook. New keys without a playbook entry trigger an "unknown key" warning at revision time.

---

## Lockfile protocol

Path: `docs/_architect_state.lock`. Contents:

```jsonc
{ "pid": 42, "host": "macbook-air", "acquired_at": "2026-05-12T14:00:00Z" }
```

1. **Acquire at startup.** Before reading or writing `state.json`, create the lockfile.
2. **Atomic write.** `mkstemp` in `docs/` + `rename` to `_architect_state.lock`. Never write directly.
3. **Stale window: 30 minutes.** If `now - acquired_at > 30 min`, lock is stale — offer the user: `"Stale lock from pid X on host Y (acquired 47 min ago). Clear and continue? (y/n)"`.
4. **Live lock, same host, pid alive** (`now - acquired_at <= 30 min` AND `host` matches AND `kill -0 <pid>` succeeds): refuse with `"Another project-architect session appears to be running (pid X). If this is wrong, delete docs/_architect_state.lock and retry."`.
5. **Live lock, different host or dead pid:** treat as stale; offer to clear.
6. **Release at clean exit.** Phase 6 cleanup deletes the lockfile only — the state file is preserved (v2.1.5 fix — bug #14, required for cross-session resume and `/iterate-design` in v2.2). Any other phase's clean exit also deletes only the lockfile.
7. **Mirror.** Whenever the lockfile is written, also update `state.lock`. The file is canonical for cross-process coordination; the field is informational.

---

### Programming language project sub_types (added v2.3 — Sketch F)

Specialised sub_types for `project.sub_type` when the user is designing a new programming language. The 6 variants partition the design space by intended scope/audience; they gate the v2.3 family of PL design templates (LANGUAGE_GRAMMAR, SEMANTICS, TYPE_SYSTEM, STDLIB, TOOLCHAIN, BOOTSTRAP_PLAN, STABILITY_AND_RFC).

| sub_type | Description | Exemplars |
|---|---|---|
| `general_purpose_language` | Broad, full-featured language. Needs stdlib, type system, GC/ownership, full toolchain. | Rust, Go, Python clone |
| `domain_specific_language` | Narrow grammar; embedded use or standalone. | HCL, regex, Terraform-class |
| `query_language` | Declarative data querying; needs schema model + optimizer. | SQL/GraphQL/OQL dialects |
| `configuration_language` | Total functions, hermetic; type system + import semantics. | Nix, Dhall, CUE, Jsonnet |
| `educational_language` | Teaching tool; minimal stdlib, clarity over performance. | Crafting Interpreters-class, BF clone |
| `transpiler_target` | Compiles to existing language; needs host-language interop. | TypeScript→JS, Elm→JS, CoffeeScript |

### Programming language decisions (added v2.3 — Sketch F)

When `project.sub_type` is one of the PL variants above, four additional decision axes are recorded in `state.decisions`. Enum values are normative — agents and templates assume these exact strings.

#### `impl_strategy` — how the language is implemented in v0.1

| Value | When to pick |
|---|---|
| `tree_walking_interpreter` | Simplest path; educational or DSL bootstrapping. |
| `bytecode_vm` | Moderate complexity; custom VM, portable. |
| `native_compiler` | Highest performance; AOT to machine code. |
| `transpiler` | Compiles to existing language; fastest path to "real" language. |
| `hosted_embedded` | DSL inside a host language (Lua-in-C-style). |

#### `host_runtime` — what runs the compiled/interpreted code

Research-informed enum as of 2026-05-13 (see plan preamble for citations). 14 values; choose by use-case fit, not by familiarity.

| Value | When to pick (2026 status) |
|---|---|
| `llvm` | Industrial default (LLVM 22.x stable); broadest target coverage. |
| `mlir` | Accelerator-friendly (GPU/FPGA/TPU/quantum); dialect-driven design. Mojo proves general-purpose viability. |
| `cranelift` | Wasm runtimes or fast-debug-build Rust codegen (production for Wasm/JIT). |
| `qbe` | Small-backend alternative (~14 kLOC C); teaching/bootstrap. x86-64/aarch64/riscv64 only. |
| `truffle` | Host a new language on GraalVM (24/25 LTS) — free JIT + Native Image + polyglot. |
| `jvm` | Target JVM bytecode directly (Java 25 LTS). |
| `beam` | Functional/actor-shaped languages only (Gleam exemplar). |
| `wasm` | Raw Wasm 3.0 target (W3C standard since Sept 2025: WasmGC + EH + tail calls + multi-memory). |
| `wasm_component` | Component Model target for cross-component composition (WASI 0.2 stable; 0.3 RC). |
| `js_host` | Compile to JavaScript for web embedding or polyglot piggyback. |
| `python_embedded` | DSL inside Python 3.14+ — prototyping/education. (No-GIL opt-in only.) |
| `rust_host` | Embedded DSL in Rust — proc-macro or runtime interpreter. |
| `native_no_runtime` | Hand-rolled native codegen; expert-only. |
| `custom_vm` | Hand-rolled bytecode VM; teaching/niche. |

#### `paradigm` — primary programming paradigm

| Value | Examples |
|---|---|
| `imperative` | C, Go |
| `functional` | Haskell, OCaml |
| `logic` | Prolog, miniKanren |
| `oop` | Smalltalk, Java |
| `multi_paradigm` | Rust, Scala, Swift |
| `data_oriented` | Clojure, APL |

#### `type_system` — primary static-analysis stance

| Value | Description |
|---|---|
| `static_strong` | Statically typed, no implicit coercion. Rust, Haskell, OCaml. |
| `static_gradual` | Static with opt-in/opt-out gradual typing. TypeScript, Python+mypy. |
| `dynamic` | Runtime types only. Python, Ruby, JavaScript. |
| `dependent` | Types depend on values. Lean 4 (closest to general-purpose 2026), Idris 2 (research), Agda (research). |
| `affine_linear` | Linear or affine resource types. Rust ownership, Linear Haskell. |
| `none_untyped` | No types (untyped lambda calc, Forth). |

---

## Migration policy

At startup, compare `state.schema_version` against the current plugin's expected schema:

| Comparison | Action |
|---|---|
| `state.schema_version == current` | Proceed. |
| `state.schema_version < current` AND entry in [migration table](#migration-table) | Run migration. Save migrated state. Proceed. |
| `state.schema_version < current` AND **no** migration entry | Refuse: `"State file is from incompatible plugin version X.Y; re-run bootstrap fresh or upgrade to a compatible plugin version."` |
| `state.schema_version > current` | Refuse: `"State file (vX.Y) is newer than this plugin (vA.B). Upgrade the project-architect plugin."` |

Each migration step is idempotent (re-running on already-migrated state is a no-op). Migrations chain (e.g., `1.0 → 1.1 → 2.0` runs both steps).

---

## Migration table

Currently empty: `2.0` is the first schema version using this layout.

| From | To | Steps |
|---|---|---|
| _(none yet)_ | _(none yet)_ | — |

**Convention for future entries:** one row per `from → to` pair. The `Steps` column lists field-level operations (add / remove / rename / re-type / default-fill). Keep each step idempotent. Example (illustrative): `2.0 → 2.1`: (1) add `phase_progress.phase_4.docs_remaining` default `[]` if absent; (2) rename `git.has_remote` → `git.remote_configured`.

---

## Revision Log

(none yet)

---

*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
