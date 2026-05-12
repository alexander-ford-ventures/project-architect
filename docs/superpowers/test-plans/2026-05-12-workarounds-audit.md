# Workarounds Audit — Final Round (2026-05-12, post-fixes)

## Summary

3 findings — 0 blocking, 3 minor.

Plugin manifests, JSON, frontmatter, cross-references, tool grants, phase enum, state-schema, and agent contracts are all in order. The implementation is functionally clean and ready for live tests. Three documentation-consistency issues remain: `README.md` lists 5 recommended plugins instead of 6 (missing `fewer-permission-prompts`); the as-built appendix in spec/plan still describes a 5-plugin baseline; the failure-modes table still carries a "Recommended (soft) dep missing" row even though Preflight now resolves it proactively.

None block live testing. The runtime path (orchestrator + 5 agents) is fully consistent with the 6-plugin Preflight baseline.

## Checks

### Structural validations

1. **PASS** — `claude plugin validate /Users/vladimir/projects/project-architect/.claude-plugin/plugin.json` returns `✔ Validation passed`.
2. **PASS** — `claude plugin validate /Users/vladimir/projects/project-architect` returns `✔ Validation passed` (marketplace manifest validated).
3. **PASS** — `python3 -m json.tool` parses both `plugin.json` and `marketplace.json` cleanly.
4. **PASS** — File inventory exact:
   - `agents/` contains exactly 5 files: `claude-md-author.md`, `claude-tooling-author.md`, `decision-revisor.md`, `document-author.md`, `research-scout.md`. No `.gitkeep`. No v1 leftovers.
   - `skills/project-architect/references/` contains exactly 7 files: `questioning-flow.md`, `tech-stack-options.md`, `document-catalog.md`, `research-prompts.md`, `revision-playbook.md`, `claude-code-integration.md`, `state-schema.md`.
   - `skills/project-architect/references/templates/` contains exactly 56 `.md` files.
   - `SKILL.md` is 573 lines (within the 400–650 acceptable range).
5. **PASS** — Every `.md` in `agents/` (5 files) and `references/templates/` (56 files) starts with `---` YAML frontmatter. Verified with a per-file `head -1` loop; zero misses.
6. **PASS** — Every agent file has `name`, `description`, `tools`, `model: opus` in frontmatter. Verified by AWK-parsing each frontmatter block.

### Cross-reference resolution

7. **PASS** — `grep -oE 'references/[a-z-]+\.md' skills/project-architect/SKILL.md | sort -u` returns 7 paths; each matches a file in `skills/project-architect/references/` exactly. No dangling reference.
8. **PASS** — No `docs/superpowers/specs/...` redirect anywhere in `SKILL.md`, `references/`, or `agents/`. The state-schema is sourced canonically from `references/state-schema.md` (lines 28 and 553 of SKILL.md).
9. **PASS** — No `<!-- SKILL_E*_MARKER -->` markers in `SKILL.md`, `references/`, or `agents/`. The only matches in the repo are inside `docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md` where they are intentional historical references to past edit steps — not "leftover anywhere" in runtime files.

### SKILL.md content

10. **PASS** — Frontmatter description starts with `Use when the user wants to set up a new project, ...`. Does not contain the words `interview`, `dispatch`, `orchestrator`, or any phase number. Verified by `grep -cE` against the frontmatter slice.
11. **PASS** — `python3 yaml.safe_load` parses the SKILL.md frontmatter cleanly. Returns `{'name', 'description'}`. No unquoted colons in long strings.
12. **PASS** — Phase -1 Preflight (lines 57–82) lists six recommended plugins: `superpowers`, `claude-md-management`, `claude-code-setup`, `hookify`, `document-skills`, `fewer-permission-prompts`. Each has a probe line and an explicit "used by which agent/phase for what" justification.
13. **PASS** — All 5 subagent types have explicit `Agent({...})` envelope examples inline in SKILL.md:
    - `research-scout` (line 144)
    - `document-author` (line 309)
    - `claude-md-author` (line 341)
    - `claude-tooling-author` (line 367)
    - `decision-revisor` (line 445)
14. **FAIL (minor)** — The failure-modes table (line 543) still contains a "Recommended (soft) dep missing" row. The row's body now correctly explains that the case is handled proactively at Phase -1, but per the audit spec the row itself should have been removed (it's no longer an unresolved failure mode). Cosmetic only; the runtime behavior is consistent.
15. **PASS** — No `phase_-1` string anywhere in SKILL.md, references, or agents. All Preflight references use `preflight`. The only `phase-1` match (SKILL.md:206) is the commit-message template for Phase 1 (Discovery), which is correct usage.

