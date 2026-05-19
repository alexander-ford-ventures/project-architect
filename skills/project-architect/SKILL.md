---
name: project-architect
description: Use when the user wants to set up a new project, scaffold project docs, plan a new project, initialize project architecture, bootstrap with planning documents, design a system architecture, choose a tech stack, revisit existing project architecture decisions, or generate CLAUDE.md and .claude/ config for an existing project. Works for any project type — web apps, mobile, multi-platform, APIs, CLI tools, libraries, desktop, browser extensions, games, AI/ML, data pipelines, embedded/IoT, infrastructure, Claude Code plugins, MCP servers, Web3, scientific code, AR/VR, programming language design.
---

<!--
Author: Alexander Ford <alex@pseudo-lang.com>
Repository: https://github.com/alexander-ford-ventures/project-architect
License: MIT
-->

# Project Architect

You orchestrate an 11-phase project bootstrap (preflight → 0a repo init → 0 universal kickoff → 1 vision → 2 tech stack → 2.5 cost → 3 architecture → 4 doc + plan generation → 5 iteration → 6 LOCK → 7 tooling execution → 8 handoff). You do not do the heavy lifting yourself — you dispatch subagents, invoke skills, and synthesize. Load references on-demand from `references/`.

## Phase order

```
-1. Preflight              — model + effort + 1M-context verification
 0a. Repo Init (optional)  — git init + remote
 0.  Universal Kickoff     — Q1–Q8 + first research dispatch
 1.  Vision & Scope        — type-specific drill-down + research + universal CLI-UX gate
 2.  Tech Stack            — type-aware options + per-language CLI-UX picker + ADR per major decision
 2.5 Cost Modeling         — pricing research → COST_MODEL.md draft
 3.  Architecture          — per-area drill-downs + inline consistency check
 4.  Document Generation   — parallel agent dispatch (design docs + 4 plan docs) + quality-gate-auditor
 5.  Iteration             — decision-revisor loop, auditor-seeded menu, snapshot option
 6.  Post-Generation Setup — commit/push, plugin install offers, LOCK v1.0 (state.locked = true)
 7.  Tooling Execution     — menu: execute CLAUDE_MD_PLAN / CLAUDE_TOOLING_PLAN / hand off SCAFFOLD_PLAN to superpowers
 8.  Handoff               — print restart instructions; future sessions auto-load CLAUDE.md router
```

## State

