<!-- Author: Alexander Ford <alex@alexfordlabs.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/alexfordlabs/project-architect) -->

---
template_name: SCAFFOLD_PLAN
generate_when: project.sub_type != "documentation_only"
required_decisions:
  - project.name
  - project.sub_type
  - tech_stack.language
  - tech_stack.language_edition
  - decisions.license
optional_decisions:
  - tech_stack.build_tool
  - tech_stack.test_runner
  - tech_stack.toolchain_version
  - tech_stack.runtime_version
  - decisions.architecture.lib_vs_bin
  - decisions.copyright_holder
  - decisions.copyright_year
depends_on:
  - TECH_STACK.md
  - ARCHITECTURE.md
  - BUILD_AND_RUN.md
  - LICENSE_NOTICE.md
revision_triggers:
  - tech_stack.language
  - tech_stack.language_edition
  - tech_stack.build_tool
  - decisions.license
  - decisions.architecture.lib_vs_bin
---

# Scaffold plan — {{project.name}}

This document **describes** the exact files and commands needed to bootstrap the on-disk codebase for `{{project.name}}` once the design is locked. It is **not** the codebase itself — it is the recipe.

The plan is **consumed by `superpowers:writing-plans` (via `/scaffold`)**: Phase 8 option (c) in `project-architect` hands the locked design off to superpowers, which turns this plan into a concrete `plans/<date>-scaffold.md` and runs SDD against it (TDD-driven, one verified file at a time).

## Why a plan, not the scaffold itself

Phase 4 produces design + plan docs only. Generating scaffold contents (real `Cargo.toml`, `src/lib.rs`, license headers) in Phase 4 would:
- Conflate "what the codebase should look like" (design) with "creating it on disk" (execution).
- Make Phase 5 iteration awkward — you'd be editing committed source code, not a plan.
- Bypass `superpowers:writing-plans` + SDD, which is where the actual scaffold belongs.

With a plan-first approach:
- Phase 5 lets you edit this plan and re-run audit
- Phase 8 hands the plan to superpowers (`/scaffold`), which produces a real plan + executes it test-first
- The plan stays as a permanent record of the intended initial codebase, traceable back to ADRs

## 1. Build manifest

The future build manifest (`{{ if tech_stack.language == "rust" then "Cargo.toml" else if tech_stack.language == "javascript" or tech_stack.language == "typescript" then "package.json" else if tech_stack.language == "python" then "pyproject.toml" else if tech_stack.language == "go" then "go.mod" else "(language-appropriate manifest)" }}`) will encode dependencies, metadata, and build settings locked from the ADRs. Show the **full inline content** of the manifest here, with versions pinned per ADR.

### Language-conditional examples

{{ if tech_stack.language == "rust" then "" }}
```toml
# Cargo.toml — generated from TECH_STACK ADR {{tech_stack.language.adr}}
[package]
name = "{{project.name}}"
version = "0.1.0"
edition = "{{tech_stack.language_edition}}"
rust-version = "{{tech_stack.toolchain_version}}"
license = "{{decisions.license}}"
authors = ["{{decisions.copyright_holder}}"]
description = "{{project.elevator_pitch}}"

[dependencies]
# Each dep MUST cite the ADR that introduced it
{{decisions.dependencies.runtime}}  # e.g., serde = { version = "1.0", features = ["derive"] }  # ADR 0004

[dev-dependencies]
{{decisions.dependencies.test}}  # e.g., insta = "1.39"  # ADR 0005 (TESTING_STRATEGY)
```

{{ if tech_stack.language == "javascript" or tech_stack.language == "typescript" then "" }}
```json
{
  "name": "{{project.name}}",
  "version": "0.1.0",
  "description": "{{project.elevator_pitch}}",
  "license": "{{decisions.license}}",
  "type": "module",
  "engines": { "node": "{{tech_stack.runtime_version}}" },
  "scripts": {
    "build": "{{tech_stack.build_tool}} build",
    "test": "{{tech_stack.test_runner}}"
  },
  "dependencies": {},
  "devDependencies": {}
}
```

{{ if tech_stack.language == "python" then "" }}
```toml
# pyproject.toml — generated from TECH_STACK ADR {{tech_stack.language.adr}}
[project]
name = "{{project.name}}"
version = "0.1.0"
requires-python = ">={{tech_stack.runtime_version}}"
license = { text = "{{decisions.license}}" }
description = "{{project.elevator_pitch}}"
dependencies = []

[project.optional-dependencies]
dev = []

[build-system]
requires = ["{{tech_stack.build_tool}}"]
build-backend = "{{tech_stack.build_backend}}"
```

