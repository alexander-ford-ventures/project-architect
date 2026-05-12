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
