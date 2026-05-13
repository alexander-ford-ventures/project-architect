<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# CLAUDE.md — `project-architect`

> Auto-loaded by Claude Code when working in this repo. Captures what this project is, where things live, how we develop it, and the non-obvious gotchas the next session shouldn't have to rediscover.

## What this project is

A **Claude Code plugin** that orchestrates the interactive bootstrap of a new software project. The user invokes the `project-architect` skill; it walks 11 phases (Preflight → Repo Init → Universal Kickoff → Vision → Tech Stack → Cost → Architecture → Doc Generation → Iteration → Lock → Tooling Execution → Handoff), dispatching 6 specialised subagents and emitting design docs, ADRs, `CLAUDE.md`, `.claude/` tooling, and a scaffolded skeleton.

Published at <https://github.com/siliconyouth/project-architect>. Current tag: `git describe --tags --abbrev=0`.

## Commands you'll actually run

```bash
# Smoke test — run after EVERY change
bash tests/run_all.sh
# Must end with "All tests passed" and "Test files failed: 0".

# Run a single check against a fixture
bash agents/quality-gate-auditor/run_all.sh tests/fixtures/e2e-rust-cli \
     tests/fixtures/e2e-rust-cli/docs/_architect_state.json | jq .summary

# Lint shell + python checks
shellcheck agents/quality-gate-auditor/checks/check_*.sh tests/test_*.sh
for f in agents/quality-gate-auditor/checks/check_*.py; do python3 -m py_compile "$f"; done

# Release (see "Release workflow" below — order matters)
git tag v<X.Y.Z>
git push origin main && git push origin v<X.Y.Z>
gh release create v<X.Y.Z> --title "v<X.Y.Z>" \
   --notes-file - < <(sed -n "/^## v<X.Y.Z>/,/^## v/p" CHANGELOG.md | sed '$d')

# End-user update flow (also useful when dogfooding)
# In any Claude Code session:
/plugin           # detects + downloads updates from marketplaces
/reload-plugins   # applies to the live session without restart
```

## Architecture

```
.claude-plugin/plugin.json              version + plugin metadata (SOURCE OF TRUTH for version)
.claude-plugin/marketplace.json         marketplace listing description
agents/                                 6 subagent prompts — all opus, all with runtime_budget frontmatter
  quality-gate-auditor/checks/_lib.sh   sourced helpers shared by every shell check (do NOT chmod +x)
  quality-gate-auditor/checks/check_NN_*.{sh,py}  one file per check (16 total)
skills/project-architect/
  SKILL.md                              11-phase orchestrator — the "skill body"
  references/                           docs SKILL.md reads on demand via the Read tool
    state-schema.md, document-catalog.md, runtime-budgets.md, memory-persistence.md, ...
  references/templates/                 60+ design-doc templates + 4 plan templates + 3 slash templates + CLI_UX_DESIGN
tests/
  run_all.sh                            runner — iterates tests/test_*.sh
  lib/test_helpers.sh                   assert_eq / assert_contains / assert_file_exists / test_summary
  fixtures/                             clean-bundle + 14 per-check failure fixtures + 3 e2e fixtures
  test_v22_*.sh                         the v2.2 test suite (54 files at v2.2.0)
docs/
  superpowers/plans/                    implementation plans with annotated commit maps
  superpowers/specs/                    design specs (validation sketches, CLI-UX questioning)
  tests/                                live-test reports (e.g. md2pdf 2026-05-13)
```

## Development workflow

This project ships a Claude Code skill+plugin to other developers. Rushed releases break their installs. Follow this discipline.

### TDD is non-negotiable

Every change to a check, template, agent, or `SKILL.md` follows:

1. Write the failing test first (`tests/test_<version>_*.sh`) — use `assert_contains` against the exact string you expect.
2. Run it; confirm it FAILS for the right reason.
3. Write the minimal implementation.
4. Run the single test; confirm it PASSES.
5. Run `bash tests/run_all.sh`; confirm zero regressions.
6. Commit with a Conventional Commits subject.

**No "I'll add a test later".** If the change can't be tested by string-matching against a known output, redesign until it can. See `superpowers:test-driven-development` for the underlying discipline; `superpowers:writing-skills` extends it to documentation changes (every `SKILL.md` edit needs a test).

### Subagent-driven plan execution

For multi-task plans (e.g. `docs/superpowers/plans/2026-05-13-v2.2-implementation.md`), use `superpowers:subagent-driven-development`. Per task:

- A fresh implementer subagent (TDD inside).
- A spec-compliance review subagent.
- A code-quality review subagent.
- An optional fix-and-re-review loop until APPROVED.

