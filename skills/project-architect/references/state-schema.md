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
| Phase 6 cleanup | Delete `state.json` AND `_architect_state.lock`, then commit (`chore: clean up bootstrap state`). |
| Clean exit (any phase) | Release lock (delete `_architect_state.lock`); leave `state.json` for next resume. |

To re-bootstrap: delete `state.json` and re-invoke. Existing generated docs become reference material — the orchestrator diffs and asks rather than overwriting.

---

## Schema

```jsonc
{
  // Versioning
  "schema_version": "2.0",                  // String. Bumps when this schema changes. Drives migration.
  "plugin_version": "2.0.0",                // String. semver of the plugin that wrote this state.
  "started_at": "2026-05-12T14:00:00Z",     // ISO8601 UTC. Set at file creation.
  "last_updated_at": "2026-05-12T16:30:00Z",// ISO8601 UTC. Rewritten on every save.

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

  // Plugin recommendations (resolved during Phase 6)
  "recommended_plugins": [{ "name": "hookify", "reason": "...", "installed": false }],

  // Concurrency guard. Mirror of _architect_state.lock; the file is canonical.
  "lock": { "pid": 42, "host": "macbook-air", "acquired_at": "..." }
}
```

**Phase enum:** `"preflight" | "phase_0a" | "phase_0" | "phase_1" | "phase_2" | "phase_2.5" | "phase_3" | "phase_4" | "phase_5" | "phase_6" | "phase_7" | "complete"`

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
| `phase_7` | `complete`, `handoff_invoked` (bool) | If handoff invoked, do not re-invoke. |

`completed_at` is ISO8601 UTC. `*_remaining` arrays shrink as work completes; all other arrays are append-only.

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
6. **Release at clean exit.** Phase 6 cleanup deletes BOTH state file and lockfile. Any other phase's clean exit deletes only the lockfile.
7. **Mirror.** Whenever the lockfile is written, also update `state.lock`. The file is canonical for cross-process coordination; the field is informational.

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