{{ if tech_stack.language == "go" then "" }}
```
module {{decisions.module_path}}

go {{tech_stack.runtime_version}}

require ()
```

For every dependency added, cite the ADR that mandates it. Do **not** add transitive sugar (test frameworks "everyone uses"); every line must be ADR-justified.

## 2. `src/` tree with per-file purpose statements

The future `src/` tree must be designed up-front so SDD has a concrete target. List **every initial file** with a one-line purpose statement tied to ARCHITECTURE.md or the relevant ADR. (Files added later during SDD belong in the superpowers plan, not here.)

### Example (Rust library + binary)

| File | Purpose | Source |
|---|---|---|
| `src/lib.rs` | Library entry point exposing public API per ADR-0003 | ARCHITECTURE §Module layout |
| `src/main.rs` | CLI entry point parsing args and dispatching to lib | ARCHITECTURE §Binaries |
| `src/error.rs` | Crate-wide error type (`thiserror`) per ADR-0006 | ARCHITECTURE §Error handling |
| `src/{{module.name}}/mod.rs` | {{module.purpose}} | ADR-{{module.adr}} |

### Example (Python package)

| File | Purpose | Source |
|---|---|---|
| `src/{{project.name}}/__init__.py` | Package root; re-exports public API | ARCHITECTURE §Public surface |
| `src/{{project.name}}/cli.py` | CLI entry (argparse / typer / click per ADR) | ARCHITECTURE §CLI |
| `src/{{project.name}}/core.py` | Pure-logic module — no I/O | ARCHITECTURE §Layering |
| `tests/test_core.py` | Test for `core.py` (TDD seed for SDD) | TESTING_STRATEGY §Unit tests |

### Example (TypeScript / Node)

| File | Purpose | Source |
|---|---|---|
| `src/index.ts` | Library entry — re-exports public API | ARCHITECTURE §Public surface |
| `src/cli.ts` | CLI entry (commander / yargs per ADR) | ARCHITECTURE §CLI |
| `src/{{module.name}}.ts` | {{module.purpose}} | ADR-{{module.adr}} |

For each row, the purpose statement must be **specific enough that an SDD agent could write the test first** without re-reading the entire design.

## 3. License files + NOTICE

The future repo will ship the canonical license text plus (if required) a `NOTICE` file for attribution. List the **full file content** here, with placeholders for year and author so Phase 8 (or `/scaffold`) substitutes them deterministically.

### `LICENSE` ({{decisions.license}})

The full text of `{{decisions.license}}` will be written to `LICENSE` at repo root.

{{ if decisions.license == "MIT" then "" }}
```
MIT License

Copyright (c) {{decisions.copyright_year}} {{decisions.copyright_holder}}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```

{{ if decisions.license == "Apache-2.0" then "" }}
For Apache-2.0, also write a `NOTICE` file with the attribution header (see LICENSE_NOTICE.md §NOTICE-file shape).

### `NOTICE` (if required by license)

```
{{project.name}}
Copyright (c) {{decisions.copyright_year}} {{decisions.copyright_holder}}

This product includes software developed at
{{decisions.copyright_holder}} ({{decisions.copyright_url}}).
```

### Per-source-file header (if mandated by LICENSE_NOTICE.md)

If the design requires per-file SPDX headers, document the exact header here:

```
// SPDX-License-Identifier: {{decisions.license}}
// Copyright (c) {{decisions.copyright_year}} {{decisions.copyright_holder}}
```

## 4. Toolchain pin file

The future repo will pin its toolchain via a language-appropriate file so contributors get a reproducible environment without thinking about it.

### Language-conditional examples

{{ if tech_stack.language == "rust" then "" }}
```toml
# rust-toolchain.toml — pinned per TECH_STACK ADR {{tech_stack.toolchain.adr}}
[toolchain]
channel = "{{tech_stack.toolchain_version}}"
components = ["rustfmt", "clippy"]
profile = "minimal"
```

{{ if tech_stack.language == "javascript" or tech_stack.language == "typescript" then "" }}
```
# .nvmrc — pinned per TECH_STACK ADR {{tech_stack.runtime.adr}}
{{tech_stack.runtime_version}}
```