### State schema consistency

16. **PASS** — `state-schema.md` phase enum (line 113) includes `preflight` and uses `phase_0a … phase_7 | complete`. No `phase_-1` token.
17. **PASS** — `state-schema.md` documents a full `recommended_plugins[]` fields table (lines 139–154), with six fields, type/required annotations, and two write-point notes (Phase -1 baseline + Phase 6 per-project additions). This satisfies Finding 3 from the prior audit.
18. **PASS** — The `decisions` namespace section (line 158) cross-references `revision-playbook.md` explicitly: "*The full canonical catalog … lives in **[`revision-playbook.md`](./revision-playbook.md)**. Do not duplicate it here.*" Plus an inline jsonc comment at line 64 of the schema block.
19. **PASS** — The Phase-progress fields table (lines 121–133) covers every phase enumerated in the phase enum (`preflight`, `phase_0a`, `phase_0`, `phase_1`, `phase_2`, `phase_2.5`, `phase_3`, `phase_4`, `phase_5`, `phase_6`, `phase_7`). `complete` is a terminal state, not a phase with progress, so its omission is correct.

### Agent contracts

20. **PASS** — `claude-tooling-author` frontmatter `tools:` array is `[Read, Write, Edit, Glob, Grep, Bash, Skill]` — `Skill` is present. Body invokes 4 different `Skill:` calls (`fewer-permission-prompts`, `update-config`, `hookify:writing-rules`, `claude-code-setup:claude-automation-recommender`).
21. **PASS** — `claude-md-author` frontmatter `tools:` array is `[Read, Write, Edit, Glob, Grep, Bash, Skill]`. Body invokes `Skill` tool with `claude-md-management:claude-md-improver` at step 5 (line 39) and step 4 of substep loop (line 66).
22. **PASS** — Python regex scan of all agent bodies against their declared `tools:` arrays finds zero undeclared-tool usages. (Verified for all 5 agents across `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `WebSearch`, `WebFetch`, `Skill`.)
23. **PASS** — Each agent body cites the files/skills it reads at runtime:
    - `claude-md-author` cites `template_root_path`, `template_subfolder_path`, `state_path`, and the `claude-md-management:claude-md-improver` skill.
    - `claude-tooling-author` cites `integration_path` (= `references/claude-code-integration.md`), `state_path`, and the four optional `Skill:` invocations.
    - `document-author` cites `template_path` (under `references/templates/`), `state_slice`, `research_paths`.
    - `decision-revisor` cites `playbook_path` (= `references/revision-playbook.md`), `state_path`.
    - `research-scout` does not read internal references; reads web only (correctly scoped).

### Doc consistency

24. **FAIL (minor)** — `README.md` (lines 40–48) lists only 5 recommended plugins: `superpowers`, `claude-md-management`, `claude-code-setup`, `hookify`, `document-skills`. Missing: `fewer-permission-prompts`. The Preflight baseline now has 6 entries, so README is out of sync. Independent minor issue: README also says SKILL.md is "~200 lines" and references is "6 reference files" — actual is 573 lines and 7 reference files. Cosmetic but worth correcting for accuracy.
25. **PASS** — `CHANGELOG.md` 2.0.0 release notes describe the implemented feature set: 9-phase model, 5 subagents, ADRs, decision-revisor consequence propagation, `.claude/` generation with stack-aware permissions, ~56 templates, resumable state, optional Phase 7 handoff. All match what's actually shipped.
26. **FAIL (minor)** — The "as-built corrections" appendix in both `docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md` (line 940) and `docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md` (line 4753) describes the runtime Preflight check as scanning for "5 recommended plugins". Implementation now scans for 6. The appendix should be updated (or appended-to, per the "append-only" convention stated in those docs) so future maintainers don't see the discrepancy.

### Git state

27. **PASS** — Working tree clean (`git status` reports `nothing to commit, working tree clean`).
28. **PASS** — On branch `main`.
29. **PASS** — `origin/main` is up to date with local (`git log origin/main..HEAD` and `git log HEAD..origin/main` both empty after `git fetch`).
30. **PASS** — Tag `v2.0.0` exists locally (`git tag` lists `v2.0.0`) and on origin (`git ls-remote --tags origin` lists `refs/tags/v2.0.0` at `063b5d6c…`).

### Free-form scan

- **PASS** — No literal `TODO`, `TBD`, `FIXME`, `XXX`, `WIP` markers in any of `skills/` or `agents/` outside template-body contexts. The single hit is `references/claude-code-integration.md:335` inside a fenced shell snippet: `rg -n "TODO|FIXME" --max-count=5 …` — that's the literal command the generated `session-start.sh` hook template runs, not a leftover marker.
- **PASS** — Soft-language scan (`(deferred)`, `later`, `pending`, `not yet`, `to be`, `placeholder`) yields only legitimate prose usage. Examples: "user can resume later", "Template names not yet authored" (in jsonc field comment), "pending message age" (in BACKGROUND_JOBS template body), "later enumerated in the STRIDE walkthrough" (THREAT_MODEL template). All intentional content, none are workaround flags.
- **PASS** — `{{placeholder}}` scan outside fenced code blocks (Python pass with proper indented-fence detection): two hits in `references/claude-code-integration.md` (lines 380 and 483), both inside nested template fences within an outer code block, so they are intentional template snippets. All other `{{…}}` instances are inside `Agent({…})` envelope blocks or other fenced code regions.

## Findings

### Finding 1 — Failure-modes table still carries a now-redundant "Soft dep missing" row

**Severity:** minor (cosmetic)
**Location:** `skills/project-architect/SKILL.md:543`
**What's wrong:** Audit check #14 expected the row to be removed because soft-dep handling is now resolved proactively at Phase -1. The row exists; its body correctly describes the proactive handling, but its presence in a "Failure modes & recovery" table is logically inconsistent with the new Preflight behavior.
**Suggested fix:** Either (a) delete the row outright, or (b) move it under a new short subsection titled "Resolved at Preflight" with one sentence pointing back to Phase -1's soft-dependency check. Option (a) is the lower-churn choice; option (b) preserves a discoverable note for anyone still wondering "what if it's missing?".

### Finding 2 — `README.md` lists 5 recommended plugins; runtime baseline lists 6

**Severity:** minor (doc consistency)
**Location:** `README.md:40-48`
**What's wrong:** README's "Recommended:" section enumerates 5 plugins. The Preflight soft-dep check in SKILL.md (line 61) enumerates 6 (the same 5 plus `fewer-permission-prompts`). A new user reading README first won't know to install `fewer-permission-prompts` and will see it as a surprise at Preflight.
**Suggested fix:** Add a sixth bullet to `README.md`:
```
- `fewer-permission-prompts` (for tightening the generated `.claude/settings.json` allowlist).
```
Secondary fix while editing the file: update the "Plugin layout" section so the SKILL.md size estimate ("~200 lines") and the reference count ("6 reference files including `templates/`") match reality (573 lines, 7 reference files). The latter is the same one-line edit.

### Finding 3 — As-built appendix still describes a 5-plugin Preflight check

**Severity:** minor (historical accuracy)
**Location:**
- `docs/superpowers/specs/2026-05-12-project-architect-v2-redesign-design.md:940`
- `docs/superpowers/plans/2026-05-12-project-architect-v2-implementation.md:4753`
**What's wrong:** Both appendices say:
> "A new Preflight runtime check in SKILL.md (`### Soft-dependency check`) that scans for the 5 recommended plugins and offers to install missing ones at session start."
The Preflight check now scans 6 plugins. The doc convention at the bottom of each appendix says future divergences should be appended as new rows, not rewritten in-place — so the cleanest fix is to add a new sub-row (e.g., "### 4. `fewer-permission-prompts` added to the Preflight baseline") that records the change and references commit `b59cbfd`.
**Suggested fix:** Append a fourth row to both as-built appendices documenting that `fewer-permission-prompts` was added to the Preflight baseline post-implementation (commit `b59cbfd`). Do not rewrite existing rows.

## Recommendation

**CLEAR TO PROCEED with live tests.**

All three findings are documentation/consistency issues, not runtime bugs. The orchestrator, agents, references, state schema, plugin manifest, and git state are clean. The failure-modes-table row (Finding 1) is harmless; the README and as-built doc gaps (Findings 2 and 3) are pure documentation lag that can be patched at any time without affecting test outcomes.

If desired before live tests, the three minor edits could be batched into a single follow-up commit (`docs(readme+as-built): align with 6-plugin Preflight baseline`) — but live testing can begin immediately as-is.
