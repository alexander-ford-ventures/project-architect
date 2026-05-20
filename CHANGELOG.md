<!--
Author: Alexander Ford <alex@pseudo-lang.com>
Repository: https://github.com/alexander-ford-ventures/project-architect
License: MIT
-->

# Changelog

All notable changes to the `project-architect` plugin.

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v3.1.0 — 2026-05-20

**Universal research checklist for every `research-scout` dispatch + the full Alex Ford Labs brand-asset kit.**

Minor release. Backward-compatible. Same 11-phase orchestrator, same 6 subagents, same 16-check auditor, same state schema. The new rule changes WHAT the scout does (always fetches `llms.txt`/`llms-full.txt` + cites latest official docs), not WHO calls it or HOW the orchestrator dispatches it.

### Added — universal research checklist

- **Every `research-scout` dispatch** (phase-level Phase 0/1/2/2.5/3 and ad-hoc red-flag alike) now MUST cover four bases before topic-specific work begins: (1) **latest official docs**, (2) **`llms.txt` + `llms-full.txt`** per the [`llmstxt.org`](https://llmstxt.org/) standard, (3) **current best practices** via web search, (4) **3–5 similar projects / prior art**. Findings files MUST cite the official-docs URL plus any `llms.txt` source for each tool researched.
- **`agents/research-scout.md`** — adds a "Universal first-pass" section before the existing "Research methodology" section. Includes worked `llms.txt` URL examples (`docs.anthropic.com/llms.txt`, `docs.cloudflare.com/llms.txt`, `supabase.com/docs/llms.txt`, `nextjs.org/llms.txt`) and a documented fallback when `llms.txt` is absent.
- **`skills/project-architect/references/research-prompts.md`** — adds a top-level "Universal research checklist" section, listed in the ToC, applied to "every dispatch". The phase-specific prompts now add topic-specific questions ON TOP of this universal floor.
- **`tests/test_v31_research_llms_txt.sh`** (17 assertions) — asserts the rule survives in both the agent prompt and the prompt-template reference, including the `llmstxt.org` standard URL, the literal phrase "latest official", the "Universal first-pass" section heading, the "Universal research checklist" section heading, the "every dispatch" applicability statement, and the four-bullet floor.

### Added — Alex Ford Labs brand-asset kit

- **`.github/assets/brand/`** — full visual identity for the Alex Ford Labs umbrella entity. **Geist Mono ExtraBold** (display) + **Geist Mono Medium** (subtext), **V5 palette** (pure B&W, no colour at the umbrella level). 50 files, 588 KB total. Every SVG is outline-converted via `fontTools` — Geist Mono glyphs become vector paths embedded directly in the SVG, no font dependency at render time.
  - `lockup/` — AF / LABS matched-width stack, the **primary mark** (SVG + PNG @ 256/512/1024/2048, light + dark)
  - `mark/` — just AF, favicon-grade (SVG + PNG @ 16/32/48/64/128/180/192/256/460/512/1024, light + dark)
  - `wordmark/` — AF · LABS inline horizontal (SVG + PNG @ 400/800/1600/3200, light + dark)
  - `social/` — pre-composed 1280×640 GitHub social preview (SVG + PNG, light + dark)
  - `source/build_brand.py` — `fontTools` outline conversion + `cairosvg` rasterizer, regenerable
  - `README.md` — usage guide (which asset for which surface, light/dark `<picture>` toggle pattern, future colour variants per sub-brand)

### Changed

- **README hero image** now references `.github/assets/brand/social/light-1280x640.png` (Alex Ford Labs umbrella mark) instead of the retired `.github/social-preview.png`. README attribution note rewritten to point at the brand-asset directory and describe the V5 colour-restraint rule.
- **`test_v30_version_bump.sh` → `test_v31_version_bump.sh`** per the canonical retire-and-replace pattern. New test asserts `plugin.json` version = `3.1.0`, CHANGELOG v3.1.0 entry exists and references the research checklist + the brand kit, manifest identity intact, LICENSE intact.

### Removed

- **`.github/assets/alexander-ford-ventures-logo.svg`** — inherited Silicon Youth geometric mark, obsoleted by the new brand kit's outline-converted AF/LABS marks.
- **`.github/social-preview.py`** + **`.github/social-preview.png`** — Pillow-based per-release social-preview generator, superseded by `.github/assets/brand/social/` (which produces a cleaner, vector-true 1280×640 composition via `fontTools` + `cairosvg`).

### Archived (not removed)

- **`.github/assets/logo-concepts/`** moved to **`.github/assets/_archive/logo-concepts/`** — 50 exploration artifacts from the 7-concept design pass + the AF/LABS font-width matrix (Geist Mono / Inter / Helvetica / Helvetica Neue). Parked for later reference; not active branding.

### Why (research checklist)

Skill behaviour drift: vendor docs and best practices evolve faster than any LLM's training data. Without an enforced rule, the scout can default to whatever it already "knows" about a vendor from training — which is, by construction, stale by some unknown number of months. Mandating `llms.txt` / `llms-full.txt` as the first `WebFetch` shifts the scout from "recall from training" to "fetch current source-of-truth", which is what makes downstream ADRs defensible against "you wrote this from stale training data" objections.

### Why (brand kit)

The prior identity (Silicon Youth → Alexander Ford Ventures) never had a coherent visual asset kit — the GitHub social preview, README hero, and any favicon were ad-hoc. The new kit ships every asset needed for `alexfordlabs.com`, `github.com/alexfordlabs`, and downstream repos (including `alexfordlabs/project-architect`) as scale-infinite SVG masters + PNGs at every standard resolution. Light + dark variants. Zero font dependency at render time.

### Test coverage

- 69 test files (was 68 at v3.0.0). +1 for the universal-research-checklist rule. The version-bump release gate retired-and-replaced (`test_v30_version_bump.sh` → `test_v31_version_bump.sh`). Same net count.

```bash
bash tests/run_all.sh
# Test files passed: 69 · All tests passed.
```

## v3.0.0 — 2026-05-19

**Canonical home moves to [`alexander-ford-ventures/project-architect`](https://github.com/alexander-ford-ventures/project-architect); authorship transfers to Alexander Ford `<alex@pseudo-lang.com>` (Alexander Ford Ventures).**

Identity-only change. No behaviour changes, no API changes, no schema changes. Every test still green (`bash tests/run_all.sh` → 68 / 68).

### Changed

- **Repository path** — every reference to `siliconyouth/project-architect` retargeted to `alexander-ford-ventures/project-architect`. Live code, manifests, READMEs, agent prompts, references, templates, test attribution headers — 293 occurrences across 185 files.
- **Marketplace identifier** — `claude plugin install project-architect@siliconyouth` becomes `claude plugin install project-architect@alexander-ford-ventures`. The marketplace `name` field in `.claude-plugin/marketplace.json` updated.
- **Author** — all attribution headers, owner metadata in `.claude-plugin/*.json`, and `LICENSE` copyright line updated to Alexander Ford `<alex@pseudo-lang.com>`.
- **Organization** — `Silicon Youth` → `Alexander Ford Ventures` in `LICENSE`, `README.md`, marketplace metadata, and the explainer PDF cover (no legal-form suffix on the organization name).
- **CLAUDE.md plugin-namespace gotcha** rewritten — published namespace is now `alexander-ford-ventures:project-architect`; `siliconyouth` GitHub repo remains reachable as a mirror but new installs should target `alexander-ford-ventures`.

### Preserved

- **Frozen historical docs** — `docs/superpowers/{plans,specs,test-plans}/*`, `docs/tests/*`, and pre-v3 `CHANGELOG.md` entries continue to reference the original identity (per the CLAUDE.md "don't tweak history in passing" rule).
- **Test fixtures** — `tests/fixtures/e2e-*/docs/*` retain whatever identity strings their generated content originally had (intentionally minimal per CLAUDE.md).
- **Both GitHub repos remain reachable** — the `siliconyouth/project-architect` repo is kept as a mirror; the canonical source-of-truth is now `alexander-ford-ventures/project-architect`.

### Migration

Existing installs continue to work from the `siliconyouth` mirror; to switch to the new canonical home:

```bash
claude plugin uninstall project-architect@siliconyouth
claude plugin marketplace remove siliconyouth      # optional — keep if you want the mirror
claude plugin marketplace add alexander-ford-ventures/project-architect
claude plugin install project-architect@alexander-ford-ventures
/reload-plugins
```

The Preflight version-freshness check will surface a notice in any session whose installed copy predates this entry once the next tag is cut on the alexander-ford-ventures repo.

## v2.3.0 — 2026-05-13

**Programming language design as a first-class project sub_type — 6 sub_types, 7 design templates, 4 decision axes, 2 e2e fixtures.**

Minor release. Lets users invoke `/skill project-architect:project-architect` for "design a new programming language" and get a coherent doc set covering grammar, semantics, type system, stdlib, toolchain, bootstrap trajectory, and stability/RFC process — same orchestrator, same 11 phases, same 6 subagents, same 16-check auditor; new project-type taxonomy entries, new templates, new questioning paths, new decision axes.

### Added

- **6 programming-language sub_types**: `general_purpose_language`, `domain_specific_language`, `query_language`, `configuration_language`, `educational_language`, `transpiler_target`. Registered in `state-schema.md`; emitted by Phase 1 routing in `questioning-flow.md`.
- **7 PL design templates** under `references/templates/`:
  - `LANGUAGE_GRAMMAR.md` — lexer + parser + grammar design (EBNF, precedence, ambiguity resolution, error recovery).
  - `SEMANTICS.md` — evaluation model (call-by-value/name/need), scoping (lexical/dynamic), memory model, concurrency model, side-effect discipline.
  - `TYPE_SYSTEM.md` — static / dynamic / gradual choice, inference algorithm (HM, bidirectional, local), generics, subtyping, variance, dependent-type opt-in.
  - `STDLIB.md` — module organization (batteries-included vs minimal core + community), namespacing, stable-vs-experimental tiers, packaging story.
  - `TOOLCHAIN.md` — REPL, formatter, LSP, debugger, package manager, build tool, test runner, profiler — what ships in the box vs deferred.
  - `BOOTSTRAP_PLAN.md` — host-language → self-hosted trajectory, v0.1 / v0.5 / v1.0 milestones, dogfooding gates.
  - `STABILITY_AND_RFC.md` — versioning policy (Rust-style trains? Python-style PEPs? Go-style 1.x?), stability tiers (experimental / unstable / stable / deprecated), RFC process, breaking-change escape hatches.
- **4 PL decision axes** in `state-schema.md`:
  - `impl_strategy` — 5 values: `tree_walking_interpreter`, `bytecode_vm`, `jit_compiled`, `aot_compiled`, `transpiled`.
  - `host_runtime` — 14 research-informed values (research dated 2026-05-13): `llvm` (22.x), `mlir_mojo`, `cranelift`, `qbe`, `truffle_graalvm` (24/25 LTS), `jvm` (25 LTS), `beam` (Erlang VM), `wasm` (W3C 3.0 — Sept 2025: WasmGC + EH + tail calls + multi-memory + memory64 + SIMD + WASI 0.2 stable / 0.3 RC + Component Model), `js_host` (transpiler target), `python_embedded` (Python 3.14, no-GIL opt-in + experimental JIT), `rust_host` (Rust as host language for the implementation), `native_no_runtime` (C-class), `custom_vm`, `other`.
  - `paradigm` — 6 values: `imperative`, `functional` (pure/effect-typed/impure), `object_oriented`, `logic`, `array`, `multi_paradigm`.
  - `type_system` — 6 values: `dynamic`, `static_nominal`, `static_structural`, `gradual`, `dependent` (Lean 4 + Mathlib4 >210K theorems), `none` (untyped target).
- **Phase 1 PL-detection routing** in `questioning-flow.md` — gates the PL sub_type when Q1 indicates a language/DSL.
- **Phase 2 + Phase 3 PL question batches** in `questioning-flow.md` — drives `impl_strategy` + `host_runtime` (Phase 2) and `paradigm` + `type_system` (Phase 3) decisions, each filed as an ADR.
- **"PL implementation backends" comparison table** in `tech-stack-options.md` (research dated 2026-05-13) — covers LLVM 22.x, MLIR/Mojo, Cranelift, QBE, Truffle/GraalVM 24/25 LTS, JVM 25 LTS, BEAM, Wasm 3.0 (W3C standard since Sept 2025), Python 3.14, OCaml 5.4 (effect handlers production but still "experimental"), Lean 4, Koka 3.2.3, Gleam 1.16.
- **2 e2e fixtures** under `tests/fixtures/`:
  - `e2e-programming-language-interpreter/` — `lume`, a tree-walking interpreter implemented in Rust, educational sub_type. Exercises the full design doc set + ADR chain for the educational interpreter path.
  - `e2e-programming-language-transpiler/` — `fern`, a static gradual-typed functional language transpiled to JavaScript, transpiler_target sub_type. Exercises the transpiler path with `host_runtime = js_host`.
- **Catalog registration** for all 7 PL templates in `document-catalog.md` with `generate_when` predicates keyed on `sub_type ∈ programming_language_sub_types`.

### Changed

- `SKILL.md` frontmatter description list now includes "programming language design" alongside the existing 18+ project types.
- `state-schema.md` documents the 6 PL sub_types + 4 decision axes.
- `references/tech-stack-options.md` gains the PL backends section.
- `marketplace.json` description refreshed for v2.3 PL capability.
- README.md "Project types supported" list adds "programming language design (general-purpose, DSL, query, config, educational, transpiler target)".

### Migration

Forward-compatible. New fields default to safe absent values. Existing `state.json` from v2.2.x continues to work — projects bootstrapped before v2.3.0 won't see the new questioning paths because Phase 1 PL detection short-circuits to the existing non-PL flow when the sub_type isn't a language. No breaking changes.

### Test coverage

v2.3 added 14 new test files; suite grew from 54 (v2.2.1) → 68 (v2.3.0). Full TDD per CLAUDE.md — every template, every catalog registration, every questioning batch, every tech-stack section, every fixture has a corresponding `tests/test_v23_*.sh`. The `test_v22_version_bump.sh` release gate was retired (asserted plugin.json version `"2.2.1"`); replaced by `test_v23_version_bump.sh` asserting `"2.3.0"`.

```bash
bash tests/run_all.sh
# Test files passed: 68 · All tests passed.
```

## v2.2.1 — 2026-05-13

Patch release that lands a development-workflow `CLAUDE.md`, captures the 8 documentation commits that drifted past the `v2.2.0` tag, and brings every project-internal file into attribution-convention compliance. No new features; everything below was either drift cleanup or workflow codification.

### Changed (behaviour)

- **Preflight version-freshness check** now uses a `gh release view` → `curl https://api.github.com/...` cascade. End users without `gh` installed (or unauthenticated) now still get the freshness notice. Previously the check skipped silently for them.
- **Preflight update-notice text** modernised: `/plugin` + `/reload-plugins` is presented as the primary update flow; the older `claude plugin ...` CLI form remains as a fallback for older Claude Code builds.

### Added

- **`CLAUDE.md`** at the repo root — codifies the development workflow (TDD discipline, subagent-driven plan execution, opus + max-effort directive, combined-review + parallel-dispatch, rule-of-2.5 helper extraction), the release workflow (release commit must be the last commit before the tag — the rule that prevented this drift from happening cleanly), and the file-attribution convention.
- **README.md** now has a "Keeping project-architect up to date" section documenting the `/plugin` + `/reload-plugins` flow with a `claude plugin ...` fallback and `Watch → Releases only` as zero-poll notification.

### Docs

- README.md refreshed for v2.2.0 reality — 6 specialised subagents (was 5), 11 phases (was 9), 54 test files, 5 shipped sketches, expanded architecture mermaid, refreshed phases-at-a-glance table.
- CHANGELOG v2.2.0 entry tightened to reference "the full set of 14 live-test bugs (6 in v2.1.5, the remaining 8 via the auditor here)".
- Live-test report (`docs/tests/2026-05-13-md2pdf-live-test-report.md`) updated with "All 14 bugs resolved" header banner + per-bug fixed-in-vX.Y.Z commit map.
- SKILL.md preamble + Phase order block updated for v2.2.0 (11-phase project bootstrap; Phase 7 = Tooling Execution; Phase 8 = Handoff).
- Marketplace manifest description aligned with `plugin.json`'s v2.2.0 surface area (was last touched in the v2.0.x era).
- v2.2 implementation plan annotated with full per-task → commit-SHA map at the top.
- CLI-UX questioning/templates spec re-marked as shipped in v2.2.0.

### Chore

- **Attribution sweep:** 15 markdown files gained the `*★ Skillfully made with [project-architect](...)*` footer (6 agent docs, `SKILL.md`, 7 references, `CONTRIBUTING.md`). 14 test scripts (`tests/test_v22_*.sh`) gained the 3-line bash-comment author/license/project header. Frozen historical docs (2026-05-12 plans/specs) and convention exceptions (`CHANGELOG.md`, `.github/pull_request_template.md`, `REVISION_LOG_FRAGMENT.md`, `.remember/*`) intentionally left untouched.

### Test coverage

54/54 test files green throughout. No new tests added (this is a docs + workflow release); no test files retired.

## v2.2.0 — 2026-05-13

Major architectural release. Implements the four validation sketches + cross-language CLI-UX picker designed during the md2pdf live test (see `docs/tests/2026-05-13-md2pdf-live-test-report.md`).

### Added

- **Sketch B**: New `quality-gate-auditor` agent runs 16 cross-cutting checks after Phase 4 closes. Findings auto-seed the Phase 5 iteration menu. Together with v2.1.5's tactical fixes, this closes the full set of 14 live-test bugs (6 in v2.1.5, the remaining 8 via the auditor's BLOCKER/WARNING/INFO findings here).
- **Sketch C**: Per-agent runtime budget frontmatter on all 6 agents. Orchestrator wraps every dispatch with an observer that surfaces "silent for too long" and "over budget" warnings. Never auto-kills — observation only. Telemetry feeds future tuning.
- **Sketch D**: Multi-session lifecycle redesign. Phase 4 now generates 4 plan docs (CLAUDE_MD_PLAN, CLAUDE_TOOLING_PLAN, SCAFFOLD_PLAN, NEXT_STEP_PLAN) instead of producing tooling/code directly. New Phase 7 executes plans (claude-md-author and claude-tooling-author refactored to consume plan docs as input). New Phase 8 hands off via CLAUDE.md as router with 3 slash commands (`/scaffold`, `/implement`, `/iterate-design`). Adds `state.locked / version / locked_at` fields and per-phase memory persistence (8-9 memory writes per architect run for cross-session continuity).
- **Sketch A**: Inline validators in `claude-tooling-author` (shellcheck, jq, python yaml). Catches malformed `.sh`/`.json` at write-time before declaring done.
- **Sketch E**: Per-language CLI-UX library picker added to Phase 2 (Rust ratatui/inquire/indicatif/owo-colors, Go bubbletea/lipgloss, Python textual/rich, Node ink/clack, Ruby TTY, C# Spectre.Console + Terminal.Gui). New `CLI_UX_DESIGN.md` template.

### Changed

- Phase 4 no longer generates `CLAUDE.md` or `.claude/*` directly — those move to Phase 7.
- Phase 6 LOCK now snapshots state to `docs/versions/{version}/` and sets `state.locked = true`. Does NOT delete state.json (continuing v2.1.5's bug-#14 fix).
- `claude-md-author` and `claude-tooling-author` now consume plan docs as input rather than reading state directly.
- `state.json` schema gains `locked`, `version`, `locked_at`, `memory_pointer`, `phase_progress[].prerequisites_satisfied`.
- Phase enum extended with `phase_7` and `phase_8`.

### Phase boundary gates

`state.phase_progress[N].prerequisites_satisfied` blocks downstream agent dispatch until upstream phase signals are met. Specifically: Phase 4 won't dispatch document-author until Phase 3's pattern-validation research has returned. Catches the live-test bug-#4 (research dispatched in parallel with Phase 4).

### Migration

Existing v2.1.x users: state.json schema is forward-compatible. New fields default to safe values. The plugin will offer to migrate at startup if it sees a v2.1.x state.

### Test coverage

Full TDD coverage in `tests/`. Run `bash tests/run_all.sh` to verify. 54 test files covering all 16 auditor checks, runtime budgets, plan templates, slash commands, state lifecycle, memory persistence, cross-language CLI-UX picker, and end-to-end Rust/Python/Go fixtures.

## v2.1.5 — 2026-05-13

Tactical fixes for bugs surfaced during the md2pdf live test (see `docs/tests/2026-05-13-md2pdf-live-test-report.md`). Larger architectural improvements ship in v2.2.

### Fixed

- **bug #1** — `state.schema_version` now correctly initializes to `"2.0"` (state-schema version), separate from `state.plugin_version` which carries the plugin's semver. Previously `schema_version` was incorrectly set to the plugin version.
- **bug #2** — All timestamps in `state.json` now use ISO8601 UTC (`YYYY-MM-DDTHH:MM:SSZ`). Previously `started_at` could be written as a date-only string.
- **bug #5** — Phase 4 template selection now force-includes the union of every ADR's `affected_docs`, intersected with the catalog. Previously, ADR-promised docs could be skipped if their `generate_when` expression didn't match.
- **bug #7** — `claude-md-author` and `claude-tooling-author` now use `architect(phase-N): ...` commit subjects instead of `chore: ...`, matching the orchestrator's convention.
- **bug #9** — `decision-revisor` agent prompt now includes explicit scope discipline + cost-budget guidance to prevent runtime overruns on surgical patches.
- **bug #14** — Phase 6 no longer deletes `docs/_architect_state.json`. The state file is preserved as the canonical entry point for future re-invocations (and for `/iterate-design` in v2.2). Only the lockfile is released.

### Added

- Universal CLI-UX gate question in Phase 1 for CLI/TUI projects (sketch E micro-portion). Asks whether the tool is one-shot, interactive prompts, full TUI, or hybrid; routes follow-up questions accordingly. Per-language library picker ships in v2.2.

### Test infrastructure

- New `tests/` directory with shared `lib/test_helpers.sh` and `run_all.sh` runner. Every v2.1.5 fix has a corresponding `tests/test_v215_*.sh` file.

## [2.1.4] — 2026-05-12

### Changed

- **Template footer glyph**: `✨` (sparkle) → `★` (black star) across all 55 user-facing templates. Aligns the markdown-footer attribution with the existing social-preview image attribution (which already used the star glyph). README's Attribution section now explicitly notes the convention: generated-doc footer links to `project-architect` (the skill); the social-preview image credits `Claude Code` (the platform). The link target in the markdown footer is unchanged — still `https://github.com/siliconyouth/project-architect`.

## [2.1.3] — 2026-05-12

### Added

- **Silicon Youth logo** in the social-preview image's top-left publisher line, replacing the `▲` Unicode placeholder. SVG is now tracked at `.github/assets/silicon-youth-logo.svg`; the generator (`.github/social-preview.py`) re-tints the dark-fill SVG to accent blue at render time so it sits cleanly on the dark canvas. Adds `cairosvg` as an optional dependency of the generator script (only needed for regenerating the preview, not for using the skill).

## [2.1.2] — 2026-05-12

### Changed

- **Social-preview image redesigned**: footer right-side now reads "★ Skillfully made with Claude Code" (proper star glyph instead of the previous `*` fallback). The "try it →" inline CTA was removed; replaced with a dedicated pill-shaped **Install →** button in the top-right corner — higher click-conversion shape with dark-on-blue contrast.

## [2.1.1] — 2026-05-12

### Added

- **GitHub social-preview image** (`.github/social-preview.png`, 1280×640 PNG, dark theme, generated by `.github/social-preview.py`). Embedded at the top of README.md for landing-page impact. Regenerable on each release by re-running the script.

## [2.1.0] — 2026-05-12

### Added

- **Modern README** with badges, mermaid architecture diagram, terminal "screenshot" code blocks showing the live UX, comprehensive project-types list, and recommended-plugins table.
- **GitHub repo hardening**: `.github/ISSUE_TEMPLATE/bug_report.yml`, `feature_request.yml`, `config.yml`; `.github/pull_request_template.md`; `CONTRIBUTING.md`.
- **Template beautification** for generated docs: status callout under H1, table-of-contents on long docs, judicious section-emoji prefixes (🎯 🏗️ 🔐 🗄️ 🌐 🎨 🚀 🧪 📊 💰 🔧 ⚙️ 📝 🚦 ↻), Revision Log rendered as a table, "✨ Skillfully made with…" footer (sparkle prefix).

### Changed

- **Marketplace description** rewritten for public release. Now reads: "Public marketplace by Silicon Youth, featuring project-architect — an orchestrator skill that bootstraps any project type with research-augmented questioning, ADR-tracked decisions, parallel doc generation, and project-local Claude Code configuration."

## [2.0.5] — 2026-05-12

### Added

- **MIT LICENSE**.
- **Author attribution comment block** added to every text file in the repo (after YAML frontmatter where applicable, at top otherwise). Carries name, email, repo URL, license.
- **"Skillfully made with…" footer** appended to every doc template so generated user-project docs (PROJECT_OVERVIEW, CLAUDE.md, all architecture docs, etc.) automatically include downstream attribution.
- **Attribution policy + License section** in README.md explaining the social-norm attribution and the MIT terms.

### Changed

- `plugin.json` and `marketplace.json` now declare `license: MIT` and `repository: https://github.com/siliconyouth/project-architect` as standard manifest fields.

## [2.0.4] — 2026-05-12

### Changed

- **Marketplace renamed from `local` to `siliconyouth`** to match the GitHub org. The plugin now surfaces as `project-architect@siliconyouth`. **Breaking change for install commands**: anyone with the marketplace registered under the old `local` alias must re-register under `siliconyouth` (see migration below).

### Migration

```bash
# Refresh + re-register the marketplace
claude plugin marketplace remove local
claude plugin marketplace add siliconyouth/project-architect

# Reinstall the plugin from the renamed marketplace
claude plugin uninstall project-architect@local
claude plugin install project-architect@siliconyouth

# Reload in any active Claude session
/reload-plugins
```

## [2.0.3] — 2026-05-12

### Fixed

- **`commit-commands` dependency resolved to wrong marketplace** (`/doctor` flagged this as a missing-dep error). Bare-string dependencies (`"dependencies": ["commit-commands"]`) resolve to `commit-commands@<same-marketplace-as-this-plugin>` = `commit-commands@siliconyouth`, which doesn't exist. The actual installation lives in `commit-commands@claude-plugins-official`. Changed to the object form `{ "name": "commit-commands", "marketplace": "claude-plugins-official" }` per the canonical Claude Code plugin schema.

### Notes

- Bare strings in `dependencies` work only when the dep ships from the same marketplace as the dependent plugin. For cross-marketplace deps (the common case for plugins reusing Anthropic's official skills), use the object form with explicit `marketplace`.

## [2.0.2] — 2026-05-12

### Added

- **Preflight `Cache hygiene` step**. After the version-freshness check, the architect now proactively removes stale plugin-cache version directories (sibling dirs to `${CLAUDE_PLUGIN_ROOT}`) so future sessions can't accidentally load an older cached version. Replaces the manual `rm -rf` step that used to be in the README versioning-policy procedure.

### Fixed

- **`.remember/logs/` and `.gitignore` for the plugin's own repo**. The architect SKILL pre-creates `.remember/logs/` in Preflight for *generated projects*, but the plugin's own repo (`/Users/vladimir/projects/project-architect/`) was missing both the directory and a `.gitignore`. Anyone working on the architect's own files would see hook-error spam from the `remember` plugin. Added a repo-level `.gitignore` (with `.remember/` listed) and pre-created the empty `.remember/logs/` dir locally.

## [2.0.1] — 2026-05-12

### Fixed

- **Plugin manifest schema conformance** (`1be648b`). `dependencies` was an object map (npm-style); now the canonical array form per the Claude Code plugin schema. Removed `softDependencies` (unrecognized key); recommendations now surface via README, runtime Preflight check, and generated `recommended-plugins.md`. Added a top-level marketplace `description`.
- **`phase_-1` enum mismatch** (`c731879`). The Soft-dependency check saved `state.phase = "phase_-1"`, inconsistent with the canonical phase enum (`"preflight"`). Resume after a Preflight abort would have no matching case. Renamed to `"preflight"` everywhere.
- **Missing `Skill` tool grants** (`c731879`). `claude-md-author` and `claude-tooling-author` agent bodies invoke other skills but `Skill` wasn't in their tools array. Added.

### Added

- **`references/state-schema.md`** (`d1446ac`). Canonical runtime reference for `state.json`: schema, lockfile protocol, migration policy. Replaces the workaround that pointed SKILL.md at the design spec.
- **Soft-dependency Preflight check** (`6eb14a9`, `23cd200`). Lists 6 recommended plugins at startup, scans for missing ones, offers install. Replaces the dropped `softDependencies` manifest field.
- **`.remember/logs/` auto-creation** (`baf31ac`, `675b6d7`). Preflight's first step now `mkdir -p .remember/logs` to silence the `remember` plugin's PostToolUse hook when it's installed. Also adds `.remember/` to the universal-default `.gitignore` Phase 0a writes.
- **Version freshness check** (`cd54887`). Preflight compares `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` against `gh release view --repo siliconyouth/project-architect`; warns if loaded < latest. Best-effort; silently skips if `gh` missing, no network, or no releases.
- **Manual test plan** (`715bca0`). 5 scenarios covering CLI bootstrap, Claude Code plugin bootstrap, iteration/revision, resumability, and snapshot versioning.
- **As-built corrections appendix** (`3992cb6`) on the v2.0 design spec and implementation plan, documenting deltas between design-time assumptions and shipped behavior.

### Changed

- **Preflight subsection order**: `Ambient hooks tolerance` → `Model/effort verification` → `Soft-dependency check` → `Version freshness check`. The mkdir runs first so the `remember` plugin's hook never sees a missing log dir.
- **Doc consistency** (`23cd200`): README, spec, and plan all reference 6 recommended plugins. Test plan corrected re: `/plugin` not showing versions.

### Removed

- `softDependencies` field from `plugin.json` (unrecognized by schema).
- "Soft dep missing" row from the failure-modes table (replaced by proactive Preflight handling).

## [2.0.0] — 2026-05-12

### Added — Major redesign as an orchestrator

- **9-phase bootstrap model**: preflight → 0a repo init → 0 universal kickoff → 1 vision → 2 tech stack → 2.5 cost → 3 architecture → 4 doc generation → 5 iteration → 6 post-gen setup → optional 7 plan handoff.
- **Universal kickoff** (Q1–Q8) that classifies any project type before branching to type-specific drill-downs.
- **Project-type taxonomy** covering 18 top-level types: web app, mobile, multi-platform, API, CLI, library, desktop, browser extension, game, AI/ML, data pipeline, embedded/IoT, infrastructure, Claude Code plugin, MCP server, Web3, scientific code, AR/VR.
- **5 subagents**: `research-scout`, `document-author`, `decision-revisor`, `claude-md-author`, `claude-tooling-author`. Each dispatched with `model: "opus"` and a max-effort prompt header.
- **Research-augmented questioning**: end-of-phase + on-demand ad-hoc web research via `research-scout`. Findings persisted to `docs/research/`.
- **Architecture Decision Records (ADRs)**: every major decision filed as a sequentially-numbered ADR in `docs/decisions/`. Never reused; supersession chain forms the audit trail.
- **Iteration with consequence propagation**: `decision-revisor` agent reads `revision-playbook.md` to rewrite all affected docs when a decision changes; files a new ADR superseding the prior.
- **Hybrid versioning**: in-place edits + git history + opt-in snapshot bundles in `docs/versions/v<X.Y>/` + ADRs.
- **Per-folder CLAUDE.md** generation for monorepo subdirectories with materially different conventions.
- **Generated `.claude/` directory**: `settings.json` (model: opus 1M, stack-aware permissions, hook wiring), `hooks/` (lint/test/secret-scan scripts), `agents/` (project-specific subagents), `commands/` (project slash commands), `recommended-plugins.md`.
- **Auto-commit cadence**: per batch / per artifact / per phase, via `commit-commands:commit`.
- **Model + effort + 1M-context enforcement** at preflight; `update-config` invocation to set project-local defaults.
- **Optional Phase 7 handoff** to `superpowers:writing-plans` for implementation planning.
- **Resumable state** in `docs/_architect_state.json` with a concurrency lockfile.

### Changed

- SKILL.md restructured from inline workflow to slim orchestrator (~200 lines) that loads references on demand.
- `references/questioning-flow.md` restructured: universal kickoff + per-type drill-down sections.
- `references/tech-stack-options.md` expanded with more options per category.
- Templates moved from monolithic `references/document-templates.md` to one file per template under `references/templates/` (~56 files).

### Removed

- `references/document-templates.md` (content split into `references/templates/*.md`).

## [1.0.0] — 2026-05-01

- Initial release. 3-phase interview (vision, tech stack, architecture deep dive), monolithic template file, generates docs/ and CLAUDE.md.
