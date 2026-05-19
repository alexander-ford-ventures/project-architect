<!-- Author: Alexander Ford <alex@pseudo-lang.com> -->
<!-- License: MIT -->
<!-- Project: project-architect (https://github.com/alexander-ford-ventures/project-architect) -->

---
template_name: SLASH_IMPLEMENT
target_path: .claude/commands/implement.md
generate_when: always
depends_on:
  - PROJECT_REQUIREMENTS.md
---

# Slash command template: `/implement <feature>`

When `claude-tooling-author` consumes this template in Phase 7, it produces `.claude/commands/implement.md`.

## Target file content

```markdown
---
description: "Implement a specific feature from docs/PROJECT_REQUIREMENTS.md"
argument-hint: feature-name
---

Implement the feature `$1` from `docs/PROJECT_REQUIREMENTS.md`.

Steps:

1. Read `docs/PROJECT_REQUIREMENTS.md` and locate the feature spec for `$1`.
2. If the feature isn't found, surface that and propose adding it via `/iterate-design`.
3. Use `superpowers:writing-plans` to produce an implementation plan scoped to this feature.
4. Use `subagent-driven-development` to execute the plan.

Output:
- Code changes implementing the feature
- Test changes covering the feature
- One commit per atomic change, citing ADR numbers where applicable

If `superpowers:writing-plans` is unavailable, fall back to a manual TDD loop: write failing test → impl → green test → commit.
```

---

*★ Skillfully made with [project-architect](https://github.com/alexander-ford-ventures/project-architect).*