Persistent across the bootstrap: `docs/_architect_state.json`. Schema, lockfile protocol, and migration policy are documented in `references/state-schema.md`. Save after every batch, every agent dispatch, every commit. **Never deleted by the orchestrator** (v2.1.5 fix — bug #14): the state file is the canonical cross-session entry point and must persist past Phase 6 for re-invocations and (in v2.2) for `/iterate-design`.

Lock file: `docs/_architect_state.lock` with `{pid, host, acquired_at}`. Held throughout the session. If a stale lock (>30 min old) exists at startup, offer to clear it.

## Resumability

If `docs/_architect_state.json` exists at startup, read it, validate `schema_version`, print a resume summary, and jump to `state.phase`. If schema version is older than current plugin version, migrate (or refuse with a clear message).

### Resume from locked state (v2.2 — sketch D)

If `state.locked == true` at startup, the design is at a named version (e.g., `v1.0`). The orchestrator does NOT silently re-enter Phase 5 — that would risk overwriting locked decisions. Instead, surface the locked status to the user and offer three explicit options:

```
This project's design is locked at {{state.version}} (locked at {{state.locked_at}}).

What would you like to do?
  (a) Unlock and revise — bump to {{state.version}}+0.1-draft, re-enter Phase 5
  (b) Open the v1.0 snapshot for reference (read-only)
  (c) Exit — no changes
```

On **(a) Unlock and revise**:
- Snapshot the currently-locked docs to `docs/versions/{{state.version}}/` BEFORE unlocking (preserves the immutable lock-point so the user can always diff against it).
- Set `state.locked = false`.
- Set `state.version = "<previous>+0.1-draft"` (e.g., `"v1.0" → "v1.1-draft"`).
- Set `state.locked_at = null`.
- Re-enter Phase 5 with all prior ADRs and docs intact; the user revises in place.
- When the user re-locks at end of Phase 6, version becomes `<previous>+0.1` without the draft suffix (e.g., `"v1.1-draft" → "v1.1"`), and re-snapshot the new locked docs to `docs/versions/{{new_version}}/`.

On **(b) Open the v1.0 snapshot for reference (read-only)**:
- Surface the path `docs/versions/{{state.version}}/` and list its top-level files. Do not modify state. Do not enter any phase. Exit cleanly.

On **(c) Exit**:
- Save no changes. Release the lockfile and exit.

This is also the path that the `/iterate-design` slash command takes (see `references/templates/SLASH_ITERATE_DESIGN.md` template). When `/iterate-design` is invoked on a locked project, it short-circuits directly to option (a) without re-prompting.

---

## Phase -1: Preflight

### Ambient hooks tolerance

Runs FIRST in Preflight so the `remember` plugin's PostToolUse hook (if installed) sees its log directory exist starting from its very first invocation, avoiding any transient hook-error noise in the user's transcript during the rest of Preflight.

Silently pre-create `.remember/logs/` in cwd so the `remember` plugin's PostToolUse hook (if installed) can write its error log without erroring out. Run as `Bash`:

```bash
mkdir -p .remember/logs 2>/dev/null || true
```

The `|| true` ensures failure never blocks Preflight — the architect doesn't depend on this directory. This is a courtesy to a separate plugin and is harmless when `remember` isn't installed (the dir is empty + listed in `.gitignore` by Phase 0a). It lives in Preflight (not Phase 0a) because the hook fires on the first Bash/Read call regardless of whether the user opts into git init. PostToolUse hooks fire AFTER the tool completes, so the very first `mkdir` call's hook sees the directory already created by that same call, and every subsequent tool call is clean.

### Model/effort verification

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

### Soft-dependency check

Claude Code's plugin schema only supports hard `dependencies`; there is no declarative soft / recommended-plugin field. We surface recommended plugins via a runtime probe here so missing ones are obvious before Phase 0.

Recommended plugins (qualified names): `superpowers`, `claude-md-management`, `claude-code-setup`, `hookify`, `document-skills`, `fewer-permission-prompts`.

1. For each recommended plugin, probe installation:
   ```bash
   claude plugin list 2>/dev/null | grep -i "<plugin>" \
     || ls ~/.claude/plugins/cache 2>/dev/null | grep -i "<plugin>"
   ```
   Treat a non-empty match as installed.
2. For each missing plugin, emit one line to the user, e.g.:
   - `superpowers` — `claude plugin install superpowers` — used by Phase 4 doc-gen (`superpowers:dispatching-parallel-agents`) and Phase 7 (`superpowers:writing-plans`).
   - `claude-md-management` — `claude plugin install claude-md-management` — used by the `claude-md-author` agent.
   - `claude-code-setup` — `claude plugin install claude-code-setup` — used by the `claude-tooling-author` agent for `.claude/` scaffolding.
   - `hookify` — `claude plugin install hookify` — used by `claude-tooling-author` when generating project hooks.
   - `document-skills` — `claude plugin install document-skills` — used by `document-author` for diagrams / artifacts.
   - `fewer-permission-prompts` — `claude plugin install fewer-permission-prompts` — used by `claude-tooling-author` to tighten the generated `.claude/settings.json` permissions allowlist.
3. If any are missing, ask once via `AskUserQuestion` (load via `ToolSearch` if needed):
   > "Continue with current plugins? (yes / install missing now / abort)"
4. On `install missing now`: run each `claude plugin install <plugin>` sequentially; on each install failure, record and surface but do not abort the whole batch.
5. On `yes`: for every plugin still missing, append its name to `state.recommended_plugins[].missing`. The `claude-tooling-author` agent reads this in Phase 4 when generating `.claude/recommended-plugins.md` so the user's runtime choices are reflected in the final doc.
6. On `abort`: save state with `phase = "preflight"` and exit cleanly.

Skip the prompt entirely if every recommended plugin is already installed; just record `state.recommended_plugins[]` with `missing: false` for each and proceed silently.

### Version freshness check

Detect if the loaded skill is older than the latest release at the source repo, so users running a stale cache are warned and offered a refresh path. Best-effort: network errors, missing `gh`, or no published releases all degrade silently.

1. **Read the loaded version** from this plugin's own manifest. Claude Code exposes the install path via `${CLAUDE_PLUGIN_ROOT}`:

   ```bash
   LOADED=$(jq -r .version "${CLAUDE_PLUGIN_ROOT:-/dev/null}/.claude-plugin/plugin.json" 2>/dev/null || echo unknown)
   ```

2. **Read the latest released version** from the source repo. Try `gh` first (fastest, lowest rate-limit impact), then fall back to the public GitHub Releases API via `curl` (no auth needed for public repos):

   ```bash
   # Try gh first (fastest, lowest rate-limit impact)
   LATEST=$(gh release view --repo alexander-ford-ventures/project-architect --json tagName --jq .tagName 2>/dev/null | sed 's/^v//')
   # Fall back to public GitHub API via curl (no auth needed for public repos)
   if [ -z "$LATEST" ]; then
     LATEST=$(curl -fsSL --max-time 5 https://api.github.com/repos/alexander-ford-ventures/project-architect/releases/latest 2>/dev/null \
                | jq -r '.tag_name // empty' 2>/dev/null \
                | sed 's/^v//')
   fi
   LATEST="${LATEST:-unknown}"
   ```

3. **Compare** with semver-style ordering:
   - If `LOADED == LATEST` OR either is `unknown`: proceed silently.
   - If `LOADED < LATEST`: surface a one-time notice:

     > Loaded version v{{LOADED}} — a newer release v{{LATEST}} is available.
     >
     > To update (Claude Code with slash commands — recommended):
     >   `/plugin`                  → detects + downloads the update
     >   `/reload-plugins`          → applies it to the current session
     >
     > Fallback (older Claude Code without `/plugin` slash command):
     >   `claude plugin marketplace update <marketplace>`
     >   `claude plugin uninstall project-architect@<marketplace>`
     >   `claude plugin install project-architect@<marketplace>`
     >   `/reload-plugins`          (in this Claude session)
     >
     > Continue with v{{LOADED}} for this run? (yes / pause to update)

     If "pause to update": exit cleanly with state saved. If "yes": proceed and record `state.version_warning_acknowledged = true` so the warning doesn't repeat on the next phase.

4. **Skip the check** silently if:
   - `${CLAUDE_PLUGIN_ROOT}` is unset (rare; older Claude Code versions).
   - `curl` is not installed AND `gh` is not authenticated.
   - The repo has no releases yet.
   - Network is unreachable.

The check is best-effort and non-blocking. The architect's correctness does not depend on running the absolute latest version — this is purely a user-experience nudge so cache-staleness bugs (like loading v1 SKILL.md when v2 has shipped) surface immediately rather than mid-interview.

### Cache hygiene

Remove stale plugin-cache version directories so future invocations can't accidentally load an older copy. The architect knows its own install path via `${CLAUDE_PLUGIN_ROOT}`; sibling directories under the same plugin folder that aren't the current version are leftover from prior uninstall/install cycles.

```bash
# CLAUDE_PLUGIN_ROOT points at the *installed* version dir, e.g.
#   ~/.claude/plugins/cache/local/project-architect/2.0.1
# Its parent is the plugin folder containing every version that was ever installed.
if [ -n "${CLAUDE_PLUGIN_ROOT}" ]; then
  CURRENT_VERSION_DIR=$(basename "${CLAUDE_PLUGIN_ROOT}")
  PLUGIN_PARENT_DIR=$(dirname "${CLAUDE_PLUGIN_ROOT}")
  if [ -d "${PLUGIN_PARENT_DIR}" ]; then
    find "${PLUGIN_PARENT_DIR}" -mindepth 1 -maxdepth 1 -type d ! -name "${CURRENT_VERSION_DIR}" -exec rm -rf {} + 2>/dev/null || true
  fi
fi
```

Best-effort:
- Only acts when `${CLAUDE_PLUGIN_ROOT}` is set (older Claude Code versions: skip).
- Only removes sibling directories at the same depth — never touches files outside the plugin folder.
- `|| true` so failure never blocks Preflight.

After this step, if the freshness check found a newer version available but the user chose to continue, the cache for this specific plugin contains only the currently-loaded version — no ambiguity about which version a future session would load.

### State file initialization

If `docs/_architect_state.json` does not exist, initialize it. Use exactly this template — the literal `"schema_version": "2.0"` is REQUIRED (do NOT substitute the plugin version):

```bash
if [ ! -f docs/_architect_state.json ]; then
  mkdir -p docs
  cat > docs/_architect_state.json <<'STATE_EOF'
{
  "schema_version": "2.0",
  "plugin_version": "PLUGIN_VERSION_PLACEHOLDER",
  "started_at": "STARTED_AT_PLACEHOLDER",
  "last_updated_at": "STARTED_AT_PLACEHOLDER",
  "phase": "preflight",
  "decisions": {},
  "phase_progress": {},
  "documents_pending": [],
  "documents_generated": [],
  "adrs_filed": [],
  "next_adr_id": "0001",
  "research_findings": [],
  "recommended_plugins": []
}
STATE_EOF
  # Substitute the placeholders
  PLUGIN_VERSION=$(jq -r .version "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
  STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sed -i.bak "s/PLUGIN_VERSION_PLACEHOLDER/${PLUGIN_VERSION}/" docs/_architect_state.json
  sed -i.bak "s/STARTED_AT_PLACEHOLDER/${STARTED_AT}/g" docs/_architect_state.json
  rm -f docs/_architect_state.json.bak
fi
```

CRITICAL: `schema_version` is the literal string `"2.0"` — never substitute the plugin version into this field. The plugin version goes into `plugin_version`.

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
   Write `.gitignore` with universal defaults (OS files: `.DS_Store`, `Thumbs.db`; editor files: `.idea/`, `.vscode/settings.json`, `*.swp`; env: `.env`, `.env.local`; ambient: `.remember/` — foreign-plugin courtesy, pre-created in Preflight). Stack-specific entries are appended in Phase 6.
5. If remote requested and authed:
   ```bash
   gh repo create "$NAME" --"$VIS" --source . --remote origin --description "$DESC"
   ```
6. Determine branch strategy from prior knowledge (Q4 won't be answered yet — default to `main` for now; revisit if Q4 = "extending"/"rewriting"/"migrating", create `bootstrap/architect-<date>` branch at that point).
7. Set `state.git.repo_init = true`, `state.git.has_remote`, `state.git.remote_url`, `state.git.branch`.
8. Commit via `Skill: commit-commands:commit` with hint message: `chore: initialize project repo`.
9. State: `phase = "phase_0a"`, mark phase complete, save.
10. **Memory persistence:** Create the project memory file at `~/.claude/projects/<project-id>/memory/project_architect_<slug>.md` per `references/memory-persistence.md`. Append one-line entry to `MEMORY.md`. Set `state.memory_pointer = { name, path, last_synced }`.

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
8. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 0 entry (kickoff decisions + domain research summary). If `state.memory_pointer` is null (e.g., user skipped Phase 0a), create it now.

---

## Agent dispatch — observer wrapper (v2.2, sketch C)

Every `Agent({...})` dispatch is wrapped with the runtime-budget observer per `references/runtime-budgets.md`. The observer:
- Records dispatch start/end timestamps in `state.agent_dispatches`
- Surfaces "silent for too long" warnings inline
- Surfaces "over budget" warnings inline
- Pre-populates Phase 5 menu with `"review scope of <agent>"` items for over-budget runs
- **Never auto-kills** the agent — observation only

This is the bug-#9 mitigation (decision-revisor 6× cost overrun). With observation, the user sees the overrun in real time and can `Esc` if appropriate; the orchestrator records the telemetry for future tuning.

---

## Memory persistence (v2.2 — sketch D)

Every phase boundary updates a persistent memory file per `references/memory-persistence.md`. This keeps cross-session continuity for multi-day project-architect runs.

Cadence:
- **Phase 0a** (first write): create `~/.claude/projects/<project-id>/memory/project_architect_<slug>.md`; append one-line entry to `MEMORY.md`; record path in `state.memory_pointer`.
- **Phases 1, 2, 2.5, 3, 4, 5** (per-phase updates): Edit the pointed-to file with a new dated entry summarizing what was decided/generated.
- **Phase 6** (major update): write "LOCKED at v1.0" header + full design summary; update `MEMORY.md` to mark project as locked.
- **Phase 7, 8** (final updates): record execution outcome + handoff summary.

If `state.memory_pointer` is null at startup: this is the first write; create it.
If non-null but the pointed-to file is missing: regenerate from state.json + update `state.memory_pointer.last_synced`.

See `references/memory-persistence.md` for the entry template and `MEMORY.md` index format.

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
5. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 1 entry (domain research summary + scope/feasibility framing).

### CLI sub-question routing (added v2.1.5)

When `state.decisions.project.sub_type` is one of `cli_tool`, `cli_with_subcommands`, `tui_app`, or `interactive_cli`, dispatch the CLI experience-model gate question from `references/questioning-flow.md` (section "CLI experience model"). Save the answer to `state.decisions.cli_experience_model`. Route follow-up questions per the table in that reference.

The per-language CLI-UX library picker (Phase 2) is added in v2.2; for v2.1.5, only the universal gate + universal UX intent questions ship.

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
4. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 2 entry (chosen tech stack + ADR ids).

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
9. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 2.5 entry (stack gotchas + cost model snapshot).

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

End of phase: dispatch `research-scout` with Phase 3 prompt (pattern validation). Commit findings. State: `phase = "phase_4"`, save. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 3 entry (architecture decisions + per-area ADR ids + consistency-check outcomes).

---

## Phase 4: Document Generation

### Phase 4 entry gate (added v2.2 — bug #4 fix)

Before dispatching any document-author agent, verify Phase 3's prerequisites are satisfied:

```bash
PREREQS=$(jq -r '.phase_progress.phase_3.prerequisites_satisfied // false' docs/_architect_state.json)
if [[ "$PREREQS" != "true" ]]; then
  echo "Phase 3 prerequisites not satisfied; cannot enter Phase 4. Check that pattern-validation research has returned."
  exit 1
fi
```

This blocks the live-test bug where `document-author` dispatched in parallel with `research-scout` (pattern validation), causing research findings to land too late to inform doc generation.

Load `references/document-catalog.md` for selection rules and the topological sort key.

1. **Select templates** in two passes:
   - **Pass A — `generate_when` evaluation**: evaluate each template's `generate_when` expression against `state.decisions`. Always-generated + type-anchored + matching conditional templates → `gw_selected` set.
   - **Pass B — ADR `affected_docs` enforcement** (BUG-5 FIX, v2.1.5): compute the **union** of every ADR's `affected_docs` field across `state.adrs_filed`, **intersect** with the template catalog filenames, and **force-include** the result. This guarantees that if an ADR claims a doc as affected, that doc IS generated.

   ```bash
   # Pseudo-code for Pass B (executor: implement using jq + bash):
   ALL_AFFECTED=$(jq -r '.adrs_filed[].affected_docs[]?' docs/_architect_state.json | sort -u)
   CATALOG=$(ls skills/project-architect/references/templates/ | sed 's/\.md$//')
   FORCED=$(comm -12 <(echo "$ALL_AFFECTED" | sort) <(echo "$CATALOG" | sort))
   # Final selected set = gw_selected ∪ FORCED
   ```

   If a doc is in `FORCED` but missing from the catalog (typo in ADR `affected_docs`), surface a WARNING but proceed with the rest. If `FORCED` adds docs not present in `gw_selected`, log them as `affected_docs_only` for audit visibility.

   The final `selected_templates` list is `gw_selected ∪ FORCED`. Topological sort (step 2) operates on the union.
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

6. **In parallel with the last doc batch**, dispatch two agents:

   - `claude-md-author` → writes `/CLAUDE.md` and any per-folder CLAUDE.md.

     ```
     Agent({
       subagent_type: "project-architect:claude-md-author",
       model: "opus",
       description: "Write CLAUDE.md files",
       prompt: """
         [MODEL DIRECTIVE]
         Run with maximum effort. Apply extended thinking. Be thorough.

         [INPUTS]
         state_path: docs/_architect_state.json
         template_root_path: skills/project-architect/references/templates/CLAUDE_MD_ROOT.md
         template_subfolder_path: skills/project-architect/references/templates/CLAUDE_MD_SUBFOLDER.md
         doc_paths: {{list of generated doc filenames from state.documents_generated}}
         project_structure: {{tree from state.decisions[project.structure] or scanned filesystem}}

         [TASK]
         Write the root CLAUDE.md and any subdirectory CLAUDE.md files per the
         agent's documented gating triggers. Run claude-md-management:claude-md-improver
         on each file and iterate until pass. Return a summary listing each file written.
       """
     })
     ```

   - `claude-tooling-author` → writes `.claude/settings.json`, hooks/, agents/, commands/, recommended-plugins.md (see `references/claude-code-integration.md` for stack→skill recipes).

     ```
     Agent({
       subagent_type: "project-architect:claude-tooling-author",
       model: "opus",
       description: "Write .claude/ project config",
       prompt: """
         [MODEL DIRECTIVE]
         Run with maximum effort. Apply extended thinking. Be thorough.

         [INPUTS]
         state_path: docs/_architect_state.json
         integration_path: skills/project-architect/references/claude-code-integration.md
         project_root: {{user project root path}}
         stack_summary: {{parsed summary of language/frontend/backend/db/auth/hosting/testing from state.decisions}}

         [TASK]
         Follow the agent's documented workflow: read the integration recipe library,
         write .claude/settings.json (stack-aware allowlist, hooks), .claude/hooks/*,
         .claude/agents/*, .claude/commands/*, and .claude/recommended-plugins.md.
         Optionally invoke fewer-permission-prompts, hookify:writing-rules, update-config,
         and claude-code-setup:claude-automation-recommender if available. Return a summary
         listing artifact counts.
       """
     })
     ```

7. After both return:
   - Commit CLAUDE.md files: one commit per file or a batch commit `chore: add CLAUDE.md files`.
   - Commit `.claude/` artifacts: `chore: add Claude Code project config`.

8. Push if `state.git.push_strategy == "per_phase"` and `state.git.has_remote`:
   ```bash
   git push origin <branch>
   ```

9. State: `phase = "phase_5"`, save.

10. **Dispatch quality-gate-auditor** (added v2.2, sketch B):

    ```
    Agent({
      subagent_type: "project-architect:quality-gate-auditor",
      model: "opus",
      description: "Phase 4 → Phase 5 audit",
      prompt: """
        [MODEL DIRECTIVE]
        Run with maximum effort. Apply extended thinking. Be thorough.

        [INPUTS]
        project_root: {{user project root}}
        state_path: docs/_architect_state.json
        catalog_path: skills/project-architect/references/templates/
        adr_dir: docs/decisions/

        [TASK]
        Run all 16 checks via run_all.sh. Return the aggregate JSON.
        Do NOT modify any files.
      """
    })
    ```

11. Parse the auditor's JSON output. Save `findings` + `summary` into `state.last_audit`. Save `phase_5_seed_items` into `state.phase_5_seed_items` (consumed by the iteration menu in step seeding below).

12. If `summary.blocker > 0`: do NOT auto-advance to Phase 5. Print the BLOCKER findings and ask the user how to proceed (revise via `decision-revisor` / approve anyway / abort). Only after the user explicitly chooses to continue should the orchestrator enter the Phase 5 menu.

13. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 4 entry (generated doc list + quality-gate audit summary: BLOCKER / WARNING / INFO counts).

---

## Phase 5: Iteration

Print a decision summary AND the auditor's seed items (the seed items come from `state.phase_5_seed_items`; the audit summary comes from `state.last_audit.summary`):

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

QUALITY GATE AUDIT:
  BLOCKER count: {{count}}    WARNING: {{count}}    INFO: {{count}}

  {{for each finding from state.last_audit.findings}}
    [{{severity}}] {{detail}}
       → suggested: {{remediation}}
  {{end}}

What next?
  (auto-seeded from auditor)
  {{for each item in state.phase_5_seed_items}}
    ({{letter}}) {{item.label}}{{ if item.selected_default then " [default — fixes a BLOCKER]"}}
  {{end}}
  ({{next_letter}}) Approve all → Phase 6 (commit + plugin install)
  ({{next}})       Revisit a decision → type its key
  ({{next}})       Snapshot current as v1.0 → docs/versions/v1.0/ and continue
  ({{next}})       Generate the implementation plan → Phase 7
  ({{next}})       Show full decision tree
  ({{next}})       Exit (resume later)
```

### Iteration loop

Use `AskUserQuestion` for the menu.

- **(a) Approve**: break to Phase 6.
- **(b) Revisit**:
  1. Ask: which decision key? (auto-suggest from `state.decisions` keys)
  2. Ask: why (free-form — goes into ADR)
  3. Re-ask the question that produced this decision (with current value as default).
  4. Dispatch `decision-revisor`:

     ```
     Agent({
       subagent_type: "project-architect:decision-revisor",
       model: "opus",
       description: "Revise {{decision_key}}",
       prompt: """
         [MODEL DIRECTIVE]
         Run with maximum effort. Apply extended thinking. Be thorough.

         [INPUTS]
         decision_key: {{decision_key}}
         old_value: {{old_value}}
         new_value: {{new_value}}
         reason: {{user-supplied reason}}
         state_path: docs/_architect_state.json
         playbook_path: skills/project-architect/references/revision-playbook.md
         next_adr_id: {{state.next_adr_id}}

         [TASK]
         Look up decision_key in the playbook's affected-docs map. Surgically rewrite
         only the affected sections in each listed doc; append a revision-log entry
         per doc. File a new ADR at docs/decisions/<next_adr_id>-<slug>.md superseding
         any prior ADR for the same key. Update state.decisions and state.adrs_filed.
         Validate cross-references and return a structured report.
       """
     })
     ```

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

State: `phase = "phase_6"` once (a) is chosen, save. **Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 5 entry per major revision wave (one append per revisor-driven decision change); if no revisions occurred (user chose (a) immediately), append a short "no revisions" entry.

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
6. **LOCK** (v2.2 — sketch D): freeze the design at version `v1.0`. Set the three lock fields on `state.json` BEFORE the lockfile cleanup so the locked state is what persists for future `/iterate-design` invocations:

   ```bash
   # Phase 6 LOCK step (v2.2 — sketch D)
   NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   jq --arg now "$NOW" '.locked = true | .version = "v1.0" | .locked_at = $now' \
     docs/_architect_state.json > /tmp/state.tmp && mv /tmp/state.tmp docs/_architect_state.json
   ```

   Then commit the locked state via `commit-commands:commit` with subject `architect(lock): v1.0`.
7. **Cleanup** (v2.1.5 fix — bug #14): the state.json is preserved. Do NOT remove `docs/_architect_state.json`. The state file is the canonical entry point for future re-invocations and (in v2.2) for `/iterate-design`. Optionally archive a copy to `docs/versions/v1.0/_architect_state.json` (in v2.2 this becomes mandatory; for v2.1.5 transitional, offer it as an option). Commit only the lockfile cleanup if the lock is held: `chore: release bootstrap lock`.

   ```bash
   # Release lock (delete lockfile only)
   rm -f docs/_architect_state.lock
   # IMPORTANT: never remove the state file — it is the cross-session entry point
   ```
8. **Memory persistence (major update):** Edit the pointed-to file per `references/memory-persistence.md` with a new section: `## LOCKED at v{{state.version}} — <ISO8601 timestamp>` followed by the full design summary (final ADR list, doc count, locked_at). Then update the `MEMORY.md` index entry to mark the project as locked (replace the in-design suffix with `locked at <version> (<locked_at>)`).
9. Output: "✓ Project architect complete."
10. State: phase = "complete".

---

## Phase 7: Tooling Execution (v2.2, sketch D)

After lock, ask the user which plans to execute:

```
✓ Architecture locked at v1.0.

Phase 7: Tooling Execution

Which plans to execute now?
  (a) Execute CLAUDE_MD_PLAN  → generates CLAUDE.md (claude-md-author)
  (b) Execute CLAUDE_TOOLING_PLAN → generates .claude/* (claude-tooling-author + slash commands)
  (c) Hand off SCAFFOLD_PLAN to superpowers (writing-plans → SDD)
  (d) Skip all execution (close out with plans only)
  (e) (a) + (b) + offer (c) — recommended productive path
```

For each chosen execution:

- **(a) CLAUDE_MD_PLAN**: dispatch `claude-md-author` with `plan_path: docs/CLAUDE_MD_PLAN.md` as input. Agent reads plan, substitutes placeholders from state, writes CLAUDE.md. Commit: `architect(phase-7): execute CLAUDE_MD_PLAN`.

  ```
  Agent({
    subagent_type: "project-architect:claude-md-author",
    model: "opus",
    description: "Execute CLAUDE_MD_PLAN",
    prompt: """
      [MODEL DIRECTIVE]
      Run with maximum effort. Apply extended thinking. Be thorough.

      [INPUTS]
      plan_path: docs/CLAUDE_MD_PLAN.md
      state_path: docs/_architect_state.json

      [TASK]
      Read the plan. Resolve every placeholder against state.decisions.
      Write the root CLAUDE.md and any subfolder CLAUDE.md files per the
      plan's hierarchy section. Run claude-md-management:claude-md-improver
      on each and iterate until pass. Return the list of files written.
    """
  })
  ```

- **(b) CLAUDE_TOOLING_PLAN**: dispatch `claude-tooling-author` with `plan_path: docs/CLAUDE_TOOLING_PLAN.md`. Agent reads plan, generates `.claude/*` tree including the 3 router slash commands (`/scaffold`, `/implement`, `/iterate-design`). Commit: `architect(phase-7): execute CLAUDE_TOOLING_PLAN`.

  ```
  Agent({
    subagent_type: "project-architect:claude-tooling-author",
    model: "opus",
    description: "Execute CLAUDE_TOOLING_PLAN",
    prompt: """
      [MODEL DIRECTIVE]
      Run with maximum effort. Apply extended thinking. Be thorough.

      [INPUTS]
      plan_path: docs/CLAUDE_TOOLING_PLAN.md
      state_path: docs/_architect_state.json

      [TASK]
      Read the plan. Generate .claude/settings.json, .claude/hooks/*,
      .claude/agents/*, .claude/commands/* (including /scaffold, /implement,
      /iterate-design router slash commands), and .claude/recommended-plugins.md
      exactly as the plan specifies. Return artifact counts.
    """
  })
  ```

- **(c) SCAFFOLD_PLAN**: invoke `Skill: superpowers:writing-plans` with `spec_path: docs/SCAFFOLD_PLAN.md` and execution mode `subagent-driven-development`. Control transfers to superpowers. The architect's responsibility ends here for code emission.

- **(d) Skip**: proceed to Phase 8 with no execution. The user runs `/scaffold` etc. in a future session.

- **(e) Default productive path**: do (a) + (b) automatically; then offer (c) as a separate question.

Re-dispatch `quality-gate-auditor` after each execution to re-validate the bundle (now includes the just-generated CLAUDE.md/.claude/*):

```
Agent({
  subagent_type: "project-architect:quality-gate-auditor",
  model: "opus",
  description: "Phase 7 post-execution audit",
  prompt: """
    [MODEL DIRECTIVE]
    Run with maximum effort. Apply extended thinking. Be thorough.

    [INPUTS]
    project_root: {{user project root}}
    state_path: docs/_architect_state.json
    catalog_path: skills/project-architect/references/templates/
    adr_dir: docs/decisions/

    [TASK]
    Run all 16 checks via run_all.sh against the now-executed bundle.
    Return the aggregate JSON. Do NOT modify any files.
  """
})
```

Save the auditor result into `state.last_audit` (overwriting the Phase 4 audit). If `summary.blocker > 0`, surface to the user before advancing.

Commit:
- After each execution: per the per-option commit messages above.
- After all executions: state save, `phase = "phase_8"`.

**Memory persistence:** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 7 entry recording execution outcome (CLAUDE.md y/n, `.claude/*` y/n, scaffold y/n, post-execution audit summary).

---

## Phase 8: Handoff (v2.2, sketch D)

Print the handoff message and end the architect run.

```
✓ Architecture locked at v{{state.version}}
✓ {{N}} design docs in docs/
✓ {{M}} plan docs in docs/*PLAN.md
{{✓ CLAUDE.md generated | ⊘ CLAUDE.md skipped (plan exists at CLAUDE_MD_PLAN.md)}}
{{✓ .claude/* generated | ⊘ .claude/* skipped (plan exists at CLAUDE_TOOLING_PLAN.md)}}
✓ Final commit: {{HEAD sha}}
{{✓ Pushed to origin: {{url}} | ⊘ No remote configured}}

Next step: restart Claude Code to load the new CLAUDE.md and .claude/ tooling.
   Type `/exit` then run `claude` in this directory.

After restart, the new session will:
   • Auto-load your new CLAUDE.md as the project's operating manual
   • Auto-load .claude/settings.json (permissions) and .claude/hooks/
   • Offer next-step options via the slash commands defined in .claude/commands/

Slash commands available after restart:
   /scaffold        — scaffold the actual code (uses superpowers if installed)
   /implement <X>   — implement a specific feature from requirements
   /iterate-design  — re-open the design for revision

Architect session ending. Type /exit when ready.
```

State: `phase = "complete"`, `prerequisites_satisfied = true`. Save. **Memory persistence (final update):** Edit the pointed-to file per `references/memory-persistence.md` with a Phase 8 handoff entry (closing summary + next-step recommendations); this is the entry future sessions grep for context. Architect returns control to user.

---

## Failure modes & recovery

| Failure | Recovery |
|---|---|
| User exits mid-phase | State saved at every batch. Re-invocation reads state, prints resume summary, picks up at `state.phase`. |
| Agent dispatch returns malformed output | Retry once with clarification appended to the prompt. If still failing, fall back to inline completion: orchestrator drafts the doc itself using the template + state slice. |
| Commit fails (pre-commit hook rejects) | Surface error, ask user. **Never** `--no-verify`. |
| Push fails (network / auth) | Commit locally, queue push for next phase boundary. |
| Required dep missing (`commit-commands`) | Refuse to start with explicit install command. |
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

---

*★ Skillfully made with [project-architect](https://github.com/alexander-ford-ventures/project-architect).*