**Always pass `model: "opus"` and an explicit max-effort directive in the prompt.** Never `sonnet`/`haiku` for this project, even on mechanical tasks. The rule is durable: see `~/.claude/projects/-Users-vladimir-projects-project-architect/memory/feedback_subagent_model.md`.

### Combined-review + parallel-dispatch (the speedup)

Once a plan's pattern is stable (typically after 3-4 tasks), run the **combined** spec+code-quality review of task N **in parallel** with the implementer of task N+1. Halves wall-clock. The reviewer reads a frozen commit SHA; the next implementer writes to non-overlapping files. They don't conflict.

### Rule-of-2.5 helper extraction

Extract shared helpers on the SECOND occurrence, not the third. `_lib.sh` was pulled out during the Task 11 code-quality review and paid off 15× across the remaining auditor checks. **Don't wait for the rule of three.** The second time you'd copy-paste, extract.

### Release workflow — CODIFIED HERE because we drifted in v2.2.0

> **The release commit MUST be the last commit before the tag. No commits land past the tag without a new tag.**

The canonical sequence (mirrors v2.1.5 — `git log v2.1.4..v2.1.5` is the working example):

1. Land every implementation commit on `main` via normal TDD.
2. **In ONE final commit** before tagging, bundle ALL of these:
   - Bump `.claude-plugin/plugin.json` version.
   - Prepend the version's `CHANGELOG.md` entry.
   - Update `README.md` — test counts, feature list, "What's new", versioning-policy example.
   - Update `.claude-plugin/marketplace.json` description if surface area changed.
   - Refresh `skills/project-architect/SKILL.md` preamble + Phase order if structure changed.
   - Mark relevant `docs/superpowers/specs/*.md` and `docs/superpowers/plans/*.md` as "shipped".
3. Subject: `chore(release): vX.Y.Z — <one-line summary>`.
4. `git tag vX.Y.Z`.
5. `git push origin main && git push origin vX.Y.Z`.
6. `gh release create vX.Y.Z --title "vX.Y.Z" --notes-file -` (pipe the CHANGELOG entry via the `sed` recipe in the commands section). **Without this step the Preflight version-freshness check can't see the new version** — `gh release view` returns Releases, not raw tags.

**If you discover doc or behaviour drift after pushing the tag**, do NOT push polish commits past the tag. Instead:

- Open a new branch or just stage on `main`.
- Bump to the next patch (`vX.Y.Z+1`).
- Land the polish + the bump in ONE commit.
- Tag, push, release.

#### Red flags — STOP and start over

| Rationalisation | Reality |
|---|---|
| "It's just a docs patch, no need to bump" | If end users see it (README, CHANGELOG, Preflight notice, marketplace description), it's part of the release. Bump. |
| "I'll re-tag later" | Re-tagging is destructive (force-push) and breaks anyone who cached the old SHA. Bump patch instead. |
| "It's not behaviour, won't affect users" | Preflight prose, SKILL.md instructions, and `gh release` notes ARE behaviour at the documentation layer. Bump. |
| "Only one tiny commit — not worth a release" | One commit = one patch bump. The cost of a patch release is ~2 minutes. The cost of orphan commits past a tag is silent user confusion forever. |
| "The CHANGELOG already mentions this in v2.2.0" | The CHANGELOG-as-pushed-after-the-tag is invisible to anyone who pulls the tag tarball. Bump. |

### Self-modification awareness

If a Claude session has `project-architect` loaded as a skill, modifying `skills/project-architect/SKILL.md` mid-session won't take effect until `/reload-plugins`. Worse: if you load project-architect and then edit it, the in-memory copy diverges from disk. **When iterating on `SKILL.md`, work in a Claude session that does NOT have project-architect loaded** (the dev session of this repo doesn't auto-load it because the install lives in `~/.claude/plugins/cache/`, not here). Run `/reload-plugins` after every meaningful skill change if you want to dogfood.

## Gotchas (non-obvious)

- **1Password SSH agent re-locks between commits.** A signed git commit triggers TouchID; the agent then re-locks within minutes. For multi-commit sessions, the user needs to be at the keyboard. If blocked mid-run, schedule a 1200s wakeup (`ScheduleWakeup`) — 60s rapid polling burns turns; 300s is the worst-of-both cache window.
- **`gh release view --json tagName` returns Releases, not tags.** A pushed tag without a Release object is invisible to the Preflight version-freshness check. Always `gh release create` after `git push origin <tag>`.
- **`_lib.sh` is sourced, not invoked.** Mode `644`, no shebang line, no `chmod +x`. Sourced by every shell check via `source "$(dirname "$0")/_lib.sh"`.
- **Python check scripts can't source `_lib.sh`** (bash-only). They use `json.dumps()` directly. Wire contract is identical: one JSON object on stdout per check.
- **Plugin namespace `siliconyouth:` vs `local:`.** `SKILL.md` Phase 7 dispatches use `subagent_type: "project-architect:claude-md-author"`. The prefix depends on which marketplace the user installed from. `siliconyouth` is the published marketplace; `local` is dev. Confirmed working for `siliconyouth`; untested live for `local`.
- **`{{placeholder}}` literals in `references/templates/*.md` are intentional.** Substitution markers consumed by `claude-md-author` / `document-author` / `claude-tooling-author` at generation time. Auditor check 8 (`no_placeholders`) scans the user's `docs/`, NOT our `references/templates/`, so it doesn't false-positive on us.
- **Our `docs/superpowers/*` files contain `{{...}}` examples in prose.** When the auditor self-audits this repo, it flags those as INFO findings. They are real findings *for a user's project* but non-issues *for ours*. Acceptable noise.

