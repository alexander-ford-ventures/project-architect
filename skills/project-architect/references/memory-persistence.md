<!--
Author: Alexander Ford <alex@pseudo-lang.com>
License: MIT
Project: project-architect (https://github.com/alexander-ford-ventures/project-architect)
-->

# Memory Persistence Reference (v2.2, sketch D)

How project-architect writes per-phase progress notes to the user's persistent memory file so future Claude sessions can resume context.

---

## Why memory persistence

A multi-day project-architect run spans multiple Claude Code sessions. Without persistent notes:

- Each fresh session starts cold (re-reads `docs/_architect_state.json` + reconstructs context from generated docs)
- The user has to re-explain context if the agent drifts
- Decisions made in earlier sessions can be forgotten between phases
- `/iterate-design` (v2.2) has no narrative record of *why* earlier decisions were made — only the locked state

Per-phase memory writes keep a running log of "what was decided, when, why" in the user's `~/.claude/projects/<project>/memory/<project_slug>.md` file, indexed by `MEMORY.md`. The state file remains the canonical machine-readable record; the memory file is the human-readable narrative.

---

## Memory file location

The orchestrator writes to:

```
~/.claude/projects/<project-id>/memory/project_architect_<project_slug>.md
```

Where:

- `<project-id>` is Claude Code's project directory (the actual filesystem path Claude is in, slugified by Claude Code itself)
- `<project_slug>` is a slug of `state.decisions.project.name` (e.g., `md2pdf-cli`, `ledger-app`); lowercased, non-alphanumeric collapsed to `-`, trimmed

Pointer to this file is stored in `state.memory_pointer` (see `state-schema.md`). Subsequent phases Edit this same file rather than re-resolving the slug each time — the resolved path is canonical for the run.

---

## Cadence — when to write

The write cadence (one entry per phase boundary) is summarized in the table below; each phase's entry is appended at the moment the phase transitions to `complete = true` in `state.phase_progress`.

| Phase | Action | Content |
|---|---|---|
| Phase 0a | **Create** the memory file; append index entry to `MEMORY.md` | Project name, elevator pitch, `started_at`, link to `docs/_architect_state.json` |
| Phase 1 | **Update** with domain research summary + scope/feasibility framing | 2-3 sentence summary + research findings file path |
| Phase 2 | **Update** with chosen scope + key constraints | What's in/out of scope; load-bearing constraints |
| Phase 2.5 | **Update** with stack gotchas + cost model | Per-language gotchas snapshot |
| Phase 3 | **Update** with chosen tech stack + ADR-0001 thru ADR-0005 ids | Stack decisions + ADR file paths |
| Phase 4 | **Update** with generated docs list + quality-gate audit result | Doc count, audit summary (BLOCKER / WARNING / INFO counts) |
| Phase 5 | **Update** each revision wave (one entry per major decision change) | What changed, why, ADR cross-ref |
| Phase 6 | **Major update**: write "LOCKED at v1.0" header + design summary | Final ADR list, `locked_at`, full doc count |
| Phase 7 | **Update** with execution outcome (what was generated, what was skipped) | `CLAUDE.md` y/n, `.claude/*` y/n, scaffold y/n |
| Phase 8 | **Final update** with handoff summary + next-step recommendations | Closing entry; future sessions can grep here |

Each write is **append-only** — the orchestrator never rewrites a prior entry. If Phase 5 revises a Phase 3 decision, Phase 5 appends a new entry that cross-references the original; the original stays put.

---

## Memory entry template

Each entry uses this shape:

```markdown
## <Phase N name> — <ISO8601 timestamp>

<2-3 sentence summary of what happened in this phase.>

**Decisions made:**
- <decision 1> (ADR <NNNN>)
- <decision 2> (ADR <NNNN>)

**Files generated/modified:**
- <file path>

**Open questions:**
- <if any>

**Next:** <what the next phase will do>

---
```

Notes:

- The `<ISO8601 timestamp>` is the canonical `date -u +"%Y-%m-%dT%H:%M:%SZ"` value (matches `state.last_updated_at` at the time of write).
- "Decisions made" cross-references ADR ids when relevant; pre-ADR phases (0a, 1) may have none.
- "Open questions" is omitted when empty.
- The trailing `---` separates entries visually.

---

## MEMORY.md index format

The user's `MEMORY.md` (one level up from the per-project memory file) gets one line per memory file. project-architect appends:

```markdown
- [project-architect: <project name>](project_architect_<slug>.md) — <one-line elevator pitch>, locked at <version> (<locked_at>)
```

If the project is still in design (not locked), the suffix is `— in design (last update: <phase>)`. The orchestrator updates this single line on each phase boundary; the index never grows multiple lines per project.

If `MEMORY.md` does not exist when Phase 0a runs, the orchestrator creates it with a minimal header and the first entry.

---

## state.memory_pointer field

After the Phase 0a write, the orchestrator records the memory file path in `state.memory_pointer`. See `state-schema.md` for the schema. Subsequent phases Edit this file directly (not re-resolve the slug).

---

## Conflict resolution

If `state.memory_pointer` is non-null at startup but the pointed-to file is missing or moved:

1. Regenerate the file from `state.json` content (best-effort reconstruction of past entries from `phase_progress`, `decisions`, `adrs_filed`)
2. Append a one-line entry to `MEMORY.md` if its line is missing
3. Update `state.memory_pointer.last_synced` to the regeneration timestamp
4. Continue the current phase as normal

The `MEMORY.md` index is the source of truth for "which memory files exist"; the per-file content is the source of truth for "what happened in this project-architect run". If both are missing, the orchestrator falls back to writing fresh as if from Phase 0a (no harm — append-only).

---

## Cross-references

- State field schema: `references/state-schema.md` § `memory_pointer`
- Phase boundaries that trigger writes: `SKILL.md` Phases 0a, 1, 2, 2.5, 3, 4, 5, 6, 7, 8
- `/iterate-design` workflow reads the memory file to seed the diff prompt: `commands/iterate-design.md` (v2.2)

---

*★ Skillfully made with [project-architect](https://github.com/alexander-ford-ventures/project-architect).*
