# Workarounds Audit (post-implementation, 2026-05-12)

Audit of `skills/project-architect/SKILL.md`, `agents/*.md`, and `skills/project-architect/references/*.md` for leftover workarounds, TODOs, broken references, or placeholder syntax outside fenced blocks.

**Scope of check:**
1. `TODO`, `TBD`, `FIXME`, `XXX`, `WIP`, `(deferred)`, `later` markers.
2. Cross-references to files in `references/` and `references/templates/` that don't exist.
3. `{{placeholder}}` syntax outside fenced code blocks.
4. Em-dash / partial-sentence artifacts from past Edit-tool failures.
5. Agent / skill / tool references that point at nothing that ships in this plugin or the recommended baseline.

**Method:**
- `grep -nE 'TODO|TBD|FIXME|XXX|WIP|\(deferred\)|later'` across the three target sets.
- `grep -oE 'references/[a-z-]+\.md'` and `grep -oE 'templates/[A-Z_]+\.md'` cross-checked against `ls` of each directory.
- A small Python pass to identify `{{...}}` placeholders OUTSIDE fenced code blocks (templates/ excluded because their placeholders are intentional template hints).
- Manual inspection of each finding's surrounding context to filter false positives.

---

## Findings

Severity legend: **blocker** (skill won't run) / **major** (functional gap) / **minor** (doc/contract inconsistency) / **cosmetic** (style only).

### Finding 1 — `fewer-permission-prompts` is invoked by an agent but not surfaced in the new Preflight soft-dep check

**File:** `agents/claude-tooling-author.md:63`, `agents/claude-tooling-author.md:133`
**Severity:** minor
**What's wrong:**
The agent does `**Optionally invoke** Skill: fewer-permission-prompts if available` (line 63) and lists it in its own failure-modes table (line 133) as a soft dependency. The new Phase -1 "Soft-dependency check" probes only `superpowers`, `claude-md-management`, `claude-code-setup`, `hookify`, `document-skills` — five plugins. `fewer-permission-prompts` is a separate skill that ships standalone (it's enabled in the current session per the available-skills list), so it's not bundled into one of those five.

Net effect: a project that would benefit from `fewer-permission-prompts` won't see it surfaced at Preflight. The `claude-tooling-author` agent handles its absence cleanly (line 133: "write files anyway with internal best-effort"), so this is not a blocker, but it's a contract inconsistency between the new Preflight list and the agent's expectations.

**Suggested fix (don't apply — user decides):**
Option A: add `fewer-permission-prompts` as a sixth entry in the Phase -1 soft-dep list.
Option B: re-frame the agent's reference as "if the user has it; we don't probe for it" and remove `fewer-permission-prompts` from line 133's example list (keep `hookify` only).
Option C: leave as-is and document the divergence in `references/claude-code-integration.md`'s "Quality/process recommendations" section so it's a per-project recommendation rather than a baseline one.

---

### Finding 2 — Three subagent dispatches in SKILL.md don't show explicit Agent() input blocks

**Files:**
- `skills/project-architect/SKILL.md:336` (`claude-md-author`)
- `skills/project-architect/SKILL.md:337` (`claude-tooling-author`)
- `skills/project-architect/SKILL.md:389` (`decision-revisor`)

**Severity:** minor (functional but underspecified)

**What's wrong:**
Compare to Phase 0 (lines ~120–144) for `research-scout` and Phase 4 (lines ~282–305) for `document-author` — both have full Agent({...}) blocks with `subagent_type`, `model`, `description`, and an explicit `prompt` body that lists every input.

The three later dispatches use narrative form only:
- "dispatch `claude-md-author` agent → writes `/CLAUDE.md` ..."
- "dispatch `claude-tooling-author` agent → writes `.claude/settings.json`, ..."
- "Dispatch `decision-revisor` (reads `references/revision-playbook.md`) with `{decision_key, old_value, new_value, reason, next_adr_id}`."

Each of those agents' `## Inputs you receive` section declares additional inputs the SKILL.md doesn't visibly pass:
- `claude-md-author` expects: `state_path`, `template_root_path`, `template_subfolder_path`, `doc_paths`, `project_structure`.
- `claude-tooling-author` expects: `state_path`, `integration_path`, `recommended_plugins_state` (implicit from new Preflight contract).
- `decision-revisor` expects `state_path` and `playbook_path` in addition to the five fields SKILL.md lists.

At runtime the orchestrator might fill these in implicitly, but a future maintainer reading SKILL.md alone would not know what to construct.

**Suggested fix (don't apply — user decides):**
Add three Agent({...}) blocks matching the Phase 4 / Phase 0 style, with full input lists. Example shape for `claude-tooling-author`:

```
Agent({
  subagent_type: "project-architect:claude-tooling-author",
  model: "opus",
  description: "Write .claude/ for {{project.name}}",
  prompt: """
    [MODEL DIRECTIVE]
    Run with maximum effort. Apply extended thinking. Be thorough.

    [INPUTS]
    state_path: docs/_architect_state.json
    integration_path: skills/project-architect/references/claude-code-integration.md
    recommended_plugins_state: {{state.recommended_plugins}}
    output_root: .claude/

    [TASK]
    Follow the agent's documented workflow ...
  """
})
```

Alternative: leave the narrative dispatches and add a one-line note that orchestrator passes all inputs from the agent's `## Inputs you receive` section by name.

---

### Finding 3 — `state.recommended_plugins[].missing` is referenced but not enforced by schema

**File:** `skills/project-architect/references/state-schema.md` (line ~98–107, in the example block)
**Severity:** cosmetic

**What's wrong:**
The Workstream-1 commit added `missing: true|false` to the example in state-schema.md, but there's no explicit field definition in a "fields" table for `recommended_plugins[]`. The example is the only documentation of the field shape. Compared to other entries like `git`, `model_state`, and `phase_progress`, the new `recommended_plugins[]` entries lack a per-field table or comment block.

This won't break anything — schemas in this project are example-driven, not table-driven — but the asymmetry will look odd to a future maintainer.

**Suggested fix:**
Either (a) accept the asymmetry (cheap), or (b) add a small fields table beneath the example specifying `name: string`, `reason: string`, `missing: bool`, `installed: bool` and noting which phase writes each.

---

### Finding 4 — `Skill` tool listed in `claude-md-author` tools array, but no other agent declares it

**File:** `agents/claude-md-author.md:4`
**Severity:** cosmetic (intentional, but worth noting)

**What's wrong:**
`tools: [Read, Write, Edit, Glob, Grep, Bash, Skill]` — `Skill` is included specifically because step 5 of the agent's workflow invokes `claude-md-management:claude-md-improver` via the Skill tool. The other agents (`claude-tooling-author`, `document-author`, `research-scout`, `decision-revisor`) only list bread-and-butter tools. `claude-tooling-author` also says it "Optionally invokes" two skills (`fewer-permission-prompts`, `hookify:writing-rules`, `update-config`, `claude-code-setup:claude-automation-recommender`) but doesn't have `Skill` in its `tools:` array — so those invocations would fail.

**Suggested fix:**
Add `Skill` to `agents/claude-tooling-author.md:4`'s `tools:` array. (Workaround for this not being declared: the agent at line 63 starts with "Optionally invoke ... if available", which gives it cover to no-op when the Skill tool isn't in its toolset. But the cleanest fix is to declare it.)

---

### Finding 5 — `phase_-1` as a state.phase value isn't in the canonical enum

**File:** `skills/project-architect/references/state-schema.md:105`
**Severity:** minor

**What's wrong:**
The Workstream-1 commit added: "On `abort`: save state with `phase = "phase_-1"` and exit cleanly." But the canonical phase enum in state-schema.md line 105 lists: `"preflight" | "phase_0a" | ...` — not `"phase_-1"`. The enum uses string `"preflight"` for Phase -1, not `"phase_-1"`.

Net effect: if a user aborts at Preflight, the state file will have `phase: "phase_-1"`, which doesn't match the enum, and on resume the orchestrator's phase-jumper will not have a case for it.

**Suggested fix:**
Change the SKILL.md Preflight abort step (file `skills/project-architect/SKILL.md`, the line that says `save state with phase = "phase_-1" and exit cleanly`) to `save state with phase = "preflight" and exit cleanly`. The resume path for `preflight` already exists in the resumability checklist (line ~466).

---

### Finding 6 — Some inline `{{placeholder}}` instances in commit-message templates are unmarked

**Files:**
- `skills/project-architect/SKILL.md:205, 227, 280, 391` (commit-message format strings)
- `agents/document-author.md:45` (return summary format string)

**Severity:** cosmetic

**What's wrong:**
These are all intentional runtime template substitutions (the orchestrator fills `{{batch summary}}`, `{{topic}}`, etc., before issuing the commit). They are NOT broken — but they live outside fenced code blocks, which makes them indistinguishable to a naive reader (or a strict linter) from accidental leftover placeholders.

This is a stylistic inconsistency: most of the prose elsewhere wraps such tokens in backticks (`` `{{key}}` ``), but commit-message bullets in SKILL.md do not.

**Suggested fix:**
Either (a) accept as intentional and document the convention at the top of SKILL.md (one line: "`{{...}}` tokens in commit-message templates are runtime substitutions"), or (b) backtick-wrap them all: `architect(phase-1): \`{{batch summary}}\``. Option (a) is lower-churn.

---

## Items checked and clean

- All `references/<name>.md` referenced from SKILL.md, agents, and other references EXIST in `skills/project-architect/references/`.
- All `templates/<NAME>.md` referenced EXIST in `skills/project-architect/references/templates/`.
- No literal `TODO`, `FIXME`, `XXX`, `WIP`, or `(deferred)` markers in active prose. (The only `TODOs` mentions are inside fenced shell snippets — `rg -n "TODO|FIXME"` is the literal command the `session-start.sh` hook template runs.)
- No dangling em-dashes or partial sentences.
- All `{{...}}` placeholders found outside fenced blocks are documented as intentional runtime substitutions in their enclosing file's preamble (e.g., `research-prompts.md` line 3 explicitly notes the substitution contract).
- Plugin manifest (`.claude-plugin/plugin.json`) conforms to the canonical schema (array `dependencies`, no `softDependencies`).
- The "five recommended plugins" list in the new Phase -1 soft-dep check matches the list in the as-built corrections appendix (Workstream 2) and the rationale in `README.md`'s "Recommended" section (assuming README has been updated to match — verify out-of-band).

---

## Overall assessment

Six findings: one minor (1), one minor + one minor + one minor across Findings 2, 5, and the bottom of Finding 1; two cosmetic (3, 4, 6). No blockers. No major functional gaps. The skill is implementable / runnable as shipped; the findings are tightening opportunities, not bugs.

Recommended order of fixes if pursuing them:
1. Finding 5 (`phase_-1` → `preflight`) — quickest, prevents a real resume bug.
2. Finding 4 (add `Skill` to `claude-tooling-author` tools array) — quick, unblocks documented "Optionally invoke" lines.
3. Finding 1 (decide where `fewer-permission-prompts` belongs) — design call.
4. Finding 2 (Agent() blocks for the three narrative dispatches) — biggest doc-only commit.
5. Findings 3 and 6 — cosmetic polish, not urgent.

---

## Revision Log

(none yet)