## File attribution convention

Every project-internal file carries author + license + repo attribution. The format depends on file type.

**Markdown files (`.md`)** — header after frontmatter, footer at end:

````markdown
<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# ...content...

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
````

**Shell + Python (`.sh`, `.py`)** — bash-comment header after shebang, no footer:

````bash
#!/usr/bin/env bash
# Author: Vladimir Dukelic <vladimir@dukelic.com>
# License: MIT
# Project: project-architect (https://github.com/siliconyouth/project-architect)
````

**Files that are exceptions:**
- `.remember/*` — local-only daily notes, gitignored, no attribution.
- `CHANGELOG.md` — release-notes convention has no footer.
- `.github/*` templates — github-meta files; header optional.
- Frozen historical docs (e.g. `docs/superpowers/plans/2026-05-12-*.md`) — leave as-is per "don't tweak history in passing".
- Files in `tests/fixtures/` — fixture content intentionally minimal.

**Rule:** Every new project file you create MUST start with the appropriate attribution. Every edit to an existing file should ADD attribution if it's missing AND the file is in the "should comply" set above.

When in doubt: grep an existing compliant file of the same type (e.g. `head -20 skills/project-architect/SKILL.md` for `.md`, `head -10 agents/quality-gate-auditor/checks/check_05_json_valid.sh` for `.sh`).

## Testing

```bash
bash tests/run_all.sh                   # full suite
bash tests/test_v22_check_NN_*.sh       # one check at a time
bash tests/test_v22_e2e_*.sh            # end-to-end fixtures (rust / python-tui / go-cli)
shellcheck agents/quality-gate-auditor/checks/check_*.sh tests/test_*.sh
python3 -m py_compile agents/quality-gate-auditor/checks/check_*.py
```

Host tooling required: `bash >= 4`, `jq`, `python3 >= 3.10`, `shellcheck`, `gh`, `git`, `curl`. Python deps: `pip install pyyaml python-dateutil` (the Python checks use both).

## Memory (cross-session continuity)

Project memory lives in `~/.claude/projects/-Users-vladimir-projects-project-architect/memory/`:

- `MEMORY.md` — index (one line per memory file).
- `feedback_subagent_model.md` — durable rule: `model: "opus"` + max-effort for every subagent dispatch.
- `project_v22_session_2026-05-13.md` — last shipping checkpoint (v2.2.0 release narrative + patterns).
- `project_architecture_post_v22.md` — repo structure snapshot.

Update these when patterns change. Don't store ephemeral conversation state — store what's load-bearing for the NEXT session's first 30 seconds.

## When to consult what

| Question | Source of truth |
|---|---|
| "What version did this ship in?" | `git tag --contains <sha>` + `CHANGELOG.md` |
| "What does the v2.2 plan look like?" | `docs/superpowers/plans/2026-05-13-v2.2-implementation.md` (commit map at top) |
| "What's the `state.json` schema?" | `skills/project-architect/references/state-schema.md` |
| "What is auditor check N supposed to do?" | The check script's header docstring + `tests/test_v22_check_NN_*.sh` assertions |
| "How do I add a new template?" | Copy an existing `references/templates/<EXISTING>.md`, add a row to `references/document-catalog.md`, write `tests/test_<version>_template_<name>.sh`, then TDD-commit-release per the workflow above |
| "How do I add a new auditor check?" | Copy `check_05_json_valid.sh` (the canonical bash pattern) or `check_10_yaml_frontmatter.py` (canonical Python pattern), add a fixture under `tests/fixtures/<defect>/`, add `tests/test_<version>_check_NN_*.sh`, TDD-commit-release |
| "How does the end-user update flow work?" | `README.md` § "Keeping project-architect up to date" + Preflight version-freshness check in `SKILL.md` |
| "Where is the runtime-budget observer wrapper documented?" | `skills/project-architect/references/runtime-budgets.md` |
| "Where is per-phase memory persistence documented?" | `skills/project-architect/references/memory-persistence.md` |

---

*★ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
