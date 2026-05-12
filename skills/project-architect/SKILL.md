---
name: project-architect
description: Use when the user wants to set up a new project, scaffold project docs, plan a new project, initialize project architecture, bootstrap with planning documents, design a system architecture, choose a tech stack, revisit existing project architecture decisions, or generate CLAUDE.md and .claude/ config for an existing project. Works for any project type — web apps, mobile, multi-platform, APIs, CLI tools, libraries, desktop, browser extensions, games, AI/ML, data pipelines, embedded/IoT, infrastructure, Claude Code plugins, MCP servers, Web3, scientific code, AR/VR.
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

Persistent across the bootstrap: `docs/_architect_state.json`. Schema, lockfile protocol, and migration policy are documented in `references/state-schema.md`. Save after every batch, every agent dispatch, every commit. Delete only at end of Phase 6 cleanup.

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

### Ambient hooks tolerance

Silently pre-create `.remember/logs/` in cwd so the `remember` plugin's PostToolUse hook (if installed) can write its error log without erroring out. Run as `Bash`:

```bash
mkdir -p .remember/logs 2>/dev/null || true
```

The `|| true` ensures failure never blocks Preflight — the architect doesn't depend on this directory. This is a courtesy to a separate plugin and is harmless when `remember` isn't installed (the dir is empty + listed in `.gitignore` by Phase 0a). It lives in Preflight (not Phase 0a) because the hook fires on the first Bash/Read call regardless of whether the user opts into git init.

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
