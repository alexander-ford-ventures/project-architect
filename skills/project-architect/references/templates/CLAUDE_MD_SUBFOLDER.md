---
template_name: CLAUDE_MD_SUBFOLDER
generate_when: "subfolder meets gating triggers (see claude-md-author system prompt)"
required_decisions:
  - subfolder.path
  - subfolder.purpose
optional_decisions:
  - subfolder.language
  - subfolder.framework
  - subfolder.test_framework
  - subfolder.build_command
depends_on: [CLAUDE_MD_ROOT]
revision_triggers:
  - subfolder.language
  - subfolder.framework
  - subfolder.test_framework
---

# {{subfolder.path}}

## Purpose
What this area is responsible for. How it relates to the rest of the project.

## Local Tech Stack
Only list what differs from the root CLAUDE.md.

## Conventions Specific to This Area
- {{convention}} — why
- {{convention}} — why

## Local Development Commands
Only commands that are different from root (test, build, run).

## Key Files In This Area
Path → purpose.

## Cross-references
- Root: `../CLAUDE.md` for project-wide conventions
- Related docs: {{relevant docs/ links}}