{{ if tech_stack.language == "python" then "" }}
```
# .python-version (pyenv / mise) — pinned per TECH_STACK ADR {{tech_stack.runtime.adr}}
{{tech_stack.runtime_version}}
```

{{ if tech_stack.language == "go" then "" }}
The `go` directive in `go.mod` (above) is the toolchain pin. Optionally pin via `// toolchain` line or `.tool-versions` (asdf / mise).

For each pin, cite the ADR that justifies the chosen version (LTS policy, language-feature gate, etc.).

## 5. Bootstrap commands

The exact, deterministic command sequence Phase 8 (or `/scaffold` → `superpowers:writing-plans`) will run to materialize the scaffold. These run **before** any source content is written — they establish directory shape, VCS, and toolchain.

> **Important:** every destructive operation must be guarded. If a step would clobber an existing file, the executor must stop and surface a confirmation prompt. Use the `:*` glob form when listing patterns to avoid Semgrep / pre-commit false-positives (e.g., `Bash(rm:*)`, not the literal command).

### Example sequence (Rust library + binary)

```bash
# 1. Initialize project structure (no VCS yet — we add it explicitly below)
cargo init --lib --vcs none "{{project.name}}"
cd "{{project.name}}"

# 2. Overwrite Cargo.toml with the manifest from §1
#    (executor writes the file from this plan; no inline cat <<EOF here)

# 3. Write toolchain pin
#    (executor writes rust-toolchain.toml from §4)

# 4. Initialize VCS and seed history
git init
git branch -M main

# 5. Write LICENSE and (optionally) NOTICE from §3
#    (executor writes these files)

# 6. Stage everything and commit
git add .
git commit -m "chore(scaffold): bootstrap {{project.name}} v0.1.0"
```

### Example sequence (Python package with pyproject + src-layout)

```bash
mkdir -p "{{project.name}}/src/{{project.name}}" "{{project.name}}/tests"
cd "{{project.name}}"
# Executor writes pyproject.toml (§1), .python-version (§4), LICENSE (§3),
# and the empty src/ files from §2.
git init
git branch -M main
git add .
git commit -m "chore(scaffold): bootstrap {{project.name}} v0.1.0"
```

### Forbidden / guarded commands

The executor must **never** run, and `.claude/settings.json` should deny:

- `Bash(rm:*)` — no recursive deletes during scaffold
- `Bash(sudo:*)` — no privilege escalation
- `Bash(curl:*|sh)` — no piped remote execution

(These also live in `CLAUDE_TOOLING_PLAN.md` §`settings.json` — keep them in sync.)

## 6. Hand-off note

This plan is consumed by **`superpowers:writing-plans`** (via the `/scaffold` slash command generated in Phase 7).

Phase 8 option (c) — "Hand off to scaffold" — calls `/scaffold`, which:
1. Reads this `SCAFFOLD_PLAN.md` from the locked design.
2. Invokes `superpowers:writing-plans` to convert this plan into a concrete `plans/{{today}}-scaffold-{{project.name}}.md` (TDD-shaped phases).
3. Hands the produced plan to SDD (subagent-driven development) so each file in §2 is **test-first**: one file → one passing test → one verified commit.
4. Returns to the user at the end with a working, committed scaffold ready for `/implement <feature>`.

If `superpowers` is not installed on the contributor's machine, the manual fallback is documented in `NEXT_STEP_PLAN.md` (Task 35) — execute §5 commands by hand, then write `src/` files from §2 stub-first, test-second.

## Notes for the executor

When `/scaffold` (via `superpowers:writing-plans`) consumes this plan:

1. Substitute every `{{...}}` placeholder from `state.decisions`.
2. Resolve all language-conditional blocks (`{{ if tech_stack.language == "..." then "..." }}`) — keep only the branch that matches the project's language.
3. Pass the resolved plan to `superpowers:writing-plans`, which produces a TDD-shaped `plans/<date>-scaffold.md`.
4. Run that plan via `superpowers:executing-plans` + `subagent-driven-development` so every src file lands test-first.
5. Each commit subject follows project convention (e.g., `scaffold(<file>): <one-line purpose>`).
6. After the last commit, set `state.scaffolded = true` and `state.scaffold_commit = <SHA>` in `state.json`.

If any bootstrap command in §5 fails, stop and surface to the user — do not retry destructively or rewrite history.

---

*★ Skillfully made with [project-architect](https://github.com/alexfordlabs/project-architect).*
