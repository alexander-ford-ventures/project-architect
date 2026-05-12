---
template_name: CLAUDE_MD_ROOT
generate_when: "always"
required_decisions:
  - project.name
  - project.type
  - language.primary
optional_decisions:
  - frontend.framework
  - backend.framework
  - database.engine
  - auth.provider
  - hosting.frontend
  - hosting.backend
  - testing.unit_framework
  - package_manager
depends_on: [PROJECT_OVERVIEW, PROJECT_REQUIREMENTS]
revision_triggers:
  - language.primary
  - frontend.framework
  - backend.framework
  - database.engine
  - auth.provider
  - project.type
  - testing.unit_framework
  - package_manager
---

<!--
Author: Vladimir Dukelic <vladimir@dukelic.com>
Repository: https://github.com/siliconyouth/project-architect
License: MIT
-->

# {{project_name}}

> 📌 **Status:** v{{document_version}} · **Last revised:** {{last_revised_date}} · **ADRs:** {{adr_links}}

## Table of contents
- [🎯 Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [🏗️ Project Structure](#project-structure)
- [Development Commands](#development-commands)
- [Code Conventions](#code-conventions)
- [🏗️ Architecture Notes](#architecture-notes)
- [Key Files](#key-files)
- [Where to look](#where-to-look)

## 🎯 Project Overview
One sentence: what this project is. Link to `docs/PROJECT_OVERVIEW.md` for the full pitch.

## Tech Stack
Concise table — one row per major layer.

## 🏗️ Project Structure
Brief listing of key directories with one-line purpose each. Highlight which subdirs have their own CLAUDE.md.

## Development Commands
Install, dev, build, test, lint, typecheck. Stack-specific (pnpm / cargo / pip / go).

## Code Conventions
- Naming: {{convention}}
- Formatting: {{tool + config file}}
- Linting: {{tool + config file}}
- Test placement: {{co-located / __tests__ / tests/}}
- Commit style: {{conventional / freeform}}

## 🏗️ Architecture Notes
Key architectural decisions that affect coding patterns. One line per decision, link to ADR.

## Key Files
Path → purpose, one line each. Limit to ~10 most-important files.

## Where to look
- `docs/` — full architecture documentation
- `docs/decisions/` — ADRs
- `docs/research/` — research findings from bootstrap
- `<subdir>/CLAUDE.md` — area-specific conventions (if applicable)

---

*✨ Skillfully made with [project-architect](https://github.com/siliconyouth/project-architect).*
